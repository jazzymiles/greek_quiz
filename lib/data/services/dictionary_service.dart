// lib/data/services/dictionary_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:greek_quiz/data/models/dictionary_info.dart';
import 'package:greek_quiz/data/models/word.dart';

/// Service that manages dictionary metadata, selection and active words.
class DictionaryService extends ChangeNotifier {
  DictionaryService();

  // === Favorites dictionary (virtual) ===
  static const String favoritesFile = 'user_favs.json';
  static const String favoritesNameRu = 'Избранное';
  static const String favoritesNameEn = 'Favorites';
  static const String favoritesNameEl = 'Αγαπημένα';

  // Public state
  List<Word> activeWords = [];
  List<DictionaryInfo> availableDictionaries = [];
  final Set<String> selectedDictionaries = <String>{};

  // Download UI state
  bool isDownloading = false;
  double downloadProgress = 0.0;
  String statusMessage = 'downloading_dictionaries';

  // Internals
  final Random _random = Random.secure();

  // Cache: dictionaryId(file) -> words
  final Map<String, List<Word>> _wordsCache = {};

  // Availability loading gate
  bool _availableLoaded = false;
  Future<void>? _availableLoadFuture;

  // ---- Public API ----

  /// Базовая инициализация без автозагрузки.
  Future<void> initialize() async {
    await _ensureDirs();
    await _ensureFavoritesFileExists(); // <- создать избранное, если нет
    await ensureAvailableLoaded();
    _injectFavoritesIfMissing();        // <- убедиться, что избранное есть в списке
    await _loadSelected();
    // Загрузим слова для выбранных словарей (чтобы активные сразу работали)
    await _ensureWordsLoadedForSelection();
    // И — для режима "All words" — прогрузим в кэш все словари из папки
    await _ensureAllCachedLoaded();
    _rebuildActiveWords();
    notifyListeners();
  }

  /// Инициализация + автозагрузка словарей, если их нет (первый запуск).
  Future<void> initializeWithBootstrap({
    String interfaceLanguage = 'en',
    String? indexUrlIfBootstrap,
  }) async {
    await initialize();

    if (indexUrlIfBootstrap == null || indexUrlIfBootstrap.isEmpty) {
      return; // нет URL — ничего не делаем
    }

    final needBootstrap = availableDictionaries.isEmpty ||
        !(await _allIndexedFilesPresent(availableDictionaries));

    if (needBootstrap) {
      try {
        await downloadAndSaveDictionaries(
          interfaceLanguage,
          indexUrl: indexUrlIfBootstrap,
        );
      } catch (_) {
        // молча: пользователь сможет скачать вручную из настроек
      } finally {
        await ensureAvailableLoaded();
        _injectFavoritesIfMissing();
        await _ensureWordsLoadedForSelection();
        await _ensureAllCachedLoaded();
        _rebuildActiveWords();
        notifyListeners();
      }
    }
  }

  /// Ensure list of available dictionaries is loaded exactly once.
  Future<void> ensureAvailableLoaded() async {
    if (_availableLoaded && availableDictionaries.isNotEmpty) return;
    _availableLoadFuture ??= _fetchAvailableDictionaries();
    try {
      await _availableLoadFuture;
    } finally {
      _availableLoadFuture = null;
    }
  }

  /// Toggle selection of a dictionary by its id (file).
  void toggleDictionarySelection(String fileId) {
    if (selectedDictionaries.contains(fileId)) {
      selectedDictionaries.remove(fileId);
    } else {
      selectedDictionaries.add(fileId);
    }
    _saveSelected(); // fire-and-forget
    _ensureWordsLoadedForSelection(); // preload words (включая избранное)
    _rebuildActiveWords();
    notifyListeners();
  }

  /// Re-compute activeWords from selected dictionaries.
  void filterActiveWords() {
    _ensureWordsLoadedForSelection();
    _rebuildActiveWords();
    notifyListeners();
  }

  /// Return a random word from active set (or null if empty).
  Word? getRandomWord() {
    if (activeWords.isEmpty) return null;
    return activeWords[_random.nextInt(activeWords.length)];
  }

  /// Utility for multiple choice options (excludes a word).
  List<Word> getRandomOptions({required Word excludeWord, int count = 3}) {
    final pool = List<Word>.from(activeWords)
      ..removeWhere((w) => w.id == excludeWord.id);
    pool.shuffle(_random);
    return pool.take(count).toList();
  }

  /// Picks candidates for wrong options.
  ///
  /// Если [useAllWords] = true — берём из *всех загруженных словарей*.
  /// Если false — **строго** из выбранных (activeWords), без автоподмешивания.
  /// Порядок — случайный; возвращаем до [count] элементов.
  List<Word> getQuizOptions({
    required Word excludeWord,
    bool useAllWords = false,
    int count = 3,
  }) {
    List<Word> pool;

    if (useAllWords) {
      final allCached = _allCachedWords();
      pool = allCached.isNotEmpty ? List<Word>.from(allCached) : List<Word>.from(activeWords);
    } else {
      pool = List<Word>.from(activeWords);
    }

    // Удалим сам правильный ответ из пула и уберём дубликаты по id
    final seen = <String>{excludeWord.id};
    final filtered = <Word>[];
    for (final w in pool) {
      if (seen.add(w.id)) filtered.add(w);
    }

    filtered.shuffle(_random);
    return filtered.take(count).toList();
  }

  /// Обновить кэш избранного после изменений в FavoritesService
  Future<void> refreshFavorites() async {
    await _loadFavoritesIntoCache();
    if (selectedDictionaries.contains(favoritesFile)) {
      _rebuildActiveWords();
      notifyListeners();
    }
  }

  // ---- Download dictionaries (remote-only) ----

  /// Downloads index and dictionaries it references into app storage.
  Future<void> downloadAndSaveDictionaries(
      String interfaceLanguage, {
        String? indexUrl,
      }) async {
    if (indexUrl == null || indexUrl.isEmpty) {
      return; // совместимость с существующими вызовами
    }

    isDownloading = true;
    downloadProgress = 0.0;
    statusMessage = 'downloading_dictionaries';
    notifyListeners();

    try {
      final dir = await _dictionariesDir();
      await dir.create(recursive: true);

      // Получаем и парсим индекс
      final resp = await http.get(Uri.parse(indexUrl));
      if (resp.statusCode != 200) {
        throw Exception('Index download failed: ${resp.statusCode}');
      }
      final body = utf8.decode(resp.bodyBytes);

      final List<DictionaryInfo> list = _parseIndex(body);

      // Сохраняем индекс локально
      final indexFile = File('${dir.path}/index.json');
      await indexFile.writeAsString(jsonEncode(list
          .map((d) => {
        'file': d.file,
        'name_ru': d.nameRu,
        'name_en': d.nameEn,
        'name_el': d.nameEl,
        'filePath': d.filePath,
      })
          .toList()));

      // Скачиваем каждый словарь (только http/https)
      int i = 0;
      for (final d in list) {
        i++;
        downloadProgress = i / (list.isEmpty ? 1 : list.length);
        notifyListeners();

        final target = File('${dir.path}/${d.file}');
        if (d.filePath.toLowerCase().startsWith('http')) {
          final r = await http.get(Uri.parse(d.filePath));
          if (r.statusCode == 200) {
            await target.writeAsBytes(r.bodyBytes);
          } else {
            // логировать при желании
          }
        }
      }

      // Обновляем внутреннее состояние
      await _fetchAvailableDictionaries();
      _injectFavoritesIfMissing();
      await _ensureAllCachedLoaded();
      await _ensureWordsLoadedForSelection();
      _rebuildActiveWords();

      statusMessage = 'all_dictionaries_updated';
    } catch (e) {
      statusMessage = 'download_error';
      rethrow;
    } finally {
      isDownloading = false;
      downloadProgress = 0.0;
      notifyListeners();
    }
  }

  // ---- Internals ----

  List<DictionaryInfo> _parseIndex(String body) {
    // 1) Попробуем JSON
    try {
      final dynamic decoded = jsonDecode(body);

      if (decoded is List) {
        return decoded.map<DictionaryInfo>((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return _dictFromAnyMap(m);
        }).toList();
      }

      if (decoded is Map && decoded['dictionaries'] is List) {
        final list = (decoded['dictionaries'] as List);
        return list.map<DictionaryInfo>((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return _dictFromAnyMap(m);
        }).toList();
      }
      // Если JSON, но формат неизвестен — провалимся в текстовый парсер ниже
    } catch (_) {
      // не JSON — попробуем как текст
    }

    // 2) Текстовый формат: построчно
    final result = <DictionaryInfo>[];
    final lines = const LineSplitter().convert(body);
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#')) continue;

      // поддержим запятая/точка с запятой/таб
      final parts = line
          .split(RegExp(r'\s*,\s*|\s*;\s*|\t'))
          .where((p) => p.isNotEmpty)
          .toList();

      String? file;
      String? url;
      String? nameRu;
      String? nameEn;
      String? nameEl;

      if (parts.length >= 2) {
        file = parts[0].trim();
        url = parts[1].trim();
        if (parts.length >= 3) nameRu = parts[2].trim();
        if (parts.length >= 4) nameEn = parts[3].trim();
        if (parts.length >= 5) nameEl = parts[4].trim();
      } else if (parts.length == 1) {
        url = parts[0].trim();
      }

      if (url == null || url.isEmpty) continue;

      // если file отсутствует — вытащим из URL последний сегмент
      file ??= Uri.parse(url).pathSegments.isNotEmpty
          ? Uri.parse(url).pathSegments.last
          : 'dict_${result.length + 1}.json';

      // уберём .json/.txt из базового имени
      final baseName =
      file.replaceAll(RegExp(r'\.(json|txt)$', caseSensitive: false), '');
      nameRu ??= baseName;
      nameEn ??= baseName;
      nameEl ??= baseName;

      result.add(DictionaryInfo(
        file: file,
        nameRu: nameRu,
        nameEn: nameEn,
        nameEl: nameEl,
        filePath: url,
      ));
    }

    return result;
  }

  DictionaryInfo _dictFromAnyMap(Map<String, dynamic> m) {
    String file = (m['file'] ?? m['filename'] ?? m['id'] ?? '').toString();
    String filePath = (m['filePath'] ?? m['url'] ?? m['href'] ?? '').toString();

    // имена
    String nameRu =
    (m['name_ru'] ?? m['ru'] ?? m['nameRu'] ?? m['title_ru'] ?? file)
        .toString();
    String nameEn =
    (m['name_en'] ?? m['en'] ?? m['nameEn'] ?? m['title_en'] ?? file)
        .toString();
    String nameEl =
    (m['name_el'] ?? m['el'] ?? m['nameEl'] ?? m['title_el'] ?? file)
        .toString();

    if (file.isEmpty) {
      // если file не задан — вытащим из URL
      if (filePath.isNotEmpty) {
        final segs = Uri.parse(filePath).pathSegments;
        if (segs.isNotEmpty) file = segs.last;
      } else {
        file = 'dict_${DateTime.now().millisecondsSinceEpoch}.json';
      }
    }

    final baseName =
    file.replaceAll(RegExp(r'\.(json|txt)$', caseSensitive: false), '');
    nameRu = nameRu.isEmpty ? baseName : nameRu;
    nameEn = nameEn.isEmpty ? baseName : nameEn;
    nameEl = nameEl.isEmpty ? baseName : nameEl;

    return DictionaryInfo(
      file: file,
      nameRu: nameRu,
      nameEn: nameEn,
      nameEl: nameEl,
      filePath: filePath,
    );
  }

  Future<void> _rebuildActiveWords() async {
    final List<Word> list = [];
    for (final id in selectedDictionaries) {
      final words = _wordsCache[id];
      if (words != null) list.addAll(words);
    }
    activeWords = list;
  }

  Future<void> _ensureWordsLoadedForSelection() async {
    if (selectedDictionaries.isEmpty) {
      activeWords = [];
      return;
    }
    final dir = await _dictionariesDir();
    for (final id in selectedDictionaries) {
      if (_wordsCache.containsKey(id)) continue;

      if (id == favoritesFile) {
        // особая загрузка избранного
        await _loadFavoritesIntoCache();
        continue;
      }

      final file = File('${dir.path}/$id');
      if (await file.exists()) {
        final list = await _readWordsListFromFile(file, id);
        _wordsCache[id] = list;
      } else {
        _wordsCache[id] = const <Word>[];
      }
    }
  }

  /// Грузим **все** словари из папки в кэш (для режима "All words").
  Future<void> _ensureAllCachedLoaded() async {
    final dir = await _dictionariesDir();
    if (!await dir.exists()) return;

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) {
      final name = f.uri.pathSegments.last.toLowerCase();
      // .json и .txt; исключаем служебные index/selected
      final isDataFile = name.endsWith('.json') || name.endsWith('.txt');
      final isService = name == 'index.json' ||
          name == 'selected.json' ||
          name == 'index.txt' ||
          name == 'selected.txt';
      return isDataFile && !isService;
    })
        .toList();

    for (final f in files) {
      final id = f.uri.pathSegments.last; // имя файла — наш dictionaryId
      if (_wordsCache.containsKey(id)) continue;

      if (id == favoritesFile) {
        await _loadFavoritesIntoCache();
        continue;
      }

      try {
        final list = await _readWordsListFromFile(f, id);
        _wordsCache[id] = list;
      } catch (e) {
        _wordsCache[id] = const <Word>[];
      }
    }
  }

  Future<void> _fetchAvailableDictionaries() async {
    final dir = await _dictionariesDir();
    final file = File('${dir.path}/index.json');
    List<DictionaryInfo> list = [];

    if (await file.exists()) {
      try {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          list = decoded
              .map((e) => DictionaryInfo.fromJson(Map<String, dynamic>.from(e)))
              .toList()
              .cast<DictionaryInfo>();
        }
      } catch (_) {
        list = [];
      }
    } else {
      // Fallback: просканировать папку на *.json и *.txt (кроме служебных)
      if (await dir.exists()) {
        final entries = dir
            .listSync()
            .whereType<File>()
            .where((f) {
          final name = f.uri.pathSegments.last.toLowerCase();
          final isDataFile = name.endsWith('.json') || name.endsWith('.txt');
          final isService = name == 'index.json' ||
              name == 'selected.json' ||
              name == 'index.txt' ||
              name == 'selected.txt';
          return isDataFile && !isService;
        });
        for (final f in entries) {
          final name = f.uri.pathSegments.last;
          list.add(DictionaryInfo(
            file: name,
            nameRu: name,
            nameEn: name,
            nameEl: name,
            filePath: f.path,
          ));
        }
      }
    }

    availableDictionaries = list;
    _injectFavoritesIfMissing(); // гарантируем наличие избранного
    _availableLoaded = true;
    notifyListeners();
  }

  Future<void> _loadSelected() async {
    try {
      final file = await _selectedFile();
      if (await file.exists()) {
        final raw = await file.readAsString();
        final list = (jsonDecode(raw) as List).cast<String>();
        selectedDictionaries
          ..clear()
          ..addAll(list);
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _saveSelected() async {
    try {
      final file = await _selectedFile();
      await file.writeAsString(jsonEncode(selectedDictionaries.toList()));
    } catch (_) {
      // ignore
    }
  }

  Future<Directory> _dictionariesDir() async {
    final base = await getApplicationDocumentsDirectory();
    return Directory('${base.path}/dictionaries');
  }

  Future<File> _selectedFile() async {
    final dir = await _dictionariesDir();
    await dir.create(recursive: true);
    return File('${dir.path}/selected.json');
  }

  Future<void> _ensureDirs() async {
    final dir = await _dictionariesDir();
    await dir.create(recursive: true);
  }

  List<Word> _allCachedWords() {
    return _wordsCache.values.expand((e) => e).toList();
  }

  /// Проверяем, что для каждого словаря из индекса файл реально существует.
  Future<bool> _allIndexedFilesPresent(List<DictionaryInfo> list) async {
    if (list.isEmpty) return false;
    final dir = await _dictionariesDir();
    for (final d in list) {
      final f = File('${dir.path}/${d.file}');
      if (!await f.exists()) {
        return false;
      }
    }
    return true;
  }

  // -------- Favorites helpers --------

  Future<void> _ensureFavoritesFileExists() async {
    final dir = await _dictionariesDir();
    final favFile = File('${dir.path}/$favoritesFile');
    if (await favFile.exists()) return;

    // Создаём файл с форматом ids для совместимости с FavoritesService
    await favFile.create(recursive: true);
    await favFile.writeAsString(jsonEncode({'ids': <String>[]}));
  }

  void _injectFavoritesIfMissing() {
    final has = availableDictionaries.any((d) => d.file == favoritesFile);
    if (!has) {
      availableDictionaries = [
        DictionaryInfo(
          file: favoritesFile,
          nameRu: favoritesNameRu,
          nameEn: favoritesNameEn,
          nameEl: favoritesNameEl,
          filePath: favoritesFile, // локальный файл
        ),
        ...availableDictionaries,
      ];
    }
  }

  /// Прочитать список слов из файла словаря (поддержка форматов):
  ///  - JSON-массив: [ {...}, {...} ]
  ///  - Объект с ключом "words": { "words": [ {...}, ... ] }
  ///  - Для избранного возможен формат { "ids": [ "dictId|el", ... ] }
  Future<List<Word>> _readWordsListFromFile(File f, String dictionaryId) async {
    final raw = await f.readAsString();
    final decoded = jsonDecode(raw);

    // 1) массив объектов
    if (decoded is List) {
      return decoded
          .where((e) => e is Map)
          .map((e) => Word.fromJson(Map<String, dynamic>.from(e as Map), dictionaryId))
          .toList();
    }

    // 2) объект с "words"
    if (decoded is Map && decoded['words'] is List) {
      final list = decoded['words'] as List;
      return list
          .where((e) => e is Map)
          .map((e) => Word.fromJson(Map<String, dynamic>.from(e as Map), dictionaryId))
          .toList();
    }

    // 3) особый случай: избранное по "ids"
    if (dictionaryId == favoritesFile && decoded is Map && decoded['ids'] is List) {
      final ids = (decoded['ids'] as List).whereType<String>().toList();
      // убеждаемся, что весь пул слов загружен — будем матчить по Word.id
      await _ensureAllCachedLoaded();
      final all = _allCachedWords();
      final byId = {for (final w in all) w.id: w};
      return [
        for (final id in ids)
          if (byId[id] != null) byId[id]!,
      ];
    }

    return const <Word>[];
  }

  /// Загрузка favorites в кэш, с поддержкой всех форматов
  Future<void> _loadFavoritesIntoCache() async {
    final dir = await _dictionariesDir();
    final favFile = File('${dir.path}/$favoritesFile');
    if (!await favFile.exists()) {
      await _ensureFavoritesFileExists();
    }
    try {
      // Читаем файл и парсим
      final raw = await favFile.readAsString();
      final decoded = jsonDecode(raw);

      // Обрабатываем формат с ids
      if (decoded is Map && decoded['ids'] is List) {
        final ids = (decoded['ids'] as List).whereType<String>().toList();

        // Убеждаемся, что все словари загружены
        await _ensureAllCachedLoaded();

        // Собираем слова по ID
        final all = _allCachedWords();
        final byId = {for (final w in all) w.id: w};

        final favoriteWords = <Word>[];
        for (final id in ids) {
          if (byId[id] != null) {
            favoriteWords.add(byId[id]!);
          }
        }

        _wordsCache[favoritesFile] = favoriteWords;
      }
      // Обрабатываем формат с words (старый формат)
      else if (decoded is Map && decoded['words'] is List) {
        final list = decoded['words'] as List;
        final words = list
            .where((e) => e is Map)
            .map((e) => Word.fromJson(Map<String, dynamic>.from(e as Map), favoritesFile))
            .toList();
        _wordsCache[favoritesFile] = words;
      }
      // Пустой массив слов по умолчанию
      else {
        _wordsCache[favoritesFile] = const <Word>[];
      }
    } catch (e) {
      debugPrint('[DictionaryService] Error loading favorites: $e');
      _wordsCache[favoritesFile] = const <Word>[];
    }
  }
}

// Riverpod providers
final dictionaryServiceProvider =
ChangeNotifierProvider<DictionaryService>((ref) => DictionaryService());

final availableDictionariesProvider =
FutureProvider<List<DictionaryInfo>>((ref) async {
  final service = ref.read(dictionaryServiceProvider);
  await service.ensureAvailableLoaded();
  return service.availableDictionaries;
});
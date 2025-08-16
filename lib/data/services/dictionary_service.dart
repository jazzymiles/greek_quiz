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

  void _log(String msg) => debugPrint('[DictionaryService] $msg');

  // ---- Public API ----

  /// Базовая инициализация без автозагрузки.
  Future<void> initialize() async {
    _log('initialize(): start');
    await _ensureDirs();
    await _ensureFavoritesFileExists();
    await ensureAvailableLoaded();
    _injectFavoritesIfMissing();
    await _loadSelected();

    // подгрузим слова из выбранных словарей
    await _ensureWordsLoadedForSelection();

    // прогрузим в кэш все словари из папки (кроме избранного)
    await _ensureAllCachedLoaded();

    // пересоберём избранное (после появления словарей ids смогут резолвиться)
    await _loadFavoritesIntoCache();

    _rebuildActiveWords();
    _log('initialize(): done; available=${availableDictionaries.length}, selected=${selectedDictionaries.length}, activeWords=${activeWords.length}');
    notifyListeners();
  }

  /// Инициализация + автозагрузка словарей, если их нет (первый запуск).
  Future<void> initializeWithBootstrap({
    String interfaceLanguage = 'en',
    String? indexUrlIfBootstrap,
  }) async {
    _log('initializeWithBootstrap(): start; lang=$interfaceLanguage, indexUrlIfBootstrap=${indexUrlIfBootstrap ?? "(null)"}');
    await initialize();

    if (indexUrlIfBootstrap == null || indexUrlIfBootstrap.isEmpty) {
      _log('initializeWithBootstrap(): no indexUrl provided -> return');
      return;
    }

    // игнорируем виртуальный словарь избранного
    final realDictionaries = availableDictionaries
        .where((d) => d.file != favoritesFile)
        .toList(growable: false);

    _log('initializeWithBootstrap(): realDictionaries=${realDictionaries.length} -> [${realDictionaries.map((e)=>e.file).join(', ')}]');

    final needBootstrap =
        realDictionaries.isEmpty ||
            !(await _allIndexedFilesPresent(realDictionaries));

    _log('initializeWithBootstrap(): needBootstrap=$needBootstrap');

    if (needBootstrap) {
      try {
        _log('initializeWithBootstrap(): calling downloadAndSaveDictionaries()');
        await downloadAndSaveDictionaries(
          interfaceLanguage,
          indexUrl: indexUrlIfBootstrap,
        );
      } catch (e) {
        _log('initializeWithBootstrap(): download failed: $e');
      } finally {
        _log('initializeWithBootstrap(): finalizing state after bootstrap');
        await ensureAvailableLoaded();
        _injectFavoritesIfMissing();
        await _ensureAllCachedLoaded();
        await _loadFavoritesIntoCache();
        await _ensureWordsLoadedForSelection();
        _rebuildActiveWords();
        _log('initializeWithBootstrap(): done; available=${availableDictionaries.length}, activeWords=${activeWords.length}');
        notifyListeners();
      }
    } else {
      _log('initializeWithBootstrap(): bootstrap not needed');
    }
  }

  /// Ensure list of available dictionaries is loaded exactly once.
  Future<void> ensureAvailableLoaded() async {
    if (_availableLoaded && availableDictionaries.isNotEmpty) {
      _log('ensureAvailableLoaded(): already loaded; available=${availableDictionaries.length}');
      return;
    }
    _log('ensureAvailableLoaded(): loading...');
    _availableLoadFuture ??= _fetchAvailableDictionaries();
    try {
      await _availableLoadFuture;
    } finally {
      _availableLoadFuture = null;
      _log('ensureAvailableLoaded(): loaded; available=${availableDictionaries.length}');
    }
  }

  /// Toggle selection of a dictionary by its id (file).
  void toggleDictionarySelection(String fileId) {
    final before = selectedDictionaries.length;
    if (selectedDictionaries.contains(fileId)) {
      selectedDictionaries.remove(fileId);
      _log('toggleDictionarySelection("$fileId"): removed (before=$before -> after=${selectedDictionaries.length})');
    } else {
      selectedDictionaries.add(fileId);
      _log('toggleDictionarySelection("$fileId"): added (before=$before -> after=${selectedDictionaries.length})');
    }
    _saveSelected(); // fire-and-forget
    _ensureWordsLoadedForSelection(); // preload words (включая избранное)
    _rebuildActiveWords();
    notifyListeners();
  }

  /// Re-compute activeWords from selected dictionaries.
  /// Важно: без notifyListeners() — иначе Riverpod может упасть при вызове в инициализации других провайдеров.
  void filterActiveWords() {
    _log('filterActiveWords(): recompute from selected=${selectedDictionaries.length}');
    _ensureWordsLoadedForSelection(); // без await — как и раньше
    _rebuildActiveWords();
    // нет notifyListeners() умышленно
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
  List<Word> getQuizOptions({
    required Word excludeWord,
    bool useAllWords = false,
    int count = 3,
  }) {
    List<Word> pool;

    if (useAllWords) {
      final allCached = _allCachedWords();
      pool = allCached.isNotEmpty ? List<Word>.from(allCached) : List<Word>.from(activeWords);
      _log('getQuizOptions(): useAllWords=true; pool=${pool.length}');
    } else {
      pool = List<Word>.from(activeWords);
      _log('getQuizOptions(): useAllWords=false; pool=${pool.length}');
    }

    final seen = <String>{excludeWord.id};
    final filtered = <Word>[];
    for (final w in pool) {
      if (seen.add(w.id)) filtered.add(w);
    }

    filtered.shuffle(_random);
    final result = filtered.take(count).toList();
    _log('getQuizOptions(): result=${result.length} (requested $count)');
    return result;
  }

  /// Обновить кэш избранного после изменений в FavoritesService
  Future<void> refreshFavorites() async {
    _log('refreshFavorites(): start');
    await _loadFavoritesIntoCache();
    if (selectedDictionaries.contains(favoritesFile)) {
      _rebuildActiveWords();
      notifyListeners();
    }
    _log('refreshFavorites(): done; favWords=${_wordsCache[favoritesFile]?.length ?? 0}, active=${activeWords.length}');
  }

  // ---- Download dictionaries (remote-only) ----

  /// Downloads index and dictionaries it references into app storage.
  Future<void> downloadAndSaveDictionaries(
      String interfaceLanguage, {
        String? indexUrl,
      }) async {
    if (indexUrl == null || indexUrl.isEmpty) {
      _log('downloadAndSaveDictionaries(): no indexUrl -> return');
      return;
    }

    isDownloading = true;
    downloadProgress = 0.0;
    statusMessage = 'downloading_dictionaries';
    _log('downloadAndSaveDictionaries(): start; lang=$interfaceLanguage, url=$indexUrl');
    notifyListeners();

    try {
      final dir = await _dictionariesDir();
      await dir.create(recursive: true);

      _log('downloadAndSaveDictionaries(): fetching index...');
      final resp = await http.get(Uri.parse(indexUrl));
      _log('downloadAndSaveDictionaries(): index status=${resp.statusCode}');
      if (resp.statusCode != 200) {
        throw Exception('Index download failed: ${resp.statusCode}');
      }
      final body = utf8.decode(resp.bodyBytes);

      final List<DictionaryInfo> list = _parseIndex(body);
      _log('downloadAndSaveDictionaries(): parsed index -> ${list.length} items');

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
      _log('downloadAndSaveDictionaries(): index.json saved to ${indexFile.path}');

      int i = 0;
      for (final d in list) {
        i++;
        downloadProgress = i / (list.isEmpty ? 1 : list.length);
        notifyListeners();

        final target = File('${dir.path}/${d.file}');
        _log('downloadAndSaveDictionaries(): [$i/${list.length}] fetching "${d.file}" from "${d.filePath}" -> ${target.path}');
        if (d.filePath.toLowerCase().startsWith('http')) {
          final r = await http.get(Uri.parse(d.filePath));
          if (r.statusCode == 200) {
            await target.writeAsBytes(r.bodyBytes);
            _log('downloadAndSaveDictionaries(): saved ${d.file} (${r.bodyBytes.length} bytes)');
          } else {
            _log('downloadAndSaveDictionaries(): SKIP ${d.file}, http ${r.statusCode}');
          }
        } else {
          _log('downloadAndSaveDictionaries(): SKIP ${d.file}, non-http path');
        }
      }

      _log('downloadAndSaveDictionaries(): refreshing internal state...');
      await _fetchAvailableDictionaries();
      _injectFavoritesIfMissing();
      await _ensureAllCachedLoaded();
      await _loadFavoritesIntoCache();
      await _ensureWordsLoadedForSelection();
      _rebuildActiveWords();

      statusMessage = 'all_dictionaries_updated';
      _log('downloadAndSaveDictionaries(): done; available=${availableDictionaries.length}, active=${activeWords.length}');
    } catch (e) {
      statusMessage = 'download_error';
      _log('downloadAndSaveDictionaries(): ERROR $e');
      rethrow;
    } finally {
      isDownloading = false;
      downloadProgress = 0.0;
      notifyListeners();
      _log('downloadAndSaveDictionaries(): finalize overlay -> isDownloading=false');
    }
  }

  // ---- Internals ----

  List<DictionaryInfo> _parseIndex(String body) {
    try {
      final dynamic decoded = jsonDecode(body);
      _log('_parseIndex(): JSON detected (${decoded.runtimeType})');

      if (decoded is List) {
        final res = decoded.map<DictionaryInfo>((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return _dictFromAnyMap(m);
        }).toList();
        _log('_parseIndex(): JSON list -> ${res.length}');
        return res;
      }

      if (decoded is Map && decoded['dictionaries'] is List) {
        final list = (decoded['dictionaries'] as List);
        final res = list.map<DictionaryInfo>((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return _dictFromAnyMap(m);
        }).toList();
        _log('_parseIndex(): JSON map.dictionaries -> ${res.length}');
        return res;
      }
      _log('_parseIndex(): JSON format not recognized, try text lines');
    } catch (_) {
      _log('_parseIndex(): not JSON, parse as text lines');
    }

    final result = <DictionaryInfo>[];
    final lines = const LineSplitter().convert(body);
    _log('_parseIndex(): text lines=${lines.length}');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#')) continue;

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

      file ??= Uri.parse(url).pathSegments.isNotEmpty
          ? Uri.parse(url).pathSegments.last
          : 'dict_${result.length + 1}.json';

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
    _log('_parseIndex(): text parsed -> ${result.length}');
    return result;
  }

  DictionaryInfo _dictFromAnyMap(Map<String, dynamic> m) {
    String file = (m['file'] ?? m['filename'] ?? m['id'] ?? '').toString();
    String filePath = (m['filePath'] ?? m['url'] ?? m['href'] ?? '').toString();

    String nameRu =
    (m['name_ru'] ?? m['ru'] ?? m['nameRu'] ?? m['title_ru'] ?? file).toString();
    String nameEn =
    (m['name_en'] ?? m['en'] ?? m['nameEn'] ?? m['title_en'] ?? file).toString();
    String nameEl =
    (m['name_el'] ?? m['el'] ?? m['nameEl'] ?? m['title_el'] ?? file).toString();

    if (file.isEmpty) {
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

  void _rebuildActiveWords() {
    final List<Word> list = [];
    for (final id in selectedDictionaries) {
      final words = _wordsCache[id];
      if (words != null) list.addAll(words);
    }
    activeWords = list;
    _log('_rebuildActiveWords(): selected=${selectedDictionaries.length}, active=${activeWords.length}');
  }

  Future<void> _ensureWordsLoadedForSelection() async {
    _log('_ensureWordsLoadedForSelection(): selected=${selectedDictionaries.length}');
    if (selectedDictionaries.isEmpty) {
      activeWords = [];
      _log('_ensureWordsLoadedForSelection(): no selection -> active cleared');
      return;
    }
    final dir = await _dictionariesDir();
    for (final id in selectedDictionaries) {
      if (_wordsCache.containsKey(id)) {
        _log('_ensureWordsLoadedForSelection(): cache hit "$id" -> ${_wordsCache[id]?.length ?? 0}');
        continue;
      }

      if (id == favoritesFile) {
        _log('_ensureWordsLoadedForSelection(): load favorites "$favoritesFile"');
        await _loadFavoritesIntoCache();
        _log('_ensureWordsLoadedForSelection(): favorites loaded -> ${_wordsCache[favoritesFile]?.length ?? 0}');
        continue;
      }

      final file = File('${dir.path}/$id');
      if (await file.exists()) {
        final list = await _readWordsListFromFile(file, id);
        _wordsCache[id] = list;
        _log('_ensureWordsLoadedForSelection(): loaded "$id" -> ${list.length}');
      } else {
        _wordsCache[id] = const <Word>[];
        _log('_ensureWordsLoadedForSelection(): file missing "$id" -> 0');
      }
    }
  }

  /// Грузим **все** словари из папки в кэш (для режима "All words"), КРОМЕ избранного.
  Future<void> _ensureAllCachedLoaded() async {
    final dir = await _dictionariesDir();
    if (!await dir.exists()) {
      _log('_ensureAllCachedLoaded(): dictionaries dir not exists');
      return;
    }

    final files = dir
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
    })
        .toList();

    _log('_ensureAllCachedLoaded(): files to consider=${files.length}');

    for (final f in files) {
      final id = f.uri.pathSegments.last;

      if (id == favoritesFile) {
        _log('_ensureAllCachedLoaded(): skip favorites "$id"');
        continue; // важно: не трогаем избранное тут, чтобы не зациклиться
      }

      if (_wordsCache.containsKey(id)) {
        _log('_ensureAllCachedLoaded(): cache hit "$id"');
        continue;
      }

      try {
        final list = await _readWordsListFromFile(f, id);
        _wordsCache[id] = list;
        _log('_ensureAllCachedLoaded(): loaded "$id" -> ${list.length}');
      } catch (e) {
        _wordsCache[id] = const <Word>[];
        _log('_ensureAllCachedLoaded(): ERROR loading "$id": $e');
      }
    }
  }

  Future<void> _fetchAvailableDictionaries() async {
    final dir = await _dictionariesDir();
    final file = File('${dir.path}/index.json');
    List<DictionaryInfo> list = [];

    if (await file.exists()) {
      _log('_fetchAvailableDictionaries(): reading index.json');
      try {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          list = decoded
              .map((e) => DictionaryInfo.fromJson(Map<String, dynamic>.from(e)))
              .toList()
              .cast<DictionaryInfo>();
          _log('_fetchAvailableDictionaries(): index.json -> ${list.length}');
        }
      } catch (e) {
        _log('_fetchAvailableDictionaries(): ERROR parse index.json: $e');
        list = [];
      }
    } else {
      _log('_fetchAvailableDictionaries(): index.json not found; scanning dir');
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
        _log('_fetchAvailableDictionaries(): scan -> ${list.length}');
      } else {
        _log('_fetchAvailableDictionaries(): dictionaries dir missing');
      }
    }

    availableDictionaries = list;
    _injectFavoritesIfMissing();
    _availableLoaded = true;
    _log('_fetchAvailableDictionaries(): final available=${availableDictionaries.length}');
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
        _log('_loadSelected(): loaded ${selectedDictionaries.length} items');
      } else {
        _log('_loadSelected(): selected.json not found');
      }
    } catch (e) {
      _log('_loadSelected(): ERROR $e');
    }
  }

  Future<void> _saveSelected() async {
    try {
      final file = await _selectedFile();
      await file.writeAsString(jsonEncode(selectedDictionaries.toList()));
      _log('_saveSelected(): saved ${selectedDictionaries.length} items');
    } catch (e) {
      _log('_saveSelected(): ERROR $e');
    }
  }

  Future<Directory> _dictionariesDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/dictionaries');
    return dir;
  }

  Future<File> _selectedFile() async {
    final dir = await _dictionariesDir();
    await dir.create(recursive: true);
    return File('${dir.path}/selected.json');
  }

  Future<void> _ensureDirs() async {
    final dir = await _dictionariesDir();
    await dir.create(recursive: true);
    _log('_ensureDirs(): ensured ${dir.path}');
  }

  List<Word> _allCachedWords() {
    return _wordsCache.values.expand((e) => e).toList();
  }

  /// Проверяем, что для каждого словаря из индекса файл реально существует.
  Future<bool> _allIndexedFilesPresent(List<DictionaryInfo> list) async {
    if (list.isEmpty) {
      _log('_allIndexedFilesPresent(): list is empty -> false');
      return false;
    }
    final dir = await _dictionariesDir();
    for (final d in list) {
      final f = File('${dir.path}/${d.file}');
      final exists = await f.exists();
      if (!exists) {
        _log('_allIndexedFilesPresent(): missing file "${d.file}"');
        return false;
      } else {
        _log('_allIndexedFilesPresent(): present "${d.file}"');
      }
    }
    _log('_allIndexedFilesPresent(): all present -> true');
    return true;
  }

  // -------- Favorites helpers --------

  Future<void> _ensureFavoritesFileExists() async {
    final dir = await _dictionariesDir();
    final favFile = File('${dir.path}/$favoritesFile');
    if (await favFile.exists()) {
      _log('_ensureFavoritesFileExists(): exists -> ${favFile.path}');
      return;
    }

    await favFile.create(recursive: true);
    await favFile.writeAsString(jsonEncode({'ids': <String>[]}));
    _log('_ensureFavoritesFileExists(): created empty -> ${favFile.path}');
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
          filePath: favoritesFile,
        ),
        ...availableDictionaries,
      ];
      _log('_injectFavoritesIfMissing(): injected virtual dictionary "$favoritesFile"');
    } else {
      _log('_injectFavoritesIfMissing(): already present "$favoritesFile"');
    }
  }

  /// Локальный хелпер: клонирует слово и подменяет dictionaryId на favoritesFile.
  Word _asFavorite(Word w) {
    // 1) copyWith(dictionaryId: ...)
    try {
      final dynamic dyn = w;
      final Word clone = dyn.copyWith(dictionaryId: favoritesFile) as Word;
      return clone;
    } catch (e) {
      _log('_asFavorite(): copyWith not available ($e), try toJson/fromJson');
    }

    // 2) toJson -> fromJson + новый dictionaryId
    try {
      final dynamic dyn = w;
      final Map<String, dynamic> m =
      Map<String, dynamic>.from(dyn.toJson() as Map);
      final Word clone = Word.fromJson(m, favoritesFile);
      return clone;
    } catch (e) {
      _log('_asFavorite(): toJson/fromJson failed ($e), return original');
    }

    // 3) fallback — вернём оригинал (худший случай: не сгруппируется)
    return w;
  }

  /// Прочитать список слов из файла словаря (несколько форматов)
  Future<List<Word>> _readWordsListFromFile(File f, String dictionaryId) async {
    final raw = await f.readAsString();
    final decoded = jsonDecode(raw);

    if (decoded is List) {
      final res = decoded
          .where((e) => e is Map)
          .map((e) => Word.fromJson(Map<String, dynamic>.from(e as Map), dictionaryId))
          .toList();
      _log('_readWordsListFromFile("$dictionaryId"): JSON list -> ${res.length}');
      return res;
    }

    if (decoded is Map && decoded['words'] is List) {
      final list = decoded['words'] as List;
      final res = list
          .where((e) => e is Map)
          .map((e) => Word.fromJson(Map<String, dynamic>.from(e as Map), dictionaryId))
          .toList();
      _log('_readWordsListFromFile("$dictionaryId"): JSON map.words -> ${res.length}');
      return res;
    }

    // избранное как ids -> резолвим только по уже загруженным словам и ПЕРЕПИСЫВАЕМ dictionaryId на favoritesFile
    if (dictionaryId == favoritesFile && decoded is Map && decoded['ids'] is List) {
      final ids = (decoded['ids'] as List).whereType<String>().toList();
      _log('_readWordsListFromFile("$dictionaryId"): ids format -> count=${ids.length}');
      final all = _allCachedWords(); // только уже загруженные словари
      final byId = {for (final w in all) w.id: w};
      final res = <Word>[
        for (final id in ids)
          if (byId[id] != null) _asFavorite(byId[id]!), // важная подмена
      ];
      _log('_readWordsListFromFile("$dictionaryId"): resolved words -> ${res.length}');
      return res;
    }

    _log('_readWordsListFromFile("$dictionaryId"): unknown format -> 0');
    return const <Word>[];
  }

  /// Загрузка favorites в кэш, с поддержкой форматов и БЕЗ вызова _ensureAllCachedLoaded()
  Future<void> _loadFavoritesIntoCache() async {
    final dir = await _dictionariesDir();
    final favFile = File('${dir.path}/$favoritesFile');
    if (!await favFile.exists()) {
      _log('_loadFavoritesIntoCache(): favorites file missing, creating...');
      await _ensureFavoritesFileExists();
    }
    try {
      final raw = await favFile.readAsString();
      final decoded = jsonDecode(raw);

      if (decoded is Map && decoded['ids'] is List) {
        final ids = (decoded['ids'] as List).whereType<String>().toList();
        _log('_loadFavoritesIntoCache(): ids=${ids.length}');

        // Резолвим ТОЛЬКО по уже загруженным словарям (без рекурсии)
        final all = _allCachedWords();
        final byId = {for (final w in all) w.id: w};

        final favoriteWords = <Word>[];
        for (final id in ids) {
          final w = byId[id];
          if (w != null) {
            favoriteWords.add(_asFavorite(w)); // важная подмена dictionaryId
          }
        }

        _wordsCache[favoritesFile] = favoriteWords;
        _log('_loadFavoritesIntoCache(): cached favorites -> ${favoriteWords.length}');
      } else if (decoded is Map && decoded['words'] is List) {
        final list = decoded['words'] as List;
        final words = list
            .where((e) => e is Map)
            .map((e) => Word.fromJson(Map<String, dynamic>.from(e as Map), favoritesFile))
            .toList();
        _wordsCache[favoritesFile] = words;
        _log('_loadFavoritesIntoCache(): cached favorites (words field) -> ${words.length}');
      } else {
        _wordsCache[favoritesFile] = const <Word>[];
        _log('_loadFavoritesIntoCache(): favorites unknown format -> 0');
      }
    } catch (e) {
      _log('_loadFavoritesIntoCache(): ERROR $e');
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

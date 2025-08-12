import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:greek_quiz/data/models/dictionary_info.dart';
import 'package:greek_quiz/data/models/word.dart';

class DictionaryService extends ChangeNotifier {
  // SharedPreferences ключи
  static const _prefsDownloadedKey = 'dicts_installed_v1';
  static const _prefsSelectedDictsKey = 'selected_dictionaries_v1';

  final Random _random = Random();

  // Данные по словарям
  List<DictionaryInfo> availableDictionaries = [];
  Set<String> selectedDictionaries = {}; // файлы словарей (id)
  List<Word> _allLoadedWords = [];

  // Состояние активной выборки
  List<Word> activeWords = [];

  // Состояние загрузки/обновления словарей
  bool isDownloading = false;
  double downloadProgress = 0.0;
  String statusMessage = "";

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1) справочник словарей (с сервера)
    await fetchAvailableDictionaries();

    // 2) восстановим выбранные словари (если ранее сохраняли)
    await _loadSelectedDictionaries();

    // 3) подхватим локально сохранённые слова (если есть на диске)
    await loadAllWordsFromDisk();

    // 4) применим выбор
    filterActiveWords();

    _isInitialized = true;
  }

  Future<void> _loadSelectedDictionaries() async {
    try {
      final p = await SharedPreferences.getInstance();
      final saved = p.getStringList(_prefsSelectedDictsKey);
      if (saved != null) {
        selectedDictionaries = saved.toSet();
      }
    } catch (_) {
      // игнорируем
    }
  }

  Future<void> _saveSelectedDictionaries() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(
        _prefsSelectedDictsKey,
        List<String>.from(selectedDictionaries),
      );
    } catch (_) {
      // игнорируем
    }
  }

  void toggleDictionarySelection(String fileId) {
    if (selectedDictionaries.contains(fileId)) {
      selectedDictionaries.remove(fileId);
    } else {
      selectedDictionaries.add(fileId);
    }
    _saveSelectedDictionaries();
    notifyListeners();
  }

  Future<void> fetchAvailableDictionaries() async {
    if (availableDictionaries.isNotEmpty) return;
    try {
      final url = Uri.parse('https://redinger.cc/greekquiz/settings.txt');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final settingsJson = json.decode(response.body) as Map<String, dynamic>;
        final dictionariesList = settingsJson['dictionaries'] as List;
        availableDictionaries = dictionariesList
            .map((json) => DictionaryInfo.fromJson(json as Map<String, dynamic>))
            .toList();

        // ВАЖНО: не выбираем автоматически ни один словарь по умолчанию.
      } else {
        throw Exception('Failed to load settings from server');
      }
    } catch (e) {
      if (kDebugMode) {
        print("Ошибка загрузки списка словарей: $e");
      }
      availableDictionaries = [];
    }
  }

  Future<void> loadAllWordsFromDisk() async {
    _allLoadedWords.clear();

    final Directory supportDir = await getApplicationSupportDirectory();
    final dictionariesDir =
    Directory('${supportDir.path}/DownloadedDictionaries');
    if (!await dictionariesDir.exists()) return;

    for (final dictInfo in availableDictionaries) {
      final file = File('${dictionariesDir.path}/${dictInfo.file}');
      if (await file.exists()) {
        try {
          final jsonString = await file.readAsString();
          final List<dynamic> jsonList = json.decode(jsonString);
          _allLoadedWords.addAll(
            jsonList.map((e) => Word.fromJson(e as Map<String, dynamic>, dictInfo.file)),
          );
        } catch (e) {
          if (kDebugMode) {
            print("Ошибка парсинга файла ${dictInfo.file}: $e");
          }
        }
      }
    }

    if (kDebugMode) {
      print("С диска загружено ${_allLoadedWords.length} слов");
    }
  }

  void filterActiveWords() {
    activeWords = [];
    if (selectedDictionaries.isEmpty) {
      notifyListeners();
      return;
    }

    activeWords = _allLoadedWords
        .where((w) => selectedDictionaries.contains(w.dictionaryId))
        .toList()
      ..shuffle(_random);

    notifyListeners();
  }

  Future<void> downloadAndSaveDictionaries(String interfaceLanguage) async {
    isDownloading = true;
    statusMessage = "downloading_dictionaries";
    downloadProgress = 0.0;
    notifyListeners();

    try {
      final Directory supportDir = await getApplicationSupportDirectory();
      final dictionariesDir =
      Directory('${supportDir.path}/DownloadedDictionaries');
      if (!await dictionariesDir.exists()) {
        await dictionariesDir.create(recursive: true);
      }

      final total = availableDictionaries.length;
      for (int i = 0; i < total; i++) {
        final dictInfo = availableDictionaries[i];

        // отображаем имя текущего словаря (локализованное) как статус
        statusMessage = dictInfo.getLocalizedName(interfaceLanguage);
        downloadProgress = (i + 1) / total;
        notifyListeners();

        final resp = await http.get(Uri.parse(dictInfo.filePath));
        if (resp.statusCode == 200) {
          final file = File('${dictionariesDir.path}/${dictInfo.file}');
          // тело в UTF-8
          await file.writeAsString(
            utf8.decode(resp.bodyBytes),
            flush: true,
          );
        } else {
          if (kDebugMode) {
            print('Ошибка HTTP ${resp.statusCode} при загрузке ${dictInfo.filePath}');
          }
        }
      }

      statusMessage = "all_dictionaries_updated";
      notifyListeners();

      // перечитываем базу и активные слова
      await loadAllWordsFromDisk();
      filterActiveWords();

      // пометим, что словари установлены (для HomeScreen логики)
      try {
        final p = await SharedPreferences.getInstance();
        await p.setBool(_prefsDownloadedKey, true);
      } catch (_) {}

    } catch (e) {
      statusMessage = "download_error";
      notifyListeners();
      if (kDebugMode) print("Ошибка при скачивании словарей: $e");
    } finally {
      // небольшая задержка, чтобы пользователь увидел финальный статус
      await Future.delayed(const Duration(seconds: 1));
      isDownloading = false;
      notifyListeners();
    }
  }

  Word? getRandomWord() {
    if (activeWords.isEmpty) return null;
    return activeWords[_random.nextInt(activeWords.length)];
  }

  List<Word> getQuizOptions({
    required Word excludeWord,
    required bool useAllWords,
    int count = 3,
  }) {
    final source = useAllWords ? _allLoadedWords : activeWords;
    if (source.length < count + 1) return [];

    final options = List<Word>.from(source)
      ..removeWhere((w) => w.id == excludeWord.id)
      ..shuffle(_random);

    return options.take(count).toList();
  }
}

final dictionaryServiceProvider =
ChangeNotifierProvider<DictionaryService>((ref) {
  return DictionaryService();
});

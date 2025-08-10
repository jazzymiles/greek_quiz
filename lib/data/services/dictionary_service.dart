import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/dictionary_info.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DictionaryService extends ChangeNotifier {
  List<Word> activeWords = [];
  List<DictionaryInfo> availableDictionaries = [];
  Set<String> selectedDictionaries = {};
  bool isDownloading = false;
  double downloadProgress = 0.0;
  String statusMessage = "";
  List<Word> _allLoadedWords = [];
  final Random _random = Random();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await fetchAvailableDictionaries();
    await loadAllWordsFromDisk();
    filterActiveWords();
    _isInitialized = true;
  }

  void toggleDictionarySelection(String fileId) {
    if (selectedDictionaries.contains(fileId)) {
      selectedDictionaries.remove(fileId);
    } else {
      selectedDictionaries.add(fileId);
    }
    notifyListeners();
  }

  Future<void> loadAllWordsFromDisk() async {
    _allLoadedWords.clear();
    final Directory supportDir = await getApplicationSupportDirectory();
    final dictionariesDir = Directory('${supportDir.path}/DownloadedDictionaries');
    if (!await dictionariesDir.exists()) return;

    for (final dictInfo in availableDictionaries) {
      final file = File('${dictionariesDir.path}/${dictInfo.file}');
      if (await file.exists()) {
        try {
          final jsonString = await file.readAsString();
          final List<dynamic> jsonList = json.decode(jsonString);
          _allLoadedWords.addAll(jsonList.map((json) => Word.fromJson(json, dictInfo.file)));
        } catch(e) {
          print("Ошибка парсинга файла ${dictInfo.file}: $e");
        }
      }
    }
    print("Всего загружено с диска ${_allLoadedWords.length} слов.");
  }

  void filterActiveWords() {
    activeWords.clear();
    if (selectedDictionaries.isEmpty) {
      print("Словари не выбраны, активных слов нет.");
      notifyListeners();
      return;
    }

    activeWords = _allLoadedWords
        .where((word) => selectedDictionaries.contains(word.dictionaryId))
        .toList();

    print("Отфильтровано ${activeWords.length} активных слов из ${selectedDictionaries.length} словарей.");
    activeWords.shuffle(_random);
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
        if (availableDictionaries.isNotEmpty && selectedDictionaries.isEmpty) {
          selectedDictionaries.add(availableDictionaries.first.file);
        }
      } else {
        throw Exception('Failed to load settings from server');
      }
    } catch (e) {
      print("Ошибка загрузки настроек словарей: $e");
      availableDictionaries = [];
    }
  }

  Future<void> downloadAndSaveDictionaries(String interfaceLanguage) async {
    isDownloading = true;
    statusMessage = "downloading_dictionaries";
    downloadProgress = 0.0;
    notifyListeners();
    try {
      final Directory supportDir = await getApplicationSupportDirectory();
      final dictionariesDir = Directory('${supportDir.path}/DownloadedDictionaries');
      if (!await dictionariesDir.exists()) await dictionariesDir.create(recursive: true);

      int total = availableDictionaries.length;
      for (int i = 0; i < total; i++) {
        final dictInfo = availableDictionaries[i];
        statusMessage = dictInfo.getLocalizedName(interfaceLanguage);
        downloadProgress = (i + 1) / total;
        notifyListeners();
        final response = await http.get(Uri.parse(dictInfo.filePath));
        if (response.statusCode == 200) {
          final file = File('${dictionariesDir.path}/${dictInfo.file}');
          final decodedBody = utf8.decode(response.bodyBytes);
          await file.writeAsString(decodedBody);
        }
      }
      statusMessage = "all_dictionaries_updated";
      notifyListeners();
      await loadAllWordsFromDisk();
      filterActiveWords();
    } catch (e) {
      statusMessage = "download_error";
      notifyListeners();
      print("Ошибка при скачивании: $e");
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      isDownloading = false;
      notifyListeners();
    }
  }

  Word? getRandomWord() {
    if (activeWords.isEmpty) return null;
    return activeWords[_random.nextInt(activeWords.length)];
  }

  List<Word> getQuizOptions({required Word excludeWord, required bool useAllWords, int count = 3}) {
    final sourceList = useAllWords ? _allLoadedWords : activeWords;
    if (sourceList.length < 4) return [];

    final options = List<Word>.from(sourceList)..removeWhere((word) => word.id == excludeWord.id);
    options.shuffle(_random);
    return options.take(count).toList();
  }
}

final dictionaryServiceProvider = ChangeNotifierProvider<DictionaryService>((ref) {
  return DictionaryService();
});

final availableDictionariesProvider = FutureProvider<List<DictionaryInfo>>((ref) async {
  final service = ref.read(dictionaryServiceProvider);
  await service.fetchAvailableDictionaries();
  return service.availableDictionaries;
});
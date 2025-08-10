// lib/data/providers/dictionary_provider.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/features/settings/app_settings.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';

// Класс для хранения состояния текущего вопроса
class QuizQuestion {
  final Word correctWord;
  final List<String> options;
  final String questionText;
  final String answerText;

  QuizQuestion({
    required this.correctWord,
    required this.options,
    required this.questionText,
    required this.answerText,
  });
}

class DictionaryNotifier extends Notifier<AsyncValue<QuizQuestion>> {
  List<Word> _allWords = [];
  int _currentIndex = 0;
  final Random _random = Random();

  @override
  AsyncValue<QuizQuestion> build() {
    _initialize();
    return const AsyncValue.loading();
  }

  // Вспомогательный метод для получения нужного поля из слова
  String _getWordField(Word word, String langCode) {
    // ИСПРАВЛЕНИЕ: Добавляем '?? ""' для обработки возможного null
    return switch (langCode) {
      'el' => word.el,
      'en' => word.en ?? '',
      'ru' => word.ru,
      _ => word.el,
    };
  }

  Future<void> _initialize() async {
    try {
      final jsonString = await rootBundle.loadString('assets/sample_data/objects.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _allWords = jsonList.map((json) => Word.fromJson(json)).toList();
      _allWords.shuffle(_random);
      generateQuestion();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void generateQuestion() {
    if (_allWords.isEmpty) {
      state = AsyncValue.error("Слова не загружены", StackTrace.current);
      return;
    }

    final settings = ref.read(settingsProvider);
    final studyLang = settings.studiedLanguage;
    final answerLang = settings.answerLanguage;

    final correctWord = _allWords[_currentIndex];

    final wrongWords = List<Word>.from(_allWords)..removeAt(_currentIndex);
    wrongWords.shuffle(_random);

    final correctAnswerText = _getWordField(correctWord, answerLang);
    final options = [correctAnswerText];

    options.addAll(
        wrongWords.take(3).map((w) => _getWordField(w, answerLang))
    );
    options.shuffle(_random);

    state = AsyncValue.data(
        QuizQuestion(
          correctWord: correctWord,
          options: options,
          questionText: _getWordField(correctWord, studyLang),
          answerText: correctAnswerText,
        )
    );
  }

  void nextWord() {
    if (_allWords.isNotEmpty) {
      _currentIndex = (_currentIndex + 1) % _allWords.length;
    }
    generateQuestion();
  }
}

final dictionaryProvider = NotifierProvider<DictionaryNotifier, AsyncValue<QuizQuestion>>(() {
  return DictionaryNotifier();
});
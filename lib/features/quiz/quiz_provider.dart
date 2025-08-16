// lib/features/quiz/quiz_provider.dart
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/data/services/dictionary_service.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/features/settings/app_settings.dart';

class QuizState {
  final AsyncValue<Word> currentWord;
  final List<String> options; // варианты на языке ответа
  final String? selectedAnswer;
  final bool showFeedback;

  const QuizState({
    required this.currentWord,
    required this.options,
    required this.selectedAnswer,
    required this.showFeedback,
  });

  factory QuizState.initial() => const QuizState(
    currentWord: AsyncValue.loading(),
    options: <String>[],
    selectedAnswer: null,
    showFeedback: false,
  );

  QuizState copyWith({
    AsyncValue<Word>? currentWord,
    List<String>? options,
    String? selectedAnswer,
    bool? showFeedback,
  }) {
    return QuizState(
      currentWord: currentWord ?? this.currentWord,
      options: options ?? this.options,
      selectedAnswer: selectedAnswer,
      showFeedback: showFeedback ?? this.showFeedback,
    );
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier(this.ref) : super(QuizState.initial()) {
    _generateNewQuestionInternal();
  }

  final Ref ref;
  final Random _rand = Random();

  DictionaryService get _dict => ref.read(dictionaryServiceProvider);
  AppSettings get _settings => ref.read(settingsProvider);

  Future<void> refresh() async => _generateNewQuestionInternal();
  Future<void> generateNewQuestion() async => _generateNewQuestionInternal();

  void selectAnswer(String option) {
    if (state.showFeedback) return;
    state = state.copyWith(selectedAnswer: option);
  }

  void checkAnswer() {
    if (state.showFeedback) return;
    state = state.copyWith(showFeedback: true);
  }

  String _text(Word w, String lang) {
    switch (lang) {
      case 'el':
        return w.el;
      case 'ru':
        return w.ru;
      case 'en':
        return w.en ?? '';
      default:
        return w.el;
    }
  }

  Future<void> _generateNewQuestionInternal() async {
    if (_dict.activeWords.isEmpty) {
      debugPrint('[Quiz] activeWords пуст — нет выбранных словарей/слов.');
      state = state.copyWith(
        currentWord: AsyncValue.error('no_words', StackTrace.current),
        options: const [],
        selectedAnswer: null,
        showFeedback: false,
      );
      return;
    }

    final word = _dict.getRandomWord();
    if (word == null) {
      debugPrint('[Quiz] getRandomWord() вернул null.');
      state = state.copyWith(
        currentWord: AsyncValue.error('no_words', StackTrace.current),
        options: const [],
        selectedAnswer: null,
        showFeedback: false,
      );
      return;
    }

    final answerLang = _settings.answerLanguage;
    final correct = _text(word, answerLang).trim();

    // ЛОГИРУЕМ флаг "All words"
    final useAll = _settings.useAllWordsInQuiz;
    debugPrint('[Quiz] useAllWordsInQuiz=$useAll | answerLang=$answerLang | '
        'currentWord.id=${word.id} dict=${word.dictionaryId} el="${word.el}" ru="${word.ru}" en="${word.en ?? ''}"');

    // Расширенный пул, чтобы после дедупликации хватило трёх уникальных
    final pool = _dict.getQuizOptions(
      excludeWord: word,
      useAllWords: useAll,
      count: 40,
    );

    // ЛОГИРУЕМ состав пула (обрежем до 20 строк, чтобы не шуметь)
    final logPreviewCount = pool.length > 20 ? 20 : pool.length;
    debugPrint('[Quiz] Получен пул кандидатов: total=${pool.length}, preview=$logPreviewCount');
    for (int i = 0; i < logPreviewCount; i++) {
      final w = pool[i];
      final t = _text(w, answerLang).trim();
      debugPrint('  [pool#$i] id=${w.id} dict=${w.dictionaryId} -> "$t" (el="${w.el}")');
    }

    // Дедупликация по тексту на языке ответа
    final seen = <String>{correct};
    final wrong = <String>[];
    for (final w in pool) {
      final t = _text(w, answerLang).trim();
      if (t.isEmpty) continue;
      if (seen.add(t)) {
        wrong.add(t);
        if (wrong.length == 3) break;
      }
    }

    if (wrong.length < 3) {
      debugPrint('[Quiz] Уникальных неправильных вариантов оказалось ${wrong.length} < 3. Дозаполняем случайно.');
    }

    // На случай, если уникальных не хватило
    while (wrong.length < 3 && pool.isNotEmpty) {
      final w = pool[_rand.nextInt(pool.length)];
      final t = _text(w, answerLang).trim();
      if (t.isNotEmpty && t != correct && seen.add(t)) {
        wrong.add(t);
      }
    }

    final options = <String>[...wrong.take(3), correct]..shuffle(_rand);

    // ЛОГИРУЕМ финальный набор вариантов
    debugPrint('[Quiz] Итоговые варианты (${options.length}):');
    for (var i = 0; i < options.length; i++) {
      final mark = options[i] == correct ? ' (✓ correct)' : '';
      debugPrint('  [opt#$i] "${options[i]}"$mark');
    }

    state = state.copyWith(
      currentWord: AsyncValue.data(word),
      options: options,
      selectedAnswer: null,
      showFeedback: false,
    );
  }
}

// Провайдер
final quizProvider =
StateNotifierProvider<QuizNotifier, QuizState>((ref) => QuizNotifier(ref));

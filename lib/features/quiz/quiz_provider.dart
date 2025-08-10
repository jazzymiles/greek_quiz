import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/data/services/dictionary_service.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';

@immutable
class QuizState {
  final AsyncValue<Word> currentWord;
  final List<String> options;
  final String? selectedAnswer;
  final bool showFeedback;

  const QuizState({
    this.currentWord = const AsyncValue.loading(),
    this.options = const [],
    this.selectedAnswer,
    this.showFeedback = false,
  });

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
  final Ref _ref;

  QuizNotifier(this._ref) : super(const QuizState()) {
    refresh();
  }

  String _getWordField(Word word, String langCode) {
    return switch (langCode) {
      'el' => word.el,
      'en' => word.en ?? '',
      'ru' => word.ru,
      _ => word.el,
    };
  }

  void refresh() {
    state = const QuizState(currentWord: AsyncValue.loading());
    _ref.read(dictionaryServiceProvider).filterActiveWords();
    generateNewQuestion();
  }

  void generateNewQuestion() {
    final dictionaryService = _ref.read(dictionaryServiceProvider);
    final settings = _ref.read(settingsProvider);
    final word = dictionaryService.getRandomWord();

    if (word == null) {
      state = state.copyWith(
          currentWord: AsyncValue.error(
              "Выберите и скачайте словари", StackTrace.current));
      return;
    }

    final wrongOptions = dictionaryService.getQuizOptions(
      excludeWord: word,
      useAllWords: settings.useAllWordsInQuiz,
    );

    final correctAnswerText = _getWordField(word, settings.answerLanguage);
    final options =
    wrongOptions.map((w) => _getWordField(w, settings.answerLanguage)).toList();
    options.add(correctAnswerText);
    options.shuffle();

    state = QuizState(currentWord: AsyncValue.data(word), options: options);
  }

  void selectAnswer(String answer) {
    if (state.showFeedback) return;
    state = state.copyWith(selectedAnswer: answer, showFeedback: false);
  }

  void checkAnswer() {
    if (state.selectedAnswer == null) return;
    state = state.copyWith(showFeedback: true);
  }
}

final quizProvider =
StateNotifierProvider.autoDispose<QuizNotifier, QuizState>((ref) {
  return QuizNotifier(ref);
});
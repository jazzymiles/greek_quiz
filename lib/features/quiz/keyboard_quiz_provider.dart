import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/data/services/dictionary_service.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';

enum KeyboardQuizStatus { asking, checked }

@immutable
class KeyboardQuizState {
  final Word? currentWord;
  final KeyboardQuizStatus status;
  final String userAnswer;
  final bool isCorrect;

  const KeyboardQuizState({
    this.currentWord,
    this.status = KeyboardQuizStatus.asking,
    this.userAnswer = "",
    this.isCorrect = false,
  });

  KeyboardQuizState copyWith({Word? currentWord, KeyboardQuizStatus? status, String? userAnswer, bool? isCorrect}) {
    return KeyboardQuizState(
      currentWord: currentWord ?? this.currentWord,
      status: status ?? this.status,
      userAnswer: userAnswer ?? this.userAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}

class KeyboardQuizNotifier extends StateNotifier<KeyboardQuizState> {
  final Ref _ref;
  late final TextEditingController textController;

  KeyboardQuizNotifier(this._ref) : super(const KeyboardQuizState()) {
    textController = TextEditingController();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  String _getWordField(Word word, String langCode) {
    return switch (langCode) { 'el' => word.el, 'en' => word.en ?? '', 'ru' => word.ru, _ => word.el };
  }

  void refresh() {
    _ref.read(dictionaryServiceProvider).filterActiveWords();
    generateNewQuestion();
  }

  void generateNewQuestion() {
    final dictionaryService = _ref.read(dictionaryServiceProvider);
    final word = dictionaryService.getRandomWord();
    textController.clear();
    state = KeyboardQuizState(currentWord: word);
  }

  void checkAnswer() {
    if (state.currentWord == null) return;
    final settings = _ref.read(settingsProvider);
    final correctAnswer = _getWordField(state.currentWord!, settings.answerLanguage);
    final isCorrect = textController.text.trim().toLowerCase() == correctAnswer.toLowerCase();

    state = state.copyWith(
      status: KeyboardQuizStatus.checked,
      userAnswer: textController.text.trim(),
      isCorrect: isCorrect,
    );
  }

  void showAnswer() {
    if (state.currentWord == null) return;
    final settings = _ref.read(settingsProvider);
    final correctAnswer = _getWordField(state.currentWord!, settings.answerLanguage);
    textController.text = correctAnswer;
    state = state.copyWith(userAnswer: correctAnswer);
  }
}

final keyboardQuizProvider = StateNotifierProvider.autoDispose<KeyboardQuizNotifier, KeyboardQuizState>((ref) {
  final notifier = KeyboardQuizNotifier(ref);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});
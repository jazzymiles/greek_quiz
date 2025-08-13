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
    this.userAnswer = '',
    this.isCorrect = false,
  });

  KeyboardQuizState copyWith({
    Word? currentWord,
    KeyboardQuizStatus? status,
    String? userAnswer,
    bool? isCorrect,
    bool clearWord = false,
  }) {
    return KeyboardQuizState(
      currentWord: clearWord ? null : (currentWord ?? this.currentWord),
      status: status ?? this.status,
      userAnswer: userAnswer ?? this.userAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}

class KeyboardQuizNotifier extends StateNotifier<KeyboardQuizState> {
  KeyboardQuizNotifier(this._ref) : super(const KeyboardQuizState()) {
    textController.addListener(() {
      final text = textController.text;
      if (text != state.userAnswer) {
        state = state.copyWith(userAnswer: text);
      }
    });
    refresh();
  }

  final Ref _ref;
  final TextEditingController textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  void refresh() {
    _ref.read(dictionaryServiceProvider).filterActiveWords();
    generateNewQuestion();
  }

  String _getWordField(Word word, String langCode) {
    switch (langCode) {
      case 'el':
        return word.el;
      case 'en':
        return word.en ?? '';
      case 'ru':
        return word.ru;
      default:
        return word.el;
    }
  }

  // ------ Нормализация / варианты ответа ------

  String _normalize(String s) {
    const accents = {
      'ά': 'α', 'έ': 'ε', 'ή': 'η', 'ί': 'ι', 'ό': 'ο', 'ύ': 'υ', 'ώ': 'ω',
      'ϊ': 'ι', 'ΐ': 'ι', 'ϋ': 'υ', 'ΰ': 'υ', 'ς': 'σ',
      'Ά': 'α', 'Έ': 'ε', 'Ή': 'η', 'Ί': 'ι', 'Ό': 'ο', 'Ύ': 'υ', 'Ώ': 'ω',
      'Ϊ': 'ι', 'Ϋ': 'υ',
    };
    final buf = StringBuffer();
    for (final ch in s.toLowerCase().trim().runes) {
      final c = String.fromCharCode(ch);
      buf.write(accents[c] ?? c);
    }
    return buf.toString()
        .replaceAll(RegExp(r'[^\p{Letter}\p{Number}\s]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _splitVariants(String s) {
    return s
        .split(RegExp(r'(,|;|/|\\| or | либо | или )', caseSensitive: false))
        .map((e) => _normalize(e))
        .where((e) => e.isNotEmpty)
        .toList();
  }

  bool _isAnswerCorrect({
    required String userInput,
    required Word word,
    required String answerLang,
  }) {
    final u = _normalize(userInput);
    if (u.isEmpty) return false;

    late final List<String> variants;
    switch (answerLang) {
      case 'el':
        variants = [_normalize(word.el)];
        break;
      case 'ru':
        variants = _splitVariants(word.ru);
        break;
      case 'en':
        variants = _splitVariants(word.en ?? '');
        break;
      default:
        variants = [_normalize(word.el)];
    }

    // строгое сравнение без «почти правильно»
    return variants.any((v) => v == u);
  }

  // ------ Логика квиза ------

  void generateNewQuestion() {
    final dictionaryService = _ref.read(dictionaryServiceProvider);
    final word = dictionaryService.getRandomWord();
    textController.text = '';
    if (word == null) {
      state = state.copyWith(
        clearWord: true,
        status: KeyboardQuizStatus.asking,
        userAnswer: '',
        isCorrect: false,
      );
      return;
    }
    state = KeyboardQuizState(
      currentWord: word,
      status: KeyboardQuizStatus.asking,
      userAnswer: '',
      isCorrect: false,
    );
  }

  void checkAnswer() {
    final w = state.currentWord;
    if (w == null) return;

    final settings = _ref.read(settingsProvider);
    final ok = _isAnswerCorrect(
      userInput: state.userAnswer,
      word: w,
      answerLang: settings.answerLanguage,
    );

    state = state.copyWith(status: KeyboardQuizStatus.checked, isCorrect: ok);
  }

  void showAnswer() {
    final w = state.currentWord;
    if (w == null) return;
    final settings = _ref.read(settingsProvider);
    final answer = _getWordField(w, settings.answerLanguage);
    textController.text = answer;
    state = state.copyWith(userAnswer: answer);
  }
}

final keyboardQuizProvider =
StateNotifierProvider.autoDispose<KeyboardQuizNotifier, KeyboardQuizState>((ref) {
  final notifier = KeyboardQuizNotifier(ref);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

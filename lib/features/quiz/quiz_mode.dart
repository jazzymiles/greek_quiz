import 'package:flutter_riverpod/flutter_riverpod.dart';

enum QuizMode { quiz, cards, keyboard, talkShow }

// Глобальный провайдер выбранного режима
final quizModeProvider = StateProvider<QuizMode>((ref) => QuizMode.quiz);

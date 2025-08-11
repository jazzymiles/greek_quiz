import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/data/services/dictionary_service.dart';

@immutable
class CardModeState {
  final List<Word> activeWords;
  final int currentIndex;
  final bool showTranslation;

  const CardModeState({
    this.activeWords = const [],
    this.currentIndex = 0,
    this.showTranslation = false,
  });

  CardModeState copyWith({
    List<Word>? activeWords,
    int? currentIndex,
    bool? showTranslation,
  }) {
    return CardModeState(
      activeWords: activeWords ?? this.activeWords,
      currentIndex: currentIndex ?? this.currentIndex,
      showTranslation: showTranslation ?? this.showTranslation,
    );
  }
}

class CardModeNotifier extends StateNotifier<CardModeState> {
  final Ref _ref;

  CardModeNotifier(this._ref) : super(const CardModeState());

  void refresh() {
    final dictionaryService = _ref.read(dictionaryServiceProvider);
    dictionaryService.filterActiveWords();
    state = state.copyWith(
      activeWords: dictionaryService.activeWords,
      currentIndex: 0,
      showTranslation: false,
    );
  }

  void nextWord() {
    if (state.activeWords.isEmpty) return;
    final nextIndex = (state.currentIndex + 1) % state.activeWords.length;
    state = state.copyWith(currentIndex: nextIndex, showTranslation: false);
  }

  void previousWord() {
    if (state.activeWords.isEmpty) return;
    final prevIndex = (state.currentIndex - 1 + state.activeWords.length) % state.activeWords.length;
    state = state.copyWith(currentIndex: prevIndex, showTranslation: false);
  }

  void flipCard() {
    state = state.copyWith(showTranslation: !state.showTranslation);
  }
}

final cardModeProvider = StateNotifierProvider.autoDispose<CardModeNotifier, CardModeState>((ref) {
  final notifier = CardModeNotifier(ref);
  // При создании сразу просим обновиться
  notifier.refresh();
  return notifier;
});
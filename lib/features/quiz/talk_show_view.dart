import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';

import 'package:greek_quiz/core/audio/talkshow_audio_handler.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/features/quiz/card_mode_provider.dart';
import 'package:greek_quiz/features/quiz/quiz_mode.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/l10n/app_localizations.dart';
import 'package:greek_quiz/shared/services/tts_service.dart';

class TalkShowView extends ConsumerStatefulWidget {
  const TalkShowView({super.key});

  @override
  ConsumerState<TalkShowView> createState() => _TalkShowViewState();
}

class _TalkShowViewState extends ConsumerState<TalkShowView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Подогреваем аудио-хендлер заранее
    // ignore: discarded_futures
    ref.read(talkShowAudioHandlerProvider.future);

    if (ref.read(quizModeProvider) != QuizMode.talkShow) {
      _stopHandlerIfReady();
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    if (ref.read(quizModeProvider) != QuizMode.talkShow) {
      _stopHandlerIfReady();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopHandlerIfReady();
    super.dispose();
  }

  Future<void> _stopHandlerIfReady() async {
    final async = ref.read(talkShowAudioHandlerProvider);
    if (async.hasValue) {
      await async.requireValue.stop();
    }
    await ref.read(ttsServiceProvider).stop();
  }

  String _textWithArticle(Word w, String langCode, {required bool includeArticle}) {
    String base = switch (langCode) {
      'el' => w.el,
      'ru' => w.ru,
      'en' => w.en ?? '',
      _ => w.el,
    };

    if (includeArticle && langCode == 'el') {
      final g = (w.gender ?? '').toLowerCase();
      String article = '';
      if (g == 'm' || g == 'м') {
        article = 'ο';
      } else if (g == 'f' || g == 'ж') {
        article = 'η';
      } else if (g == 'n' || g == 'ср') {
        article = 'το';
      }
      if (article.isNotEmpty) {
        base = '$article $base';
      }
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    // Если режим сменили — останавливаем фон
    ref.listen<QuizMode>(quizModeProvider, (prev, next) {
      if (next != QuizMode.talkShow) {
        _stopHandlerIfReady();
      }
    });

    final l10n = AppLocalizations.of(context)!;
    final cardState = ref.watch(cardModeProvider);
    final notifier = ref.read(cardModeProvider.notifier);
    final settings = ref.watch(settingsProvider);

    if (cardState.activeWords.isEmpty) {
      return Center(child: Text(l10n.error_no_dictionaries_selected));
    }

    final currentWord = cardState.activeWords[cardState.currentIndex];
    final qText = _textWithArticle(
      currentWord,
      settings.studiedLanguage,
      includeArticle: settings.showArticle,
    );
    final aText = _textWithArticle(
      currentWord,
      settings.answerLanguage,
      includeArticle: false,
    );
    final studyExample =
    currentWord.getUsageExampleForLanguage(settings.studiedLanguage);
    final answerExample =
    currentWord.getUsageExampleForLanguage(settings.answerLanguage);
    final textTheme = Theme.of(context).textTheme;

    final handlerAsync = ref.watch(talkShowAudioHandlerProvider);
    final handler = handlerAsync.value; // может быть null до инициализации

    return Column(
      children: [
        Expanded(
          child: Container(
            key: ValueKey(currentWord.id),
            margin: const EdgeInsets.all(16),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            qText,
                            style: textTheme.displaySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.volume_up,
                              color: Theme.of(context).colorScheme.primary),
                          onPressed: () async {
                            final tts = ref.read(ttsServiceProvider);
                            await tts.stop();
                            await tts.speak(qText, settings.studiedLanguage);
                          },
                        )
                      ],
                    ),
                    if ((currentWord.transcription).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '[${currentWord.transcription}]',
                          style: textTheme.titleLarge
                              ?.copyWith(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      aText,
                      style: textTheme.headlineMedium
                          ?.copyWith(color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                    if (studyExample != null && studyExample.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Column(
                          children: [
                            Text(
                              studyExample,
                              style: textTheme.bodyLarge?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade700),
                              textAlign: TextAlign.center,
                            ),
                            if (answerExample != null &&
                                answerExample.isNotEmpty &&
                                answerExample != studyExample)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  answerExample,
                                  style: textTheme.bodyLarge?.copyWith(
                                      color: Colors.grey.shade600),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ----- Панель управления воспроизведением -----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: StreamBuilder<PlaybackState>(
            stream: handler?.playbackState,
            builder: (context, snap) {
              final isPlaying = snap.data?.playing ?? false;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: 40,
                    onPressed: () async {
                      await ref.read(ttsServiceProvider).stop();
                      // Ждём и берём ненулевой хендлер
                      final AudioHandler h =
                          handler ?? await ref.read(talkShowAudioHandlerProvider.future);
                      await h.skipToPrevious();
                      // local UI index переключается провайдером
                    },
                  ),
                  IconButton(
                    icon: Icon(isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled),
                    iconSize: 60,
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () async {
                      final AudioHandler h =
                          handler ?? await ref.read(talkShowAudioHandlerProvider.future);
                      if (isPlaying) {
                        await h.pause();
                      } else {
                        await h.play();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 40,
                    onPressed: () async {
                      await ref.read(ttsServiceProvider).stop();
                      final AudioHandler h =
                          handler ?? await ref.read(talkShowAudioHandlerProvider.future);
                      await h.skipToNext();
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

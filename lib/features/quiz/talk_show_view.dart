import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _isPlaying = false;
  bool _isDisposed = false;
  bool _cycleRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Если виджет создан, но режим уже не talkShow — сразу глушим всё.
    if (ref.read(quizModeProvider) != QuizMode.talkShow) {
      _forceStopAll();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _forceStopAll();
    }
  }

  @override
  void deactivate() {
    // В IndexedStack виджет может стать невидимым, но не уничтоженным — выключаемся.
    _forceStopAll();
    super.deactivate();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  Future<void> _forceStopAll() async {
    _isPlaying = false;
    await ref.read(ttsServiceProvider).stop();
    if (mounted) setState(() {});
  }

  Future<void> _startPlayback() async {
    if (_isPlaying) return;
    if (ref.read(quizModeProvider) != QuizMode.talkShow) return;

    setState(() => _isPlaying = true);
    if (!_cycleRunning) {
      unawaited(_runPlaybackCycle());
    }
  }

  Future<void> _pausePlayback() async {
    if (!_isPlaying) return;
    setState(() => _isPlaying = false);
    await ref.read(ttsServiceProvider).stop();
  }

  Future<void> _runPlaybackCycle() async {
    if (_cycleRunning) return;
    _cycleRunning = true;

    try {
      while (_isPlaying && !_isDisposed) {
        if (ref.read(quizModeProvider) != QuizMode.talkShow) {
          await _forceStopAll();
          break;
        }

        final cardState = ref.read(cardModeProvider);
        if (cardState.activeWords.isEmpty) {
          await _pausePlayback();
          break;
        }

        final settings = ref.read(settingsProvider);
        final ttsService = ref.read(ttsServiceProvider);
        final notifier = ref.read(cardModeProvider.notifier);
        final currentWord = cardState.activeWords[cardState.currentIndex];

        final questionText = _getWordField(currentWord, settings.studiedLanguage);
        await ttsService.speak(questionText, settings.studiedLanguage);
        if (!_isPlaying || _isDisposed) break;

        await Future.delayed(const Duration(seconds: 2));
        if (!_isPlaying || _isDisposed) break;

        final answerText = _getWordField(currentWord, settings.answerLanguage);
        await ttsService.speak(answerText, settings.answerLanguage);
        if (!_isPlaying || _isDisposed) break;

        await Future.delayed(const Duration(seconds: 2));
        if (!_isPlaying || _isDisposed) break;

        if (ref.read(quizModeProvider) != QuizMode.talkShow) {
          await _forceStopAll();
          break;
        }
        notifier.nextWord();
      }
    } finally {
      _cycleRunning = false;
    }
  }

  Future<void> _skip(VoidCallback moveAction) async {
    await ref.read(ttsServiceProvider).stop();
    if (ref.read(quizModeProvider) != QuizMode.talkShow) return;

    moveAction();
    if (_isPlaying && !_cycleRunning) {
      unawaited(_runPlaybackCycle());
    }
  }

  String _getWordField(Word word, String langCode) {
    switch (langCode) {
      case 'el':
        return word.el ?? '';
      case 'en':
        return word.en ?? '';
      case 'ru':
        return word.ru ?? '';
      default:
        return word.el ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Слушаем смену режима — нельзя делать это в initState для вашей версии Riverpod
    ref.listen<QuizMode>(
      quizModeProvider,
          (prev, mode) {
        if (mode != QuizMode.talkShow) {
          // чтобы не ловить "setState during build", выполняем в микро-задаче
          Future.microtask(_forceStopAll);
        }
      },
    );

    final l10n = AppLocalizations.of(context)!;
    final cardState = ref.watch(cardModeProvider);
    final notifier = ref.read(cardModeProvider.notifier);
    final settings = ref.watch(settingsProvider);

    if (cardState.activeWords.isEmpty) {
      return Center(child: Text(l10n.error_no_dictionaries_selected));
    }

    final currentWord = cardState.activeWords[cardState.currentIndex];
    final questionText = _getWordField(currentWord, settings.studiedLanguage);
    final answerText = _getWordField(currentWord, settings.answerLanguage);
    final studyExample = currentWord.getUsageExampleForLanguage(settings.studiedLanguage);
    final answerExample = currentWord.getUsageExampleForLanguage(settings.answerLanguage);
    final textTheme = Theme.of(context).textTheme;

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
                            questionText,
                            style: textTheme.displaySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.volume_up, color: Theme.of(context).colorScheme.primary),
                          onPressed: () {
                            ref.read(ttsServiceProvider).speak(questionText, settings.studiedLanguage);
                          },
                        )
                      ],
                    ),
                    if ((currentWord.transcription ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '[${currentWord.transcription}]',
                          style: textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      answerText,
                      style: textTheme.headlineMedium?.copyWith(color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                    if (studyExample != null && studyExample.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Column(
                          children: [
                            Text(
                              studyExample,
                              style: textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                              textAlign: TextAlign.center,
                            ),
                            if (answerExample != null && answerExample.isNotEmpty && answerExample != studyExample)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  answerExample,
                                  style: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                iconSize: 40,
                onPressed: () => _skip(notifier.previousWord),
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                iconSize: 60,
                color: Theme.of(context).colorScheme.primary,
                onPressed: _isPlaying ? _pausePlayback : _startPlayback,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                iconSize: 40,
                onPressed: () => _skip(notifier.nextWord),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

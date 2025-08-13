import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/features/quiz/card_mode_provider.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/shared/services/tts_service.dart';

/// Riverpod-провайдер AudioHandler (инициализация единожды)
final talkShowAudioHandlerProvider = FutureProvider<AudioHandler>((ref) async {
  final handler = await AudioService.init(
    builder: () => TalkShowAudioHandler(ref),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'talkshow_playback',
      androidNotificationChannelName: 'Talk Show',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  return handler;
});

class TalkShowAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final Ref ref;
  bool _isDisposed = false;
  bool _loopRunning = false;
  Timer? _betweenPartsDelay;

  TalkShowAudioHandler(this.ref) {
    playbackState.add(playbackState.value.copyWith(
      controls: const [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
  }

  Future<AudioSession> _session() => AudioSession.instance;

  Future<void> _activateSessionForBackground() async {
    final s = await _session();
    // Для TTS можно использовать speech/music; оставим music из-за локскрина,
    // но TtsService сам активирует сессию перед speak.
    await s.configure(const AudioSessionConfiguration.music());
    await s.setActive(true);
  }

  Future<void> _deactivateSession() async {
    final s = await _session();
    await s.setActive(false);
  }

  @override
  Future<void> play() async {
    if (_loopRunning) return;
    await _activateSessionForBackground();

    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.ready,
      playing: true,
      controls: const [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
    ));

    _loopRunning = true;
    unawaited(_loop());
  }

  @override
  Future<void> pause() async {
    await ref.read(ttsServiceProvider).stop();
    _betweenPartsDelay?.cancel();

    playbackState.add(playbackState.value.copyWith(
      playing: false,
      controls: const [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
    ));
    _loopRunning = false;
  }

  @override
  Future<void> stop() async {
    _isDisposed = true;
    _loopRunning = false;
    _betweenPartsDelay?.cancel();
    await ref.read(ttsServiceProvider).stop();

    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
      controls: const [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
    ));
    await _deactivateSession();
  }

  @override
  Future<void> skipToNext() async {
    _betweenPartsDelay?.cancel();
    await ref.read(ttsServiceProvider).stop();
    ref.read(cardModeProvider.notifier).nextWord();
    if (playbackState.value.playing && !_loopRunning) {
      _loopRunning = true;
      unawaited(_loop());
    }
  }

  @override
  Future<void> skipToPrevious() async {
    _betweenPartsDelay?.cancel();
    await ref.read(ttsServiceProvider).stop();
    ref.read(cardModeProvider.notifier).previousWord();
    if (playbackState.value.playing && !_loopRunning) {
      _loopRunning = true;
      unawaited(_loop());
    }
  }

  Future<void> _loop() async {
    if (!_loopRunning || _isDisposed) return;

    try {
      while (_loopRunning && !_isDisposed) {
        final state = ref.read(cardModeProvider);
        if (state.activeWords.isEmpty) {
          await pause();
          break;
        }

        final settings = ref.read(settingsProvider);
        final tts = ref.read(ttsServiceProvider);
        final current = state.activeWords[state.currentIndex];

        mediaItem.add(
          MediaItem(
            id: current.id,
            title: _qText(current, settings, includeArticle: settings.showArticle),
            artist: _aText(current, settings),
            album: 'Talk Show',
          ),
        );

        // Вопрос (например, греческий)
        await tts.speak(
          _qText(current, settings, includeArticle: settings.showArticle),
          settings.studiedLanguage,
        );
        if (!_loopRunning || _isDisposed) break;

        // Пауза между вопросом и ответом
        await _delay(const Duration(seconds: 2));
        if (!_loopRunning || _isDisposed) break;

        // Ответ (например, русский/английский)
        await tts.speak(
          _aText(current, settings),
          settings.answerLanguage,
        );
        if (!_loopRunning || _isDisposed) break;

        // Пауза перед следующим словом
        await _delay(const Duration(seconds: 2));
        if (!_loopRunning || _isDisposed) break;

        // Следующее слово
        ref.read(cardModeProvider.notifier).nextWord();
      }
    } finally {
      _loopRunning = false;
    }
  }

  Future<void> _delay(Duration d) async {
    _betweenPartsDelay?.cancel();
    final c = Completer<void>();
    _betweenPartsDelay = Timer(d, () => c.complete());
    await c.future;
  }

  String _qText(Word w, dynamic settings, {required bool includeArticle}) {
    String base = switch (settings.studiedLanguage) {
      'el' => w.el,
      'ru' => w.ru,
      'en' => w.en ?? '',
      _ => w.el,
    };
    if (includeArticle && settings.studiedLanguage == 'el') {
      final g = (w.gender ?? '').toLowerCase();
      String art = '';
      if (g == 'm' || g == 'м') {
        art = 'ο';
      } else if (g == 'f' || g == 'ж') {
        art = 'η';
      } else if (g == 'n' || g == 'ср') {
        art = 'το';
      }
      if (art.isNotEmpty) base = '$art $base';
    }
    return base;
  }

  String _aText(Word w, dynamic settings) {
    return switch (settings.answerLanguage) {
      'el' => w.el,
      'ru' => w.ru,
      'en' => w.en ?? '',
      _ => w.el,
    };
  }
}

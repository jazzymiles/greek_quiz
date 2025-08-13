import 'dart:async';
import 'dart:io' show Platform;

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  Completer<void>? _speechCompleter;
  String? _currentLang; // кэшируем последний установленный язык

  TtsService() {
    _initTts();
  }

  void _initTts() {
    // Ждём завершение проговаривания через колбэк
    _tts.setCompletionHandler(() {
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
        _speechCompleter!.complete();
      }
    });

    _tts.setErrorHandler((msg) {
      // ignore: avoid_print
      print("🔥 TTS error: $msg");
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
        _speechCompleter!.complete();
      }
    });

    // Включаем ожидание завершения на уровне плагина (особенно важно на Android)
    // ignore: discarded_futures
    _tts.awaitSpeakCompletion(true);
  }

  Future<void> speak(String text, String langCode) async {
    if (text.trim().isEmpty) return;

    final session = await AudioSession.instance;
    await session.setActive(true);

    // На некоторых Android после lock/unlock setLanguage игнорируется,
    // если не прервать текущий проигрыш. Сначала стоп.
    try {
      await _tts.stop();
    } catch (_) {}

    _speechCompleter = Completer<void>();

    final ttsLangCode = switch (langCode) {
      'el' => 'el-GR',
      'ru' => 'ru-RU',
      'en' => 'en-US',
      _ => 'el-GR',
    };

    try {
      if (_currentLang != ttsLangCode) {
        await _tts.setLanguage(ttsLangCode);
        _currentLang = ttsLangCode;

        // На Android даём движку переключить голос
        if (Platform.isAndroid) {
          await Future.delayed(const Duration(milliseconds: 60));
        }
      }

      // убеждаемся, что ждём завершение
      await _tts.awaitSpeakCompletion(true);

      await _tts.speak(text);

      // страховка от «вечного ожидания», если completion не прилетел
      return _speechCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          if (!_speechCompleter!.isCompleted) {
            _speechCompleter!.complete();
          }
        },
      );
    } catch (e) {
      // ignore: avoid_print
      print("🔥 TTS speak exception: $e");
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
        _speechCompleter!.complete();
      }
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } finally {
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
        _speechCompleter!.complete();
      }
    }
  }

  // опционально: скорость/тон можно дёргать из настроек, когда добавишь UI
  Future<void> setRate(double rate) => _tts.setSpeechRate(rate);
  Future<void> setPitch(double pitch) => _tts.setPitch(pitch);
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

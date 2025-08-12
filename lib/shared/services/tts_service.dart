import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audio_session/audio_session.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  TtsService() {
    _initTts();
  }

  void _initTts() {
    // Гарантируем, что speak() будет дожидаться окончания речи
    // и не вернёт Future раньше времени.
    _tts.awaitSpeakCompletion(true);
  }

  Future<void> speak(String text, String langCode) async {
    if (text.isEmpty) return;

    final session = await AudioSession.instance;
    await session.setActive(true);

    // Перед новой фразой аккуратно прерываем предыдущую,
    // чтобы не было наложений и «залипаний».
    try {
      await _tts.stop();
      // ignore: empty_catches
    } catch (_) {}

    final ttsLangCode = switch (langCode) {
      'el' => 'el-GR',
      'ru' => 'ru-RU',
      'en' => 'en-US',
      _ => 'el-GR',
    };

    await _tts.setLanguage(ttsLangCode);

    try {
      await _tts.speak(text); // вернётся, когда закончит, благодаря awaitSpeakCompletion(true)
    } catch (e) {
      // Логируем, но не пробрасываем, чтобы UI не падал
      // Можно добавить Sentry/Crashlytics при необходимости
      // print("TTS speak error: $e");
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } finally {
      // По желанию можно деактивировать сессию:
      // final session = await AudioSession.instance;
      // await session.setActive(false);
    }
  }
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

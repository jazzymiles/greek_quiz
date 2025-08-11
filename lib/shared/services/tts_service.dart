import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> speak(String text, String langCode) async {
    final session = await AudioSession.instance;
    await session.setActive(true);

    if (text.isEmpty) return;

    final ttsLangCode = switch (langCode) {
      'el' => 'el-GR',
      'ru' => 'ru-RU',
      'en' => 'en-US',
      _ => 'el-GR',
    };

    try {
      await _flutterTts.setLanguage(ttsLangCode);

      // ИСПРАВЛЕНИЕ №1: Устанавливаем высоту тона (pitch)
      // Значение 1.0 — это нормальный, нейтральный тон голоса.
      await _flutterTts.setPitch(1.0);

      // ИСПРАВЛЕНИЕ №2: Слегка замедляем речь для большей ясности
      await _flutterTts.setSpeechRate(0.4);

      await _flutterTts.speak(text);
    } catch (e) {
      print("🔥 Ошибка при вызове speak: $e");
    }
  }
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});
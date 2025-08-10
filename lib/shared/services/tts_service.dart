import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    // Явно указываем движок при инициализации для надежности
    if (defaultTargetPlatform == TargetPlatform.android) {
      _flutterTts.setEngine("com.google.android.tts");
    }
  }

  Future<void> speak(String text, String langCode) async {
    if (text.isEmpty) return;

    final ttsLangCode = switch (langCode) {
      'el' => 'el-GR',
      'ru' => 'ru-RU',
      'en' => 'en-US',
      _ => 'el-GR',
    };

    try {
      await _flutterTts.setLanguage(ttsLangCode);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.speak(text);
    } catch (e) {
      print("🔥 Ошибка при вызове speak: $e");
    }
  }
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});
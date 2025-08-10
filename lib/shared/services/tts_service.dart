import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  Future<void> speak(String text, String langCode) async {
    final ttsLangCode = switch (langCode) {
      'el' => 'el-GR',
      'ru' => 'ru-RU',
      'en' => 'en-US',
      _ => 'el-GR',
    };
    await _tts.setLanguage(ttsLangCode);
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});
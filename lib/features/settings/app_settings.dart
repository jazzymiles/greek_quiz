// lib/features/settings/app_settings.dart
import 'package:flutter/foundation.dart';

// Перечисления для настроек
enum DictionarySource { local, customURL }
enum AppTheme { system, light, dark }

@immutable
class AppSettings {
  final bool showTranscription;
  final bool autoPlaySound;
  final bool playAnswerSound;
  // ИСПРАВЛЕНИЕ: Правильное имя, как в Swift
  final bool useAllWordsInQuiz;
  final bool showArticle;

  final AppTheme appTheme;
  final DictionarySource dictionarySource;
  final String customDictionaryURL;

  final String studiedLanguage;
  final String answerLanguage;
  final String interfaceLanguage;

  const AppSettings({
    this.showTranscription = true,
    this.autoPlaySound = true,
    this.playAnswerSound = true,
    this.useAllWordsInQuiz = false, // Правильное имя
    this.showArticle = false,
    this.appTheme = AppTheme.system,
    this.dictionarySource = DictionarySource.local,
    this.customDictionaryURL = '',
    this.studiedLanguage = 'el',
    this.answerLanguage = 'ru',
    this.interfaceLanguage = 'system',
  });

  AppSettings copyWith({
    bool? showTranscription,
    bool? autoPlaySound,
    bool? playAnswerSound,
    bool? useAllWordsInQuiz, // Правильное имя
    bool? showArticle,
    AppTheme? appTheme,
    DictionarySource? dictionarySource,
    String? customDictionaryURL,
    String? studiedLanguage,
    String? answerLanguage,
    String? interfaceLanguage,
  }) {
    return AppSettings(
      showTranscription: showTranscription ?? this.showTranscription,
      autoPlaySound: autoPlaySound ?? this.autoPlaySound,
      playAnswerSound: playAnswerSound ?? this.playAnswerSound,
      useAllWordsInQuiz: useAllWordsInQuiz ?? this.useAllWordsInQuiz,
      showArticle: showArticle ?? this.showArticle,
      appTheme: appTheme ?? this.appTheme,
      dictionarySource: dictionarySource ?? this.dictionarySource,
      customDictionaryURL: customDictionaryURL ?? this.customDictionaryURL,
      studiedLanguage: studiedLanguage ?? this.studiedLanguage,
      answerLanguage: answerLanguage ?? this.answerLanguage,
      interfaceLanguage: interfaceLanguage ?? this.interfaceLanguage,
    );
  }
}
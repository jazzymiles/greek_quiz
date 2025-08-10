import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/features/settings/app_settings.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  late TextEditingController urlController;

  @override
  AppSettings build() {
    const initialSettings = AppSettings();
    urlController = TextEditingController(text: initialSettings.customDictionaryURL);
    urlController.addListener(() {
      if (state.customDictionaryURL != urlController.text) {
        state = state.copyWith(customDictionaryURL: urlController.text);
      }
    });
    ref.onDispose(() => urlController.dispose());
    return initialSettings;
  }

  void updateShowTranscription(bool value) => state = state.copyWith(showTranscription: value);
  void updateShowArticle(bool value) => state = state.copyWith(showArticle: value);
  void updateAutoPlaySound(bool value) => state = state.copyWith(autoPlaySound: value);
  void updatePlayAnswerSound(bool value) => state = state.copyWith(playAnswerSound: value);
  void updateUseAllWordsInQuiz(bool value) => state = state.copyWith(useAllWordsInQuiz: value);
  void updateStudiedLanguage(String value) => state = state.copyWith(studiedLanguage: value);
  void updateAnswerLanguage(String value) => state = state.copyWith(answerLanguage: value);
  void updateInterfaceLanguage(String value) => state = state.copyWith(interfaceLanguage: value);
  void updateAppTheme(AppTheme theme) => state = state.copyWith(appTheme: theme);
  void updateDictionarySource(DictionarySource source) => state = state.copyWith(dictionarySource: source);
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:greek_quiz/features/settings/app_settings.dart';

/// Провайдер настроек приложения
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});

class SettingsNotifier extends Notifier<AppSettings> {
  // Контроллер для ввода пользовательского URL словаря
  late final TextEditingController urlController;

  // Ключи в SharedPreferences
  static const _kStudied = 'settings.studiedLanguage';
  static const _kAnswer = 'settings.answerLanguage';
  static const _kInterface = 'settings.interfaceLanguage';
  static const _kShowArticle = 'settings.showArticle';
  static const _kShowTranscription = 'settings.showTranscription';
  static const _kAutoPlay = 'settings.autoPlaySound';
  static const _kPlayAnswer = 'settings.playAnswerSound';
  static const _kUseAllWords = 'settings.useAllWordsInQuiz';
  static const _kAppTheme = 'settings.appTheme'; // int index of AppTheme
  static const _kDictSource = 'settings.dictionarySource'; // int index of DictionarySource
  static const _kCustomURL = 'settings.customDictionaryURL';

  @override
  AppSettings build() {
    // Базовое состояние по умолчанию
    const initial = AppSettings();

    // Инициализируем контроллер URL текущим значением
    urlController = TextEditingController(text: initial.customDictionaryURL);
    urlController.addListener(() {
      final text = urlController.text;
      if (state.customDictionaryURL != text) {
        state = state.copyWith(customDictionaryURL: text);
        _saveToPrefs(); // сохраняем URL при изменении
      }
    });

    // При уничтожении провайдера — чистим контроллер
    ref.onDispose(() => urlController.dispose());

    // Ленивая загрузка из SharedPreferences сразу после build()
    Future.microtask(loadFromPrefs);

    return initial;
  }

  /// Загрузка настроек из SharedPreferences
  Future<void> loadFromPrefs() async {
    final p = await SharedPreferences.getInstance();

    // читаем перечисления как индексы (с безопасной проверкой границ)
    AppTheme _readTheme() {
      final idx = p.getInt(_kAppTheme);
      if (idx == null) return state.appTheme;
      if (idx < 0 || idx >= AppTheme.values.length) return state.appTheme;
      return AppTheme.values[idx];
    }

    DictionarySource _readSource() {
      final idx = p.getInt(_kDictSource);
      if (idx == null) return state.dictionarySource;
      if (idx < 0 || idx >= DictionarySource.values.length) return state.dictionarySource;
      return DictionarySource.values[idx];
    }

    final loaded = state.copyWith(
      studiedLanguage: p.getString(_kStudied) ?? state.studiedLanguage,
      answerLanguage: p.getString(_kAnswer) ?? state.answerLanguage,
      interfaceLanguage: p.getString(_kInterface) ?? state.interfaceLanguage,
      showArticle: p.getBool(_kShowArticle) ?? state.showArticle,
      showTranscription: p.getBool(_kShowTranscription) ?? state.showTranscription,
      autoPlaySound: p.getBool(_kAutoPlay) ?? state.autoPlaySound,
      playAnswerSound: p.getBool(_kPlayAnswer) ?? state.playAnswerSound,
      useAllWordsInQuiz: p.getBool(_kUseAllWords) ?? state.useAllWordsInQuiz,
      appTheme: _readTheme(),
      dictionarySource: _readSource(),
      customDictionaryURL: p.getString(_kCustomURL) ?? state.customDictionaryURL,
    );

    state = loaded;

    // синхронизируем контроллер URL с загруженным состоянием
    if (urlController.text != state.customDictionaryURL) {
      urlController.text = state.customDictionaryURL;
    }
  }

  /// Сохранение текущего состояния в SharedPreferences
  Future<void> _saveToPrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kStudied, state.studiedLanguage);
    await p.setString(_kAnswer, state.answerLanguage);
    await p.setString(_kInterface, state.interfaceLanguage);
    await p.setBool(_kShowArticle, state.showArticle);
    await p.setBool(_kShowTranscription, state.showTranscription);
    await p.setBool(_kAutoPlay, state.autoPlaySound);
    await p.setBool(_kPlayAnswer, state.playAnswerSound);
    await p.setBool(_kUseAllWords, state.useAllWordsInQuiz);
    await p.setInt(_kAppTheme, state.appTheme.index);
    await p.setInt(_kDictSource, state.dictionarySource.index);
    await p.setString(_kCustomURL, state.customDictionaryURL);
  }

  // ==== Обновляющие методы (синхронные, чтобы подходили под onChanged/колбэки) ====

  // Языки
  void updateStudiedLanguage(String value) {
    state = state.copyWith(studiedLanguage: value);
    _saveToPrefs();
  }

  void updateAnswerLanguage(String value) {
    state = state.copyWith(answerLanguage: value);
    _saveToPrefs();
  }

  void updateInterfaceLanguage(String value) {
    state = state.copyWith(interfaceLanguage: value);
    _saveToPrefs();
  }

  // Тумблеры
  void updateShowTranscription(bool value) {
    state = state.copyWith(showTranscription: value);
    _saveToPrefs();
  }

  void updateShowArticle(bool value) {
    state = state.copyWith(showArticle: value);
    _saveToPrefs();
  }

  void updateAutoPlaySound(bool value) {
    state = state.copyWith(autoPlaySound: value);
    _saveToPrefs();
  }

  void updatePlayAnswerSound(bool value) {
    state = state.copyWith(playAnswerSound: value);
    _saveToPrefs();
  }

  void updateUseAllWordsInQuiz(bool value) {
    state = state.copyWith(useAllWordsInQuiz: value);
    _saveToPrefs();
  }

  // Перечисления
  void updateAppTheme(AppTheme theme) {
    state = state.copyWith(appTheme: theme);
    _saveToPrefs();
  }

  void updateDictionarySource(DictionarySource source) {
    state = state.copyWith(dictionarySource: source);
    _saveToPrefs();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:greek_quiz/data/services/dictionary_service.dart';
import 'package:greek_quiz/features/dictionary/dictionary_selection_view.dart';
import 'package:greek_quiz/features/quiz/card_mode_provider.dart';
import 'package:greek_quiz/features/quiz/card_view.dart';
import 'package:greek_quiz/features/quiz/keyboard_quiz_provider.dart';
import 'package:greek_quiz/features/quiz/keyboard_view.dart';
import 'package:greek_quiz/features/quiz/quiz_mode.dart';
import 'package:greek_quiz/features/quiz/quiz_provider.dart';
import 'package:greek_quiz/features/quiz/quiz_view.dart';
import 'package:greek_quiz/features/quiz/talk_show_view.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/features/settings/settings_screen.dart';
import 'package:greek_quiz/l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // prefs keys
  static const _prefsDownloadedKey = 'dicts_installed_v1';
  static const _prefsSelectedDictsKey = 'selected_dictionaries_v1';
  static const _prefsQuizModeKey = 'quiz_mode_v1';
  static const _prefsLangStudied = 'settings.studiedLanguage';
  static const _prefsLangAnswer = 'settings.answerLanguage';
  static const _prefsLangInterface = 'settings.interfaceLanguage';

  QuizMode _selectedMode = QuizMode.quiz;

  static const List<Widget> _quizViews = <Widget>[
    QuizView(),
    CardView(),
    KeyboardView(),
    TalkShowView(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final prefs = await SharedPreferences.getInstance();

      // === ВОССТАНОВЛЕНИЕ ЯЗЫКОВ (через существующие методы в SettingsNotifier) ===
      final settingsNotifier = ref.read(settingsProvider.notifier);
      final studied = prefs.getString(_prefsLangStudied);
      final answer = prefs.getString(_prefsLangAnswer);
      final iface = prefs.getString(_prefsLangInterface);
      if (studied != null) settingsNotifier.updateStudiedLanguage(studied);
      if (answer != null) settingsNotifier.updateAnswerLanguage(answer);
      if (iface != null) settingsNotifier.updateInterfaceLanguage(iface);

      // === Инициализация словарей ===
      final service = ref.read(dictionaryServiceProvider);
      await service.initialize();

      // === ВОССТАНОВЛЕНИЕ ВЫБРАННЫХ СЛОВАРЕЙ ===
      final savedSelected = prefs.getStringList(_prefsSelectedDictsKey);
      if (savedSelected != null) {
        service.selectedDictionaries
          ..clear()
          ..addAll(savedSelected);
        service.filterActiveWords();
      }

      // === ВОССТАНОВЛЕНИЕ РЕЖИМА ===
      final savedModeIndex = prefs.getInt(_prefsQuizModeKey);
      if (savedModeIndex != null &&
          savedModeIndex >= 0 &&
          savedModeIndex < QuizMode.values.length) {
        _selectedMode = QuizMode.values[savedModeIndex];
      }
      // уведомим провайдер о текущем режиме (важно для TalkShow/Keyboard)
      ref.read(quizModeProvider.notifier).state = _selectedMode;

      // === Обновим режимы квиза под восстановленные данные ===
      ref.read(quizProvider.notifier).refresh();
      ref.read(keyboardQuizProvider.notifier).refresh();
      ref.read(cardModeProvider.notifier).refresh();

      // === Однократная автоскачка словарей — только при наличии выбора ===
      final alreadyInstalled = prefs.getBool(_prefsDownloadedKey) ?? false;
      final hasSelection = service.selectedDictionaries.isNotEmpty;
      if (!alreadyInstalled && hasSelection) {
        final settings = ref.read(settingsProvider);
        await service.downloadAndSaveDictionaries(settings.interfaceLanguage);
        await prefs.setBool(_prefsDownloadedKey, true);

        // обновим провайдеры после загрузки
        ref.read(quizProvider.notifier).refresh();
        ref.read(keyboardQuizProvider.notifier).refresh();
        ref.read(cardModeProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dictionaryService = ref.watch(dictionaryServiceProvider);

    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: l10n.title_settings_navigation,
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => FractionallySizedBox(
                    heightFactor: 0.95,
                    child: const SettingsScreen(),
                  ),
                );

                // Сохраняем актуальные настройки языков при закрытии экрана
                final prefs = await SharedPreferences.getInstance();
                final s = ref.read(settingsProvider);
                await prefs.setString(_prefsLangStudied, s.studiedLanguage);
                await prefs.setString(_prefsLangAnswer, s.answerLanguage);
                await prefs.setString(_prefsLangInterface, s.interfaceLanguage);
              },
            ),
            title: null,
            actions: [
              IconButton(
                icon: const Icon(Icons.library_books_outlined),
                tooltip: l10n.select_dictionaries_title,
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => FractionallySizedBox(
                      heightFactor: 0.92,
                      child: const DictionarySelectionView(),
                    ),
                  );

                  // После закрытия — сохраняем выбор словарей
                  final prefs = await SharedPreferences.getInstance();
                  final service = ref.read(dictionaryServiceProvider);
                  await prefs.setStringList(
                    _prefsSelectedDictsKey,
                    List<String>.from(service.selectedDictionaries),
                  );

                  // и обновим провайдеры
                  ref.read(quizProvider.notifier).refresh();
                  ref.read(keyboardQuizProvider.notifier).refresh();
                  ref.read(cardModeProvider.notifier).refresh();
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SegmentedButton<QuizMode>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  segments: <ButtonSegment<QuizMode>>[
                    ButtonSegment(value: QuizMode.quiz, label: Text(l10n.quiz_mode_title)),
                    ButtonSegment(value: QuizMode.cards, label: Text(l10n.card_mode_title)),
                    ButtonSegment(value: QuizMode.keyboard, label: Text(l10n.keyboard_mode_title)),
                    ButtonSegment(value: QuizMode.talkShow, label: Text(l10n.talk_show_mode_title)),
                  ],
                  selected: {_selectedMode},
                  onSelectionChanged: (Set<QuizMode> newSelection) async {
                    setState(() {
                      _selectedMode = newSelection.first;
                    });
                    // уведомим о смене режима
                    ref.read(quizModeProvider.notifier).state = _selectedMode;

                    // и сохраним режим
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt(_prefsQuizModeKey, _selectedMode.index);
                  },
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedMode.index,
                  children: _quizViews,
                ),
              ),
            ],
          ),
        ),
        if (dictionaryService.isDownloading)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        l10n.getString(dictionaryService.statusMessage),
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      if (dictionaryService.downloadProgress > 0)
                        LinearProgressIndicator(value: dictionaryService.downloadProgress),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

extension AppLocalizationsExtension on AppLocalizations {
  String getString(String key) {
    switch (key) {
      case 'downloading_dictionaries':
        return downloading_dictionaries;
      case 'all_dictionaries_updated':
        return all_dictionaries_updated;
      case 'download_error':
        return download_error;
      default:
        return key;
    }
  }
}

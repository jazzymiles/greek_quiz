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
  static const _prefsDownloadedKey = 'dicts_installed_v1';

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

    // стартовый режим (важно для TalkShow/Keyboard)
    Future.microtask(() {
      ref.read(quizModeProvider.notifier).state = _selectedMode;
    });

    // Инициализация + однократная автозагрузка (только если есть выбранные словари)
    Future.microtask(() async {
      final service = ref.read(dictionaryServiceProvider);
      final settings = ref.read(settingsProvider);

      // 1) Инициализация локальных данных
      await service.initialize();

      // 2) Обновим режимы — подхватить локальные данные, если есть
      ref.read(quizProvider.notifier).refresh();
      ref.read(keyboardQuizProvider.notifier).refresh();
      ref.read(cardModeProvider.notifier).refresh();

      // 3) Проверим, качали ли уже когда-нибудь словари
      final prefs = await SharedPreferences.getInstance();
      final alreadyInstalled = prefs.getBool(_prefsDownloadedKey) ?? false;

      // 4) Если пользователь НЕ выбрал словари — ничего не качаем
      final hasSelection = service.selectedDictionaries.isNotEmpty;

      // 5) Автоскачивание только один раз и только при наличии выбора
      if (!alreadyInstalled && hasSelection) {
        await service.downloadAndSaveDictionaries(settings.interfaceLanguage);

        // 6) Отметим, что словари уже установлены — чтобы не качать на каждом запуске
        await prefs.setBool(_prefsDownloadedKey, true);

        // 7) После загрузки обновим режимы ещё раз
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
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (context) => FractionallySizedBox(
                  heightFactor: 0.95, // делаем экран настроек очень высоким
                  child: const SettingsScreen(),
                ),
              ),
            ),
            title: null, // без заголовка
            actions: [
              IconButton(
                icon: const Icon(Icons.library_books_outlined),
                tooltip: l10n.select_dictionaries_title,
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true, // чтобы не залезало под вырез/статусбар
                    backgroundColor: Colors.transparent,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => FractionallySizedBox(
                      heightFactor: 0.92, // ← повышаем высоту окна выбора словарей
                      child: const DictionarySelectionView(),
                    ),
                  );

                  // После изменения выбора — просто обновляем провайдеры.
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
                  onSelectionChanged: (Set<QuizMode> newSelection) {
                    setState(() {
                      _selectedMode = newSelection.first;
                    });
                    // уведомим о смене режима (важно для TalkShow/Keyboard)
                    ref.read(quizModeProvider.notifier).state = _selectedMode;
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greek_quiz/data/services/dictionary_service.dart';
import 'package:greek_quiz/features/dictionary/dictionary_selection_view.dart';
import 'package:greek_quiz/features/quiz/card_mode_provider.dart';
import 'package:greek_quiz/features/quiz/card_view.dart';
import 'package:greek_quiz/features/quiz/keyboard_quiz_provider.dart';
import 'package:greek_quiz/features/quiz/keyboard_view.dart';
import 'package:greek_quiz/features/quiz/quiz_provider.dart';
import 'package:greek_quiz/features/quiz/quiz_view.dart';
import 'package:greek_quiz/features/quiz/talk_show_view.dart';
import 'package:greek_quiz/features/settings/settings_screen.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/l10n/app_localizations.dart';
import 'package:greek_quiz/features/quiz/quiz_mode.dart';

import 'package:greek_quiz/features/favorites/favorites_service.dart';

// Базовый URL твоего индекса словарей
const String kDictionariesIndexUrl = 'https://redinger.cc/greekquiz/settings.txt';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
    // Инициализация + попытка автозагрузки при первом запуске
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final svc = ref.read(dictionaryServiceProvider);
      final settings = ref.read(settingsProvider);

      // Инициализируем сервис избранного до словарей
      await ref.read(favoritesServiceProvider).initialize();

      // initializeWithBootstrap сам решит, нужно ли качать (первый запуск/нет файлов)
      await svc.initializeWithBootstrap(
        interfaceLanguage: settings.interfaceLanguage,
        indexUrlIfBootstrap: kDictionariesIndexUrl,
      );

      // После инициализации обновляем режимы
      ref.read(quizProvider.notifier).refresh();
      ref.read(keyboardQuizProvider.notifier).refresh();
      ref.read(cardModeProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dictionaryService = ref.watch(dictionaryServiceProvider);
    final settings = ref.watch(settingsProvider);

    // Нужно ли показать "первичную заглушку": словарей ещё нет и загрузка не идёт
    final bool needsFirstDownloadCta =
        !dictionaryService.isDownloading &&
            dictionaryService.availableDictionaries.isEmpty;

    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: null, // без названия приложения
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: l10n.title_settings_navigation,
              onPressed: () async {
                // спрятать клавиатуру при входе в настройки
                FocusScope.of(context).unfocus();
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.95,
                    child: const SettingsScreen(),
                  ),
                );
                // после закрытия — ещё раз спрятать
                FocusScope.of(context).unfocus();
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.library_books_outlined),
                tooltip: l10n.select_dictionaries_title,
                onPressed: () async {
                  FocusScope.of(context).unfocus();

                  await ref.read(dictionaryServiceProvider).ensureAvailableLoaded();

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

                  // Обновляем провайдеры после изменения словарей
                  ref.read(quizProvider.notifier).refresh();
                  ref.read(keyboardQuizProvider.notifier).refresh();
                  ref.read(cardModeProvider.notifier).refresh();

                  FocusScope.of(context).unfocus();
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
                    // При выходе из режима клавиатуры — прячем клавиатуру
                    if (_selectedMode != QuizMode.keyboard) {
                      FocusScope.of(context).unfocus();
                    }
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

        // Оверлей прогресса загрузки словарей
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

        // Первая загрузка: нет словарей и не идёт скачивание → покажем понятный CTA
        if (needsFirstDownloadCta)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off, size: 48, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 16),
                        // Используем существующие ключи локализации статуса ошибки
                        Text(
                          l10n.getString('download_error'),
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No dictionaries available. Check your internet connection and try again.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilledButton.icon(
                              icon: const Icon(Icons.download),
                              label: const Text('Download dictionaries'),
                              onPressed: () async {
                                final svc = ref.read(dictionaryServiceProvider);
                                try {
                                  await svc.downloadAndSaveDictionaries(
                                    settings.interfaceLanguage,
                                    indexUrl: kDictionariesIndexUrl,
                                  );
                                  // после загрузки — обновить провайдеры
                                  ref.read(quizProvider.notifier).refresh();
                                  ref.read(keyboardQuizProvider.notifier).refresh();
                                  ref.read(cardModeProvider.notifier).refresh();
                                } catch (_) {
                                  // Ошибка уже отражена через statusMessage/download_error
                                }
                              },
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.settings_outlined),
                              label: Text(l10n.title_settings_navigation),
                              onPressed: () async {
                                FocusScope.of(context).unfocus();
                                await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.95,
                                    child: const SettingsScreen(),
                                  ),
                                );
                                FocusScope.of(context).unfocus();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
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

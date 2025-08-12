import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greek_quiz/data/models/dictionary_info.dart';
import 'package:greek_quiz/data/services/dictionary_service.dart';
import 'package:greek_quiz/features/dictionary/words_list_view.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/l10n/app_localizations.dart';

class DictionarySelectionView extends ConsumerStatefulWidget {
  const DictionarySelectionView({super.key});

  @override
  ConsumerState<DictionarySelectionView> createState() =>
      _DictionarySelectionViewState();
}

class _DictionarySelectionViewState
    extends ConsumerState<DictionarySelectionView> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.watch(dictionaryServiceProvider);
    final settings = ref.watch(settingsProvider);

    // Список доступных словарей
    final List<DictionaryInfo> available = [...service.availableDictionaries];

    // Сортировка по локализованному названию
    String locName(DictionaryInfo d) =>
        d.getLocalizedName(settings.interfaceLanguage);
    available.sort(
          (a, b) => locName(a).toLowerCase().compareTo(locName(b).toLowerCase()),
    );

    final hasSelection = service.selectedDictionaries.isNotEmpty;

    // Заголовок — компактный
    final baseTitle = Theme.of(context).textTheme.headlineMedium;
    final tinyTitle = baseTitle?.copyWith(
      fontSize: (baseTitle?.fontSize ?? 24) * 0.8,
      fontWeight: FontWeight.w600,
    );

    return SafeArea(
      top: false,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Шапка: заголовок по центру (меньше), Done — справа
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
                child: Row(
                  children: [
                    // Баланс слева, чтобы центрирование было честным
                    const SizedBox(width: 64),
                    Expanded(
                      child: Center(
                        child: Text(
                          l10n.select_dictionaries_title,
                          style: tinyTitle,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(l10n.button_done),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Облако "чипов" со словарями
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 0,
                    children: [
                      for (final d in available)
                        ChoiceChip(
                          label: Text(locName(d)),
                          selected: service.selectedDictionaries.contains(d.file),
                          onSelected: (_) {
                            // переключаем выбранность словаря
                            service.toggleDictionarySelection(d.file);
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Кнопка "Words list" — перед открытием перечитываем активные слова
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: hasSelection
                          ? () async {
                        // Обновим activeWords под текущий выбор,
                        // чтобы список слов не был пустым.
                        service.filterActiveWords();

                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          backgroundColor: Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (context) => const WordsListView(),
                        );
                      }
                          : null,
                      child: Text(l10n.button_show_words),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

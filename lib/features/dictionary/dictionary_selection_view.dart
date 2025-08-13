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
  bool _ensured = false;

  @override
  void initState() {
    super.initState();
    // гарантия загрузки списка один раз
    Future.microtask(() async {
      await ref.read(dictionaryServiceProvider).ensureAvailableLoaded();
      if (mounted) setState(() => _ensured = true);
    });
  }

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

    // Заголовок — компактнее
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

              // Заглушка загрузки списка
              if (!_ensured && available.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),

              // Облако "чипов" со словарями
              if (available.isNotEmpty)
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
                              service.toggleDictionarySelection(d.file);
                            },
                          ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Кнопка "Words list"
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
                        service.filterActiveWords();
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
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

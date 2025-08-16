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

    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Шапка
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
                    const SizedBox(width: 64),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Заглушка загрузки
              if (!_ensured && available.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),

              // Облако чипов (прижато к краям, компактные, выбранные — ярко залиты)
              if (available.isNotEmpty)
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        runAlignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final d in available)
                            _DictionaryChip(
                              label: locName(d),
                              selected: service.selectedDictionaries.contains(d.file),
                              onTap: () => service.toggleDictionarySelection(d.file),
                            ),
                        ],
                      ),
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
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: scheme.primary,
                        side: BorderSide(color: scheme.outline.withOpacity(0.4)),
                      ),
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

              // Кнопка Done — белая
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(l10n.button_done),
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

/// Ярко залитый selected + инверсия текста под тему.
/// Ничего функционально не меняет.
class _DictionaryChip extends StatelessWidget {
  const _DictionaryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          // инвертируем цвет текста под яркую заливку
          color: selected ? scheme.onPrimary : scheme.onSurface,
        ),
      ),
      showCheckmark: false,

      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
      labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: EdgeInsets.zero,

      // ВАЖНО: делаем выбранный — реально ярким
      selectedColor: scheme.primary,
      backgroundColor: scheme.surfaceVariant.withOpacity(0.45),

      // тонкая обводка у невыбранных; без обводки у выбранных
      side: BorderSide(
        color: selected ? Colors.transparent : scheme.outline.withOpacity(0.5),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // радиус у всех чипсов
      ),

      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

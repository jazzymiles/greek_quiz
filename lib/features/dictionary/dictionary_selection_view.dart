// lib/features/dictionary/dictionary_selection_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/dictionary_info.dart';
import 'package:greek_quiz/data/services/dictionary_service.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/l10n/app_localizations.dart';

class DictionarySelectionView extends ConsumerStatefulWidget {
  const DictionarySelectionView({super.key});
  @override
  ConsumerState<DictionarySelectionView> createState() => _DictionarySelectionViewState();
}

class _DictionarySelectionViewState extends ConsumerState<DictionarySelectionView> {
  late Set<String> _localSelectedDictionaries;

  @override
  void initState() {
    super.initState();
    _localSelectedDictionaries = Set.from(ref.read(dictionaryServiceProvider).selectedDictionaries);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dictionariesAsync = ref.watch(availableDictionariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.select_dictionaries_title),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(dictionaryServiceProvider).selectedDictionaries = _localSelectedDictionaries;
              Navigator.of(context).pop();
            },
            child: Text(l10n.button_done),
          ),
        ],
      ),
      body: dictionariesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка: ${err.toString()}')),
        data: (dictionaries) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _buildChips(context, dictionaries),
          );
        },
      ),
    );
  }

  Widget _buildChips(BuildContext context, List<DictionaryInfo> dictionaries) {
    final settings = ref.watch(settingsProvider);
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: dictionaries.map((dictInfo) {
        final isSelected = _localSelectedDictionaries.contains(dictInfo.file);
        return FilterChip(
          label: Text(dictInfo.getLocalizedName(settings.interfaceLanguage)),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _localSelectedDictionaries.add(dictInfo.file);
              } else {
                _localSelectedDictionaries.remove(dictInfo.file);
              }
            });
          },
        );
      }).toList(),
    );
  }
}
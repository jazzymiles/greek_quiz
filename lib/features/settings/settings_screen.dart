// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/services/dictionary_service.dart';
import 'package:greek_quiz/features/settings/app_settings.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    final Map<String, String> languageMap = {
      'el': l10n.language_el,
      'en': l10n.language_en,
      'ru': l10n.language_ru,
      'system': l10n.language_system,
    };
    final isDownloadButtonDisabled = settings.dictionarySource == DictionarySource.customURL && settingsNotifier.urlController.text.isEmpty;

    return Container(
      color: colorScheme.background,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _SectionHeader(l10n.display_section_header),
                  _SettingsGroup(
                    children: [
                      SwitchListTile(
                        title: Text(l10n.show_transcription_toggle),
                        value: settings.showTranscription,
                        onChanged: settingsNotifier.updateShowTranscription,
                      ),
                      _buildDivider(),
                      SwitchListTile(
                        title: Text(l10n.show_article_toggle),
                        value: settings.showArticle,
                        onChanged: settingsNotifier.updateShowArticle,
                      ),
                      _buildDivider(),
                      SwitchListTile(
                        title: Text(l10n.use_all_words_toggle),
                        subtitle: Text(l10n.use_all_words_subtitle),
                        value: settings.useAllWordsInQuiz,
                        onChanged: settingsNotifier.updateUseAllWordsInQuiz,
                      ),
                    ],
                  ),

                  _SectionHeader(l10n.sound_section_header),
                  _SettingsGroup(
                    children: [
                      SwitchListTile(
                        title: Text(l10n.autoplay_sound_toggle),
                        value: settings.autoPlaySound,
                        onChanged: settingsNotifier.updateAutoPlaySound,
                      ),
                      _buildDivider(),
                      SwitchListTile(
                        title: Text(l10n.answers_sounds_toggle),
                        value: settings.playAnswerSound,
                        onChanged: settingsNotifier.updatePlayAnswerSound,
                      ),
                    ],
                  ),

                  _SectionHeader(l10n.languages_section_header),
                  _SettingsGroup(
                    children: [
                      _PickerTile(
                        title: l10n.interface_language_picker,
                        value: languageMap[settings.interfaceLanguage] ?? '',
                        onTap: () => _showPicker(context, l10n: l10n, options: languageMap, onSelected: settingsNotifier.updateInterfaceLanguage),
                      ),
                      _buildDivider(),
                      _PickerTile(
                        title: l10n.studied_language_picker,
                        value: languageMap[settings.studiedLanguage] ?? '',
                        onTap: () => _showPicker(context, l10n: l10n, options: languageMap, onSelected: settingsNotifier.updateStudiedLanguage, excludeSystem: true),
                      ),
                      _buildDivider(),
                      _PickerTile(
                        title: l10n.answer_language_picker,
                        value: languageMap[settings.answerLanguage] ?? '',
                        onTap: () => _showPicker(context, l10n: l10n, options: languageMap, onSelected: settingsNotifier.updateAnswerLanguage, excludeSystem: true),
                      ),
                    ],
                  ),

                  _SectionHeader(l10n.appearance_section_header),
                  _SettingsGroup(children: [
                    ListTile(
                      title: Text(l10n.theme_picker),
                      trailing: SizedBox(
                        width: 220,
                        child: SegmentedButton<AppTheme>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(value: AppTheme.light, label: Text(l10n.theme_light)),
                            ButtonSegment(value: AppTheme.system, label: Text(l10n.theme_system)),
                            ButtonSegment(value: AppTheme.dark, label: Text(l10n.theme_dark)),
                          ],
                          selected: {settings.appTheme},
                          onSelectionChanged: (selection) => settingsNotifier.updateAppTheme(selection.first),
                        ),
                      ),
                    )
                  ]),

                  _SectionHeader(l10n.dictionaries_section_header),
                  _SettingsGroup(
                    children: [
                      ListTile(
                        title: Text(l10n.dictionary_source_picker),
                        trailing: SizedBox(
                          width: 200,
                          child: SegmentedButton<DictionarySource>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(value: DictionarySource.local, label: Text(l10n.source_local)),
                              ButtonSegment(value: DictionarySource.customURL, label: Text(l10n.source_custom)),
                            ],
                            selected: {settings.dictionarySource},
                            onSelectionChanged: (selection) => settingsNotifier.updateDictionarySource(selection.first),
                          ),
                        ),
                      ),
                      if (settings.dictionarySource == DictionarySource.customURL)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: TextField(
                            controller: settingsNotifier.urlController,
                            decoration: InputDecoration(
                              labelText: l10n.custom_url_label,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: isDownloadButtonDisabled ? null : () {
                          ref.read(dictionaryServiceProvider).downloadAndSaveDictionaries(settings.interfaceLanguage);
                          Navigator.of(context).pop();
                        },
                        child: Text(l10n.download_and_save_dictionaries),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.title_settings_navigation, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.button_done, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 16, endIndent: 16);

  Widget _SectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _SettingsGroup({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        elevation: 1,
        shadowColor: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _PickerTile({required String title, required String value, required VoidCallback onTap}) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showPicker(BuildContext context, {required AppLocalizations l10n, required Map<String, String> options, required void Function(String) onSelected, bool excludeSystem = false}) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(l10n.picker_dialog_title),
          children: options.entries.where((entry) => !(excludeSystem && entry.key == 'system')).map((entry) {
            return SimpleDialogOption(
              onPressed: () {
                onSelected(entry.key);
                Navigator.pop(context);
              },
              child: Text(entry.value),
            );
          }).toList(),
        );
      },
    );
  }
}
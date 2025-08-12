// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greek_quiz/data/services/dictionary_service.dart';
import 'package:greek_quiz/features/settings/app_settings.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void dispose() {
    // Страхуемся от залипания клавиатуры при закрытии экрана
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final dictService = ref.read(dictionaryServiceProvider);

    final Map<String, String> languageMap = {
      'system': l10n.language_system,
      'el': l10n.language_el,
      'en': l10n.language_en,
      'ru': l10n.language_ru,
    };

    final isCustom = settings.dictionarySource == DictionarySource.customURL;
    final isDownloadButtonDisabled =
        isCustom && settingsNotifier.urlController.text.isEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Шапка: заголовок + Done справа
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
              child: Row(
                children: [
                  const SizedBox(width: 64),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.title_settings_navigation,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      SystemChannels.textInput.invokeMethod('TextInput.hide');
                      Navigator.of(context).maybePop();
                    },
                    child: Text(l10n.button_done),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // ===== Отображение =====
                  _SectionHeader(l10n.display_section_header),
                  _SettingsGroup(
                    children: [
                      SwitchListTile(
                        title: Text(l10n.show_transcription_toggle),
                        value: settings.showTranscription,
                        onChanged: settingsNotifier.updateShowTranscription,
                      ),
                      _divider(),
                      SwitchListTile(
                        title: Text(l10n.show_article_toggle),
                        value: settings.showArticle,
                        onChanged: settingsNotifier.updateShowArticle,
                      ),
                      _divider(),
                      SwitchListTile(
                        title: Text(l10n.use_all_words_toggle),
                        subtitle: Text(l10n.use_all_words_subtitle),
                        value: settings.useAllWordsInQuiz,
                        onChanged: settingsNotifier.updateUseAllWordsInQuiz,
                      ),
                    ],
                  ),

                  // ===== Звук =====
                  _SectionHeader(l10n.sound_section_header),
                  _SettingsGroup(
                    children: [
                      SwitchListTile(
                        title: Text(l10n.autoplay_sound_toggle),
                        value: settings.autoPlaySound,
                        onChanged: settingsNotifier.updateAutoPlaySound,
                      ),
                      _divider(),
                      SwitchListTile(
                        title: Text(l10n.answers_sounds_toggle),
                        value: settings.playAnswerSound,
                        onChanged: settingsNotifier.updatePlayAnswerSound,
                      ),
                    ],
                  ),

                  // ===== Языки =====
                  _SectionHeader(l10n.languages_section_header),
                  _SettingsGroup(
                    children: [
                      _PickerTile(
                        title: l10n.interface_language_picker,
                        value: languageMap[settings.interfaceLanguage] ?? '',
                        onTap: () => _showPicker(
                          context,
                          l10n: l10n,
                          options: languageMap,
                          onSelected: settingsNotifier.updateInterfaceLanguage,
                        ),
                      ),
                      _divider(),
                      _PickerTile(
                        title: l10n.studied_language_picker,
                        value: languageMap[settings.studiedLanguage] ?? '',
                        onTap: () => _showPicker(
                          context,
                          l10n: l10n,
                          options: languageMap,
                          onSelected: settingsNotifier.updateStudiedLanguage,
                          excludeSystem: true,
                        ),
                      ),
                      _divider(),
                      _PickerTile(
                        title: l10n.answer_language_picker,
                        value: languageMap[settings.answerLanguage] ?? '',
                        onTap: () => _showPicker(
                          context,
                          l10n: l10n,
                          options: languageMap,
                          onSelected: settingsNotifier.updateAnswerLanguage,
                          excludeSystem: true,
                        ),
                      ),
                    ],
                  ),

                  // ===== Оформление =====
                  _SectionHeader(l10n.appearance_section_header),
                  _SettingsGroup(
                    children: [
                      ListTile(
                        title: Text(l10n.theme_picker),
                        trailing: SizedBox(
                          width: 220,
                          child: SegmentedButton<AppTheme>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: AppTheme.light,
                                label: Text(l10n.theme_light),
                              ),
                              ButtonSegment(
                                value: AppTheme.system,
                                label: Text(l10n.theme_system),
                              ),
                              ButtonSegment(
                                value: AppTheme.dark,
                                label: Text(l10n.theme_dark),
                              ),
                            ],
                            selected: {settings.appTheme},
                            onSelectionChanged: (selection) =>
                                settingsNotifier.updateAppTheme(selection.first),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ===== Источник словарей =====
                  _SectionHeader(l10n.dictionaries_section_header),
                  _SettingsGroup(
                    children: [
                      ListTile(
                        title: Text(l10n.dictionary_source_picker),
                        trailing: SizedBox(
                          width: 220,
                          child: SegmentedButton<DictionarySource>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: DictionarySource.local, // <-- было builtIn
                                label: Text(l10n.source_local),
                              ),
                              ButtonSegment(
                                value: DictionarySource.customURL,
                                label: Text(l10n.source_custom),
                              ),
                            ],
                            selected: {settings.dictionarySource},
                            onSelectionChanged: (selection) =>
                                settingsNotifier.updateDictionarySource(
                                    selection.first),
                          ),
                        ),
                      ),
                      if (settings.dictionarySource == DictionarySource.customURL)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: TextField(
                            controller: settingsNotifier.urlController,
                            autofocus: false, // важно: не поднимать клавиатуру
                            decoration: InputDecoration(
                              labelText: l10n.custom_url_label,
                              hintText: 'https://example.com/dictionary.json',
                              prefixIcon: const Icon(Icons.link),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              FocusManager.instance.primaryFocus?.unfocus();
                              SystemChannels.textInput
                                  .invokeMethod('TextInput.hide');
                            },
                          ),
                        ),
                    ],
                  ),

                  // ===== Кнопка загрузки =====
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.tonal(
                        onPressed: isDownloadButtonDisabled
                            ? null
                            : () async {
                          // Снимем фокус, чтобы после закрытия клавиатура не всплывала
                          FocusManager.instance.primaryFocus?.unfocus();
                          await SystemChannels.textInput
                              .invokeMethod('TextInput.hide');

                          await dictService.downloadAndSaveDictionaries(
                            settings.interfaceLanguage,
                          );

                          if (mounted) Navigator.of(context).maybePop();
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

  // ==== Вспомогательные виджеты/методы ====

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16);

  Future<void> _showPicker(
      BuildContext context, {
        required AppLocalizations l10n,
        required Map<String, String> options,
        required ValueChanged<String> onSelected,
        bool excludeSystem = false,
      }) async {
    final items = options.entries
        .where((e) => excludeSystem ? e.key != 'system' : true)
        .toList();

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final entry = items[i];
            return ListTile(
              title: Text(entry.value),
              onTap: () {
                onSelected(entry.key);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          letterSpacing: 1.0,
          fontWeight: FontWeight.w700,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withOpacity(0.65),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.title,
    required this.value,
    required this.onTap,
    super.key,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}

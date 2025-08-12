import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/data/models/dictionary_info.dart';
import 'package:greek_quiz/data/services/dictionary_service.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/l10n/app_localizations.dart';
import 'package:greek_quiz/shared/services/tts_service.dart';

class WordsListView extends ConsumerStatefulWidget {
  const WordsListView({super.key});

  @override
  ConsumerState<WordsListView> createState() => _WordsListViewState();
}

class _WordsListViewState extends ConsumerState<WordsListView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Подстрахуемся: перед показом перечитаем активные слова
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(dictionaryServiceProvider).filterActiveWords();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _textForLang(Word w, String lang) {
    switch (lang) {
      case 'el':
        return w.el;
      case 'ru':
        return w.ru;
      case 'en':
        return w.en ?? '';
      default:
        return w.el;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.watch(dictionaryServiceProvider);
    final settings = ref.watch(settingsProvider);
    final tts = ref.read(ttsServiceProvider);

    final words = service.activeWords;

    // Словари по id
    final Map<String, DictionaryInfo> dictById = {
      for (final d in service.availableDictionaries) d.file: d
    };

    // Группы по словарям
    final Map<String, List<Word>> grouped = {};
    for (final w in words) {
      grouped.putIfAbsent(w.dictionaryId, () => []).add(w);
    }

    String localizedName(String dictId) {
      final info = dictById[dictId];
      if (info == null) return dictId;
      return info.getLocalizedName(settings.interfaceLanguage);
    }

    final sectionIds = grouped.keys.toList()
      ..sort((a, b) =>
          localizedName(a).toLowerCase().compareTo(localizedName(b).toLowerCase()));

    final query = _searchController.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Заголовок + Done: опустили ниже, чтобы не упиралось в вырез
            Padding(
              padding: const EdgeInsets.fromLTRB(60, 64, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.words_list_title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
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

            // Поиск
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.search_bar_placeholder,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 12),

            // Список
            Expanded(
              child: words.isEmpty
                  ? Center(child: Text(l10n.no_words_loaded))
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 10, 16),
                itemCount: sectionIds.length,
                itemBuilder: (context, sectionIndex) {
                  final dictId = sectionIds[sectionIndex];
                  final title = localizedName(dictId);
                  final list = [...?grouped[dictId]]
                    ..sort((a, b) =>
                        a.el.toLowerCase().compareTo(b.el.toLowerCase()));

                  final filtered = query.isEmpty
                      ? list
                      : list.where((w) {
                    final el = w.el.toLowerCase();
                    final ru = w.ru.toLowerCase();
                    final en = (w.en ?? '').toLowerCase();
                    final tr = w.transcription.toLowerCase();
                    return el.contains(query) ||
                        ru.contains(query) ||
                        en.contains(query) ||
                        tr.contains(query);
                  }).toList();

                  if (filtered.isEmpty) return const SizedBox.shrink();

                  return _Section(
                    title: title,
                    children: [
                      for (final w in filtered)
                        _WordTile(
                          word: w,
                          onSpeak: () async {
                            final lang = settings.studiedLanguage;
                            await tts.speak(_textForLang(w, lang), lang);
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 1.0,
              ),
            ),
          ),
          Card(
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
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({required this.word, required this.onSpeak});

  final Word word;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greek = word.el;
    final ru = word.ru;
    final en = word.en ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        greek,
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ru.isNotEmpty)
            Text(
              ru,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
          if (en.isNotEmpty)
            Text(
              en,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.volume_up),
        onPressed: onSpeak,
        tooltip: 'TTS',
      ),
    );
  }
}

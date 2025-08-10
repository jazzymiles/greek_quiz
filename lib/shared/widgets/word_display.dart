import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/features/settings/app_settings.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';

class WordDisplay extends ConsumerStatefulWidget {
  final Word word;

  const WordDisplay({super.key, required this.word});

  @override
  ConsumerState<WordDisplay> createState() => _WordDisplayState();
}

class _WordDisplayState extends ConsumerState<WordDisplay> {
  bool _temporarilyShowTranscription = false;

  String _getWordWithArticle(Word word, AppSettings settings) {
    var question = word.el;
    if (settings.studiedLanguage == 'el' && settings.showArticle) {
      final String article;
      switch (word.gender?.toLowerCase()) {
        case "m":
        case "м":
          article = "ο";
          break;
        case "f":
        case "ж":
          article = "η";
          break;
        case "n":
        case "ср":
          article = "το";
          break;
        default:
          article = "";
      }
      if (article.isNotEmpty) {
        question = '$article $question';
      }
    }
    return question;
  }

  String _getQuestionText(Word word, AppSettings settings) {
    return switch (settings.studiedLanguage) {
      'el' => _getWordWithArticle(word, settings),
      'en' => word.en ?? '',
      'ru' => word.ru,
      _ => _getWordWithArticle(word, settings),
    };
  }

  // Сбрасываем временный показ при смене слова
  @override
  void didUpdateWidget(covariant WordDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.word.id != oldWidget.word.id) {
      _temporarilyShowTranscription = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final textTheme = Theme.of(context).textTheme;
    final word = widget.word;
    final questionText = _getQuestionText(word, settings);

    bool shouldShowTranscription = settings.showTranscription || _temporarilyShowTranscription;
    bool hasTranscription = word.transcription.isNotEmpty;

    return Column(
      children: [
        Text(questionText, style: textTheme.displaySmall, textAlign: TextAlign.center),
        if (hasTranscription)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  shouldShowTranscription
                      ? '[${word.transcription}]'
                      : '[${'*' * word.transcription.length}]',
                  style: textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
                ),
                if (!settings.showTranscription) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    color: Colors.grey,
                    onPressed: () {
                      setState(() {
                        _temporarilyShowTranscription = !_temporarilyShowTranscription;
                      });
                    },
                  )
                ]
              ],
            ),
          ),
      ],
    );
  }
}
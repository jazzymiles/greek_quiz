import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/features/settings/app_settings.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/shared/services/tts_service.dart';

class WordDisplay extends ConsumerStatefulWidget {
  final Word word;
  final bool autoplayEnabled;

  const WordDisplay({
    super.key,
    required this.word,
    this.autoplayEnabled = true,
  });

  @override
  ConsumerState<WordDisplay> createState() => _WordDisplayState();
}

class _WordDisplayState extends ConsumerState<WordDisplay> {
  bool _temporarilyShowTranscription = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _handleAutoplay(widget.word));
  }

  @override
  void didUpdateWidget(covariant WordDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.word.id != oldWidget.word.id) {
      _temporarilyShowTranscription = false;
      _handleAutoplay(widget.word);
    }
  }

  void _handleAutoplay(Word word) {
    if (!widget.autoplayEnabled) return;

    final settings = ref.read(settingsProvider);
    if (settings.autoPlaySound) {
      _speakWord(word, settings);
    }
  }

  void _speakWord(Word word, AppSettings settings) {
    final ttsService = ref.read(ttsServiceProvider);
    final textToSpeak = _getQuestionText(word, settings, forTts: true);
    ttsService.speak(textToSpeak, settings.studiedLanguage);
  }

  String _getWordWithArticle(Word word, AppSettings settings, {bool forTts = false}) {
    var question = word.el;
    if (settings.studiedLanguage == 'el' && settings.showArticle && !forTts) {
      final String article;
      switch (word.gender?.toLowerCase()) {
        case "m": case "м": article = "ο"; break;
        case "f": case "ж": article = "η"; break;
        case "n": case "ср": article = "το"; break;
        default: article = "";
      }
      if (article.isNotEmpty) {
        question = '$article $question';
      }
    }
    return question;
  }

  String _getQuestionText(Word word, AppSettings settings, {bool forTts = false}) {
    return switch (settings.studiedLanguage) {
      'el' => _getWordWithArticle(word, settings, forTts: forTts),
      'en' => word.en ?? '',
      'ru' => word.ru,
      _ => _getWordWithArticle(word, settings, forTts: forTts),
    };
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(questionText, style: textTheme.displaySmall, textAlign: TextAlign.center)),
            IconButton(
              icon: Icon(Icons.volume_up, color: Theme.of(context).colorScheme.primary),
              onPressed: () => _speakWord(word, settings),
            )
          ],
        ),
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
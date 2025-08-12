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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // автоплей вопроса, если включено
    final settings = ref.read(settingsProvider);
    if (widget.autoplayEnabled && settings.autoPlaySound) {
      final text = _questionText(widget.word, settings);
      ref.read(ttsServiceProvider).speak(text, settings.studiedLanguage);
    }
  }

  /// Текст вопроса (studiedLanguage) с учётом "показывать артикли"
  String _questionText(Word w, AppSettings settings) {
    String base = switch (settings.studiedLanguage) {
      'el' => w.el,
      'ru' => w.ru,
      'en' => w.en ?? '',
      _ => w.el,
    };

    if (settings.studiedLanguage == 'el' && settings.showArticle) {
      final g = (w.gender ?? '').toLowerCase();
      String article = '';
      if (g == 'm' || g == 'м') {
        article = 'ο';
      } else if (g == 'f' || g == 'ж') {
        article = 'η';
      } else if (g == 'n' || g == 'ср') {
        article = 'το';
      }
      if (article.isNotEmpty) {
        base = '$article $base';
      }
    }
    return base;
  }

  /// Текст ответа (answerLanguage) — без артикля
  String _answerText(Word w, AppSettings settings) {
    return switch (settings.answerLanguage) {
      'el' => w.el,
      'ru' => w.ru,
      'en' => w.en ?? '',
      _ => w.el,
    };
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final textTheme = Theme.of(context).textTheme;

    final question = _questionText(widget.word, settings);
    final answer = _answerText(widget.word, settings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Вопрос (основное слово) + TTS
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                question,
                style: textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              icon: Icon(Icons.volume_up, color: Theme.of(context).colorScheme.primary),
              onPressed: () {
                ref.read(ttsServiceProvider).speak(question, settings.studiedLanguage);
              },
            )
          ],
        ),

        // Транскрипция (если включено в настройках) или временно по тапу
        if (settings.showTranscription || _temporarilyShowTranscription) ...[
          const SizedBox(height: 8),
          Text(
            '[${widget.word.transcription}]',
            style: textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ] else if ((widget.word.transcription).isNotEmpty) ...[
          const SizedBox(height: 8),
          IconButton(
            icon: const Icon(Icons.visibility),
            color: Colors.grey,
            onPressed: () {
              setState(() {
                _temporarilyShowTranscription = !_temporarilyShowTranscription;
              });
            },
          ),
        ],

        const SizedBox(height: 24),

        // Ответ (перевод)
        Text(
          answer,
          style: textTheme.headlineMedium?.copyWith(color: Colors.grey.shade700),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

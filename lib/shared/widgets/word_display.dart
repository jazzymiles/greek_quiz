// lib/shared/widgets/word_display.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/features/settings/app_settings.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/shared/services/tts_service.dart';

class WordDisplay extends ConsumerStatefulWidget {
  final Word word;
  final bool autoplayEnabled;

  /// Показывать ли перевод (ответ).
  /// По умолчанию false — чтобы в режимах quiz/keyboard/карточки ответ не «палился» сразу.
  final bool showAnswer;

  const WordDisplay({
    super.key,
    required this.word,
    this.autoplayEnabled = true,
    this.showAnswer = false,
  });

  @override
  ConsumerState<WordDisplay> createState() => _WordDisplayState();
}

class _WordDisplayState extends ConsumerState<WordDisplay> {
  bool _temporarilyShowTranscription = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeAutoplayCurrentWord();
  }

  @override
  void didUpdateWidget(covariant WordDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если сменилось слово — озвучим заново при включённом автоплее
    if (oldWidget.word.id != widget.word.id) {
      _maybeAutoplayCurrentWord(stopBefore: true);
      // при смене слова скрываем разовое отображение транскрипции
      _temporarilyShowTranscription = false;
    }
  }

  Future<void> _maybeAutoplayCurrentWord({bool stopBefore = false}) async {
    final settings = ref.read(settingsProvider);
    if (!(widget.autoplayEnabled && settings.autoPlaySound)) return;

    final tts = ref.read(ttsServiceProvider);
    if (stopBefore) {
      await tts.stop();
    }
    final text = _questionText(widget.word, settings);
    await tts.speak(text, settings.studiedLanguage);
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
              onPressed: () async {
                final tts = ref.read(ttsServiceProvider);
                await tts.stop();
                await tts.speak(question, settings.studiedLanguage);
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

        // Перевод (ответ) — ТОЛЬКО если явно разрешено showAnswer
        if (widget.showAnswer) ...[
          const SizedBox(height: 24),
          Text(
            answer,
            style: textTheme.headlineMedium?.copyWith(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

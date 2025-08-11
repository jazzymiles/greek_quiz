import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/features/quiz/card_mode_provider.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/shared/widgets/word_display.dart';

class CardView extends ConsumerWidget {
  const CardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardState = ref.watch(cardModeProvider);
    final notifier = ref.read(cardModeProvider.notifier);
    final settings = ref.watch(settingsProvider);

    if (cardState.activeWords.isEmpty) {
      return const Center(child: Text("Выберите и скачайте словари"));
    }

    final currentWord = cardState.activeWords[cardState.currentIndex];
    final studyExample = currentWord.getUsageExampleForLanguage(settings.studiedLanguage);
    final answerExample = currentWord.getUsageExampleForLanguage(settings.answerLanguage);

    final answerText = switch (settings.answerLanguage) {
      'el' => currentWord.el,
      'en' => currentWord.en ?? '',
      'ru' => currentWord.ru,
      _ => currentWord.el,
    };

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: notifier.flipCard,
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < -100) notifier.nextWord();
              if (details.primaryVelocity! > 100) notifier.previousWord();
            },
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedSwitcher(
                duration: Duration.zero,
                child: cardState.showTranslation
                    ? _buildCardBack(context, answerText, studyExample, answerExample)
                    : _buildCardFront(context, currentWord),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 30),
                onPressed: notifier.previousWord,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 30),
                onPressed: notifier.nextWord,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardFront(BuildContext context, Word currentWord) {
    return SizedBox.expand(
      key: ValueKey('front-${currentWord.id}'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: WordDisplay(word: currentWord),
          ),
          const Spacer(flex: 1),
          const Icon(Icons.touch_app_outlined, size: 40, color: Colors.grey),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildCardBack(BuildContext context, String answerText, String? studyExample, String? answerExample) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox.expand(
      key: ValueKey('back-$answerText'),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(answerText, style: textTheme.displaySmall, textAlign: TextAlign.center),
              if (studyExample != null && studyExample.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: [
                      Text(
                        studyExample,
                        style: textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                      ),
                      if (answerExample != null && answerExample.isNotEmpty && answerExample != studyExample)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            answerExample,
                            style: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
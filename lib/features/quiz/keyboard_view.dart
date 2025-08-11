import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/features/quiz/keyboard_quiz_provider.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/l10n/app_localizations.dart';
import 'package:greek_quiz/shared/widgets/word_display.dart';

class KeyboardView extends ConsumerWidget {
  const KeyboardView({super.key});

  String _getWordField(Word word, String langCode) {
    return switch (langCode) { 'el' => word.el, 'en' => word.en ?? '', 'ru' => word.ru, _ => word.el };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(keyboardQuizProvider);
    final notifier = ref.read(keyboardQuizProvider.notifier);
    final settings = ref.watch(settingsProvider);

    final currentWord = state.currentWord;
    if (currentWord == null) {
      return Center(child: Text(l10n.error_no_words_loaded));
    }

    final correctAnswer = _getWordField(currentWord, settings.answerLanguage);
    final studyExample = currentWord.getUsageExampleForLanguage(settings.studiedLanguage);
    final answerExample = currentWord.getUsageExampleForLanguage(settings.answerLanguage);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WordDisplay(word: currentWord),

            _buildFeedback(context, l10n, state, correctAnswer),

            if (studyExample != null && studyExample.isNotEmpty)
              _buildUsageExample(
                  context: context,
                  studyExample: studyExample,
                  answerExample: answerExample,
                  isVisible: state.status == KeyboardQuizStatus.checked
              ),

            const SizedBox(height: 20),

            TextField(
              controller: notifier.textController,
              decoration: InputDecoration(labelText: l10n.your_translation_placeholder),
              enabled: state.status == KeyboardQuizStatus.asking,
              onSubmitted: (_) {
                if (state.status == KeyboardQuizStatus.asking) {
                  notifier.checkAnswer();
                }
              },
            ),
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (state.status == KeyboardQuizStatus.checked)
                  FilledButton(onPressed: notifier.showAnswer, child: Text(l10n.show_answer_button)),

                FilledButton(
                  onPressed: state.status == KeyboardQuizStatus.asking ? notifier.checkAnswer : null,
                  child: Text(l10n.check_button),
                ),

                FilledButton(onPressed: notifier.generateNewQuestion, child: Text(l10n.next_button)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildUsageExample({
    required BuildContext context,
    required String studyExample,
    String? answerExample,
    required bool isVisible
  }) {
    return Visibility(
      visible: isVisible,
      maintainAnimation: true,
      maintainState: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isVisible ? 1.0 : 0.0,
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            children: [
              Text(
                studyExample,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              if (answerExample != null && answerExample.isNotEmpty && answerExample != studyExample)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    answerExample,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback(BuildContext context, AppLocalizations l10n, KeyboardQuizState state, String correctAnswer) {
    if (state.status != KeyboardQuizStatus.checked) return const SizedBox(height: 20);
    final text = state.isCorrect ? l10n.correct_answer_feedback : correctAnswer;
    final color = state.isCorrect ? Colors.green : Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(text, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    );
  }
}
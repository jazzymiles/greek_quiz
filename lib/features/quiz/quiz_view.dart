import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/features/quiz/quiz_provider.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/l10n/app_localizations.dart';
import 'package:greek_quiz/shared/services/tts_service.dart';
import 'package:greek_quiz/shared/widgets/word_display.dart';

class QuizView extends ConsumerWidget {
  const QuizView({super.key});

  String _getWordField(Word word, String langCode) {
    return switch (langCode) { 'el' => word.el, 'en' => word.en ?? '', 'ru' => word.ru, _ => word.el };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final quizState = ref.watch(quizProvider);
    final notifier = ref.read(quizProvider.notifier);
    final settings = ref.watch(settingsProvider);

    return quizState.currentWord.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString(), textAlign: TextAlign.center)),
      data: (currentWord) {
        final correctAnswer = _getWordField(currentWord, settings.answerLanguage);
        final studyExample = currentWord.getUsageExampleForLanguage(settings.studiedLanguage);
        final answerExample = currentWord.getUsageExampleForLanguage(settings.answerLanguage);

        // --- Логика для одной кнопки ---
        final bool isAnswerChecked = quizState.showFeedback;
        final bool isAnswerSelected = quizState.selectedAnswer != null;

        final String buttonText = isAnswerChecked ? l10n.next_button : l10n.check_button;
        final VoidCallback? onPressedAction;

        if (isAnswerChecked) {
          onPressedAction = notifier.generateNewQuestion;
        } else {
          onPressedAction = isAnswerSelected ? notifier.checkAnswer : null;
        }
        // ---------------------------------

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              WordDisplay(word: currentWord),
              Container(
                height: 120,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFeedback(context, l10n, quizState, correctAnswer),
                    if (studyExample != null && studyExample.isNotEmpty)
                      _buildUsageExample(
                          context: context,
                          studyExample: studyExample,
                          answerExample: answerExample,
                          isVisible: quizState.showFeedback
                      ),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.8,
                ),
                itemCount: quizState.options.length,
                itemBuilder: (context, index) {
                  final option = quizState.options[index];
                  return _buildOptionButton(context, ref, option, quizState, correctAnswer);
                },
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: 250,
                height: 50,
                child: FilledButton(
                  onPressed: onPressedAction,
                  child: Text(buttonText),
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildFeedback(BuildContext context, AppLocalizations l10n, QuizState state, String correctAnswer) {
    if (!state.showFeedback || state.selectedAnswer == null) return const SizedBox.shrink();
    final isCorrect = state.selectedAnswer == correctAnswer;
    final text = isCorrect ? l10n.correct_answer_feedback : correctAnswer;
    final color = isCorrect ? Colors.green : Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(text, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    );
  }

  Widget _buildOptionButton(BuildContext context, WidgetRef ref, String option, QuizState state, String correctAnswer) {
    bool isSelected = state.selectedAnswer == option;
    Color? buttonColor;
    BorderSide? border;
    if (state.showFeedback) {
      if (option == correctAnswer) {
        buttonColor = Colors.green.withOpacity(0.3);
      } else if (isSelected) {
        buttonColor = Theme.of(context).colorScheme.error.withOpacity(0.3);
      }
    } else if (isSelected) {
      border = BorderSide(color: Theme.of(context).colorScheme.primary, width: 2);
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: buttonColor,
        side: border,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: state.showFeedback
          ? null
          : () {
        final settings = ref.read(settingsProvider);
        if (settings.playAnswerSound) {
          ref.read(ttsServiceProvider).speak(option, settings.answerLanguage);
        }
        ref.read(quizProvider.notifier).selectAnswer(option);
      },
      child: Text(option, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
    );
  }
}
// lib/features/quiz/quiz_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/features/quiz/quiz_provider.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/l10n/app_localizations.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return quizState.currentWord.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString(), textAlign: TextAlign.center)),
      data: (currentWord) {
        final questionText = _getWordField(currentWord, settings.studiedLanguage);
        final correctAnswer = _getWordField(currentWord, settings.answerLanguage);

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(questionText, style: textTheme.displaySmall, textAlign: TextAlign.center),
                if (settings.showTranscription && currentWord.transcription.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('[${currentWord.transcription}]', style: textTheme.titleLarge?.copyWith(color: Colors.grey.shade600)),
                  ),

                SizedBox(height: 40, child: _buildFeedback(context, l10n, quizState, correctAnswer)),

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

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton(
                      onPressed: quizState.selectedAnswer != null && !quizState.showFeedback ? notifier.checkAnswer : null,
                      child: Text(l10n.check_button),
                    ),
                    FilledButton(
                      onPressed: notifier.generateNewQuestion,
                      child: Text(l10n.next_button),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedback(BuildContext context, AppLocalizations l10n, QuizState state, String correctAnswer) {
    if (!state.showFeedback || state.selectedAnswer == null) return const SizedBox.shrink();

    final isCorrect = state.selectedAnswer == correctAnswer;
    final text = isCorrect ? l10n.correct_answer_feedback : '${l10n.incorrect_answer_feedback}$correctAnswer';
    final color = isCorrect ? Colors.green : Theme.of(context).colorScheme.error;

    return Text(text, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center);
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
      onPressed: state.showFeedback ? null : () => ref.read(quizProvider.notifier).selectAnswer(option),
      child: Text(option, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
    );
  }
}
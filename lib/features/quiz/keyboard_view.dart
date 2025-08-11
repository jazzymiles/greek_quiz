import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/features/quiz/keyboard_quiz_provider.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/l10n/app_localizations.dart';
import 'package:greek_quiz/shared/widgets/word_display.dart';

class KeyboardView extends ConsumerStatefulWidget {
  const KeyboardView({super.key});

  @override
  ConsumerState<KeyboardView> createState() => _KeyboardView();
}

class _KeyboardView extends ConsumerState<KeyboardView> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String _getWordField(Word word, String langCode) {
    return switch (langCode) { 'el' => word.el, 'en' => word.en ?? '', 'ru' => word.ru, _ => word.el };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(keyboardQuizProvider);
    final notifier = ref.read(keyboardQuizProvider.notifier);
    final settings = ref.watch(settingsProvider);

    ref.listen<KeyboardQuizState>(keyboardQuizProvider, (previous, next) {
      if (next.status == KeyboardQuizStatus.asking && previous?.status == KeyboardQuizStatus.checked) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });

    final currentWord = state.currentWord;
    if (currentWord == null) {
      return Center(child: Text(l10n.error_no_words_loaded));
    }

    final correctAnswer = _getWordField(currentWord, settings.answerLanguage);
    final studyExample = currentWord.getUsageExampleForLanguage(settings.studiedLanguage);
    final answerExample = currentWord.getUsageExampleForLanguage(settings.answerLanguage);

    final bool isAnswerChecked = state.status == KeyboardQuizStatus.checked;
    final String buttonText = isAnswerChecked ? l10n.next_button : l10n.check_button;
    final VoidCallback? onPressedAction;
    final isButtonEnabled = notifier.textController.text.trim().isNotEmpty;

    if (isAnswerChecked) {
      onPressedAction = notifier.generateNewQuestion;
    } else {
      onPressedAction = isButtonEnabled ? notifier.checkAnswer : null;
    }

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
                _buildFeedback(context, l10n, state, correctAnswer),
                if (studyExample != null && studyExample.isNotEmpty)
                  _buildUsageExample(
                      context: context,
                      studyExample: studyExample,
                      answerExample: answerExample,
                      isVisible: isAnswerChecked
                  ),
              ],
            ),
          ),
          TextField(
            focusNode: _focusNode,
            controller: notifier.textController,
            decoration: InputDecoration(labelText: l10n.your_translation_placeholder),
            enabled: !isAnswerChecked,
            onChanged: (text) => setState(() {}),
            onSubmitted: (_) {
              if (isButtonEnabled && !isAnswerChecked) {
                onPressedAction!();
              }
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
    if (state.status != KeyboardQuizStatus.checked) return const SizedBox.shrink();
    final text = state.isCorrect ? l10n.correct_answer_feedback : correctAnswer;
    final color = state.isCorrect ? Colors.green : Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(text, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    );
  }
}
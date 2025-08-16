import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/features/quiz/keyboard_quiz_provider.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/l10n/app_localizations.dart';
import 'package:greek_quiz/shared/widgets/word_display.dart';
import 'package:greek_quiz/features/quiz/quiz_mode.dart';

class KeyboardView extends ConsumerStatefulWidget {
  const KeyboardView({super.key});

  @override
  ConsumerState<KeyboardView> createState() => _KeyboardViewState();
}

class _KeyboardViewState extends ConsumerState<KeyboardView> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Locale _localeForAnswerLang(String code) {
    switch (code) {
      case 'ru':
        return const Locale('ru', 'RU');
      case 'el':
        return const Locale('el', 'GR');
      case 'en':
        return const Locale('en', 'US');
      default:
        return const Locale('en', 'US');
    }
  }

  String _getWordField(Word word, String langCode) {
    switch (langCode) {
      case 'el':
        return word.el;
      case 'en':
        return word.en ?? '';
      case 'ru':
        return word.ru;
      default:
        return word.el;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final state = ref.watch(keyboardQuizProvider);
    final notifier = ref.read(keyboardQuizProvider.notifier);

    // Смена режима: в keyboard — фокусируем, иначе скрываем
    ref.listen<QuizMode>(quizModeProvider, (prev, next) {
      if (next == QuizMode.keyboard) {
        FocusScope.of(context).requestFocus(_focusNode);
      } else {
        _focusNode.unfocus();
      }
    });

    // После проверки и перехода к новому вопросу — снова фокус
    ref.listen<KeyboardQuizState>(keyboardQuizProvider, (previous, next) {
      if (previous?.status == KeyboardQuizStatus.checked &&
          next.status == KeyboardQuizStatus.asking) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });

    final currentWord = state.currentWord;
    if (currentWord == null) {
      return Center(child: Text(l10n.error_no_dictionaries_selected));
    }

    final correctAnswer = _getWordField(currentWord, settings.answerLanguage);

    // Примеры — как в QuizView
    final studyExample =
    currentWord.getUsageExampleForLanguage(settings.studiedLanguage);
    final answerExample =
    currentWord.getUsageExampleForLanguage(settings.answerLanguage);

    final isChecked = state.status == KeyboardQuizStatus.checked;
    final buttonText = isChecked ? l10n.next_button : l10n.check_button;
    final isButtonEnabled = notifier.textController.text.trim().isNotEmpty;

    VoidCallback? onPressed;
    if (isChecked) {
      onPressed = notifier.generateNewQuestion;
    } else if (isButtonEnabled) {
      onPressed = notifier.checkAnswer;
    }

    final inputField = TextField(
      focusNode: _focusNode,
      controller: notifier.textController,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: l10n.your_translation_placeholder,
      ),
      enabled: !isChecked,
      onSubmitted: (_) {
        if (onPressed != null && !isChecked) onPressed();
      },
    );

    // === Вёрстка как в QuizView: контент со скроллом и кнопка внутри ниже поля ===
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WordDisplay(
            word: currentWord,
            autoplayEnabled: settings.autoPlaySound,
          ),

          // Блок фидбэка + примеры — фиксированной высоты (как в квизе)
          Container(
            height: 120,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isChecked)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      state.isCorrect ? l10n.correct_answer_feedback : correctAnswer,
                      style: TextStyle(
                        color: state.isCorrect
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Примеры, только когда ответ проверён
                if (isChecked && studyExample != null && studyExample.isNotEmpty)
                  _buildUsageExample(
                    context: context,
                    studyExample: studyExample,
                    answerExample: answerExample,
                  ),
              ],
            ),
          ),

          // Поле ввода с нужной локалью клавиатуры
          Localizations.override(
            context: context,
            locale: _localeForAnswerLang(settings.answerLanguage),
            child: inputField,
          ),
          const SizedBox(height: 40),

          // Кнопка проверки — как в QuizView (по центру, фиксированная ширина)
          Center(
            child: SizedBox(
              width: 250,
              height: 50,
              child: FilledButton(
                onPressed: onPressed,
                child: Text(buttonText),
              ),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Column(
        children: [
          Text(
            studyExample,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis, // чтобы влезло в 120px блока
          ),
          if (answerExample != null &&
              answerExample.isNotEmpty &&
              answerExample != studyExample)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                answerExample,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

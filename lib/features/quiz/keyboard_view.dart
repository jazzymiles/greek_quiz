import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/features/quiz/keyboard_quiz_provider.dart';
import 'package:greek_quiz/features/quiz/quiz_mode.dart'; // <— слушаем текущий режим
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/l10n/app_localizations.dart';
import 'package:greek_quiz/shared/widgets/word_display.dart';

class KeyboardView extends ConsumerStatefulWidget {
  const KeyboardView({super.key});

  @override
  ConsumerState<KeyboardView> createState() => _KeyboardViewState();
}

class _KeyboardViewState extends ConsumerState<KeyboardView>
    with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Если уже находимся в режиме Keyboard при создании — сфокусируемся после первого кадра.
    if (ref.read(quizModeProvider) == QuizMode.keyboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) FocusScope.of(context).requestFocus(_focusNode);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // На сворачивание приложения — уберём клавиатуру, чтобы не «залипала».
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  void deactivate() {
    // В IndexedStack экран может стать невидимым — прячем клавиатуру.
    FocusManager.instance.primaryFocus?.unfocus();
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ВАЖНО: слушаем смену режима прямо в build (так требует текущая версия Riverpod).
    ref.listen<QuizMode>(
      quizModeProvider,
          (prev, mode) {
        if (mode == QuizMode.keyboard) {
          // Перешли в режим Keyboard — принудительно фокусируем поле.
          Future.microtask(() {
            if (mounted) FocusScope.of(context).requestFocus(_focusNode);
          });
        } else {
          // Ушли из режима Keyboard — принудительно прячем клавиатуру.
          Future.microtask(() {
            if (mounted) FocusScope.of(context).unfocus();
          });
        }
      },
    );

    // Если мы уже в режиме Keyboard, а фокуса нет (пользователь ткнул вне поля) —
    // мягко вернём фокус, чтобы клавиатура «всегда была на экране» в этом режиме.
    if (ref.read(quizModeProvider) == QuizMode.keyboard && !_focusNode.hasFocus) {
      // post-frame, чтобы не триггерить setState во время сборки
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) FocusScope.of(context).requestFocus(_focusNode);
      });
    }

    final l10n = AppLocalizations.of(context)!;

    final state = ref.watch(keyboardQuizProvider);
    final notifier = ref.read(keyboardQuizProvider.notifier);
    final settings = ref.watch(settingsProvider);

    final Word? currentWord = state.currentWord;
    final isChecked = state.status == KeyboardQuizStatus.checked;

    // Тексты кнопок и действия
    final controller = notifier.textController;
    final isInputNotEmpty = controller.text.trim().isNotEmpty;

    VoidCallback? primaryAction;
    String primaryText;
    if (!isChecked) {
      primaryText = l10n.check_button;
      primaryAction = isInputNotEmpty ? notifier.checkAnswer : null;
    } else {
      primaryText = l10n.next_button;
      primaryAction = notifier.generateNewQuestion;
    }

    return Scaffold(
      // Убираем resize, чтобы поле оставалось «на месте», а мы контролировали фокус сами.
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: currentWord == null
            ? Center(child: Text(l10n.no_words_loaded))
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Слово/фраза для перевода (используем ваш готовый виджет)
              WordDisplay(word: currentWord, autoplayEnabled: false),
              const SizedBox(height: 16),

              // Фидбек (правильно / правильный ответ)
              _buildFeedback(context, l10n, state, _correctAnswerFor(state)),

              const SizedBox(height: 8),

              // Поле ввода: всегда фокус в режиме Keyboard
              TextField(
                controller: controller,
                focusNode: _focusNode,
                autofocus: false, // фокусируем вручную (см. выше)
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.your_translation_placeholder,
                ),
                // Не блокируем поле после проверки — чтобы «клавиатура всегда была на экране»
                enabled: true,
                onChanged: (_) {
                  // Перерисуем кнопки (enable/disable)
                  setState(() {});
                },
                onSubmitted: (_) {
                  if (!isChecked && isInputNotEmpty) {
                    notifier.checkAnswer();
                  } else if (isChecked) {
                    notifier.generateNewQuestion();
                  }
                  // После действий возвращаем фокус в поле
                  Future.microtask(() {
                    if (mounted && ref.read(quizModeProvider) == QuizMode.keyboard) {
                      FocusScope.of(context).requestFocus(_focusNode);
                    }
                  });
                },
              ),

              const SizedBox(height: 24),

              // Кнопки действий
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Показать ответ (актуально, когда ещё не проверили)
                  TextButton(
                    onPressed: !isChecked ? () {
                      notifier.showAnswer();
                      // Фокус оставляем, клавиатура остаётся открытой
                      Future.microtask(() {
                        if (mounted && ref.read(quizModeProvider) == QuizMode.keyboard) {
                          FocusScope.of(context).requestFocus(_focusNode);
                        }
                      });
                    } : null,
                    child: Text(l10n.show_answer_button),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 220,
                    height: 48,
                    child: FilledButton(
                      onPressed: primaryAction == null
                          ? null
                          : () {
                        primaryAction!();
                        // Возвращаем фокус, чтобы клавиатура не закрывалась
                        Future.microtask(() {
                          if (mounted && ref.read(quizModeProvider) == QuizMode.keyboard) {
                            FocusScope.of(context).requestFocus(_focusNode);
                          }
                        });
                      },
                      child: Text(primaryText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Вытаскиваем правильный ответ для подсказки/фидбека
  String _correctAnswerFor(KeyboardQuizState state) {
    final settings = ref.read(settingsProvider);
    final w = state.currentWord;
    if (w == null) return '';
    switch (settings.answerLanguage) {
      case 'el':
        return w.el ?? '';
      case 'en':
        return w.en ?? '';
      case 'ru':
        return w.ru ?? '';
      default:
        return w.el ?? '';
    }
  }

  Widget _buildFeedback(
      BuildContext context,
      AppLocalizations l10n,
      KeyboardQuizState state,
      String correctAnswer,
      ) {
    if (state.status != KeyboardQuizStatus.checked) {
      return const SizedBox.shrink();
    }
    final text = state.isCorrect ? l10n.correct_answer_feedback : correctAnswer;
    final color =
    state.isCorrect ? Colors.green : Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/calcademy_design.dart';
import 'package:calcademy/core/widgets/empty_state.dart';
import 'package:calcademy/features/quiz/application/quiz_session_controller.dart';
import 'package:calcademy/features/quiz/domain/quiz_answer_validator.dart';
import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/domain/quiz_session.dart';
import 'package:calcademy/features/quiz/presentation/quiz_labels.dart';
import 'package:calcademy/features/quiz/presentation/quiz_navigation.dart';
import 'package:calcademy/features/quiz/presentation/widgets/quiz_feedback_panel.dart';
import 'package:calcademy/features/quiz/presentation/widgets/quiz_option_tile.dart';
import 'package:calcademy/features/quiz/presentation/widgets/quiz_question_card.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Runs one session: shows a question, records the answer, and moves on.
///
/// Answers are locked once submitted, so a second tap cannot rewrite a
/// verdict; the controller enforces that, and this screen just reflects it.
class QuizSessionPage extends ConsumerStatefulWidget {
  const QuizSessionPage({super.key});

  @override
  ConsumerState<QuizSessionPage> createState() => _QuizSessionPageState();
}

class _QuizSessionPageState extends ConsumerState<QuizSessionPage> {
  final _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(quizSessionProvider);
    if (session == null || session.questions.isEmpty) {
      return CalcademyScaffold(
        title: Text(context.l10n.t('quiz')),
        body: Center(
          child: EmptyState(
            key: const Key('quiz-session-empty'),
            icon: Icons.school_outlined,
            title: context.l10n.t('quizNoSessionTitle'),
            body: context.l10n.t('quizNoSessionBody'),
            action: FilledButton(
              onPressed: () => leaveQuizFlow(context),
              child: Text(context.l10n.t('quizBackToTopics')),
            ),
          ),
        ),
      );
    }

    final question = session.currentQuestion;
    final answer = session.currentAnswer;
    final answered = answer != null;
    final showVerdict =
        session.config.feedbackMode == QuizFeedbackMode.immediate;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: CalcademyScaffold(
        title: Text(
          quizProgressLabel(
            context,
            session.currentIndex,
            session.questions.length,
          ),
          key: const Key('quiz-session-progress-label'),
        ),
        leading: IconButton(
          key: const Key('quiz-session-close'),
          icon: const Icon(Icons.close_rounded),
          tooltip: context.l10n.t('close'),
          onPressed: _confirmExit,
        ),
        body: SafeArea(
          key: const Key('quiz-session-safe-area'),
          top: false,
          minimum: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              children: [
                LinearProgressIndicator(
                  key: const Key('quiz-session-progress'),
                  value: (session.currentIndex + 1) / session.questions.length,
                ),
                Expanded(
                  child: ListView(
                    key: const Key('quiz-session-scroll'),
                    padding: AppBreakpoints.pagePadding(
                      constraints.maxWidth,
                    ).copyWith(top: AppSpacing.md, bottom: AppSpacing.md),
                    children: [
                      QuizQuestionCard(question: question),
                      const SizedBox(height: AppSpacing.lg),
                      if (question.type == QuestionType.multipleChoice)
                        _Options(
                          question: question,
                          answer: answer,
                          showVerdict: showVerdict,
                          onSelect: _submit,
                        )
                      else
                        _WrittenAnswerField(
                          controller: _answerController,
                          enabled: !answered,
                          onSubmitted: _submit,
                        ),
                      if (answered) ...[
                        const SizedBox(height: AppSpacing.lg),
                        QuizFeedbackPanel(
                          isCorrect: answer.isCorrect,
                          showVerdict: showVerdict,
                          correctAnswer: quizAnswerText(question.correctAnswer),
                          submittedAnswer: answer.isCorrect
                              ? null
                              : _submittedText(question, answer),
                          noteKey: answer.noteKey,
                          explanation: quizExplanationText(context, question),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: AppBreakpoints.pagePadding(
                    constraints.maxWidth,
                  ).copyWith(top: AppSpacing.xs, bottom: AppSpacing.sm),
                  // Rebuilt on every keystroke so the submit button can stay
                  // disabled while the field is empty: a submission is final,
                  // and a stray tap must not spend the question on nothing.
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _answerController,
                    builder: (context, value, _) => _ActionBar(
                      answered: answered,
                      isLastQuestion: session.isLastQuestion,
                      isWritten: question.type == QuestionType.written,
                      canSubmit: value.text.trim().isNotEmpty,
                      onSubmit: () => _submit(_answerController.text),
                      onAdvance: _advance,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _submittedText(QuizQuestion question, QuizAnswer answer) =>
      quizSubmittedText(
        question,
        question.type == QuestionType.written
            ? answer.submitted
            : question.optionById(answer.submitted)?.text ?? '',
      );

  /// Ignores a blank written submission, so the keyboard's done action cannot
  /// lock in an empty answer either.
  void _submit(String submitted) {
    final session = ref.read(quizSessionProvider);
    if (session == null || session.questions.isEmpty) return;
    if (session.currentQuestion.type == QuestionType.written &&
        submitted.trim().isEmpty) {
      return;
    }
    ref.read(quizSessionProvider.notifier).submit(submitted);
  }

  void _advance() {
    final session = ref.read(quizSessionProvider);
    if (session == null) return;
    if (session.isLastQuestion) {
      context.pushReplacement('/quiz/result');
      return;
    }
    _answerController.clear();
    ref.read(quizSessionProvider.notifier).next();
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('quiz-exit-dialog'),
        title: Text(context.l10n.t('quizExitTitle')),
        content: Text(context.l10n.t('quizExitBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton(
            key: const Key('quiz-exit-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.t('quizExitConfirm')),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    ref.read(quizSessionProvider.notifier).clear();
    if (mounted) leaveQuizFlow(context);
  }
}

class _Options extends StatelessWidget {
  const _Options({
    required this.question,
    required this.answer,
    required this.showVerdict,
    required this.onSelect,
  });

  final QuizQuestion question;
  final QuizAnswer? answer;
  final bool showVerdict;
  final ValueChanged<String> onSelect;

  static const _labels = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final correctId = QuizAnswerValidator.correctOption(question)?.id;
    return Column(
      key: const Key('quiz-options'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, option) in question.options.indexed) ...[
          QuizOptionTile(
            key: Key('quiz-option-${option.id}'),
            option: option,
            label: index < _labels.length ? _labels[index] : '${index + 1}',
            state: _stateFor(option.id, correctId),
            onTap: answer == null ? () => onSelect(option.id) : null,
          ),
          if (index < question.options.length - 1)
            const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }

  QuizOptionState _stateFor(String optionId, String? correctId) {
    final answer = this.answer;
    if (answer == null) return QuizOptionState.idle;
    if (!showVerdict) {
      return answer.submitted == optionId
          ? QuizOptionState.selected
          : QuizOptionState.idle;
    }
    if (optionId == correctId) return QuizOptionState.correct;
    if (answer.submitted == optionId) return QuizOptionState.incorrect;
    return QuizOptionState.idle;
  }
}

class _WrittenAnswerField extends StatelessWidget {
  const _WrittenAnswerField({
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    key: const Key('quiz-answer-field'),
    controller: controller,
    enabled: enabled,
    autocorrect: false,
    enableSuggestions: false,
    textInputAction: TextInputAction.done,
    onSubmitted: enabled ? onSubmitted : null,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontFamily: 'monospace'),
    decoration: InputDecoration(
      labelText: context.l10n.t('quizAnswerHint'),
      prefixIcon: const Icon(Icons.edit_rounded),
    ),
  );
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.answered,
    required this.isLastQuestion,
    required this.isWritten,
    required this.canSubmit,
    required this.onSubmit,
    required this.onAdvance,
  });

  final bool answered;
  final bool isLastQuestion;
  final bool isWritten;

  /// Written mode only: false while the answer field is blank.
  final bool canSubmit;
  final VoidCallback onSubmit;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    if (!answered) {
      if (!isWritten) return const SizedBox.shrink();
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('quiz-submit'),
          onPressed: canSubmit ? onSubmit : null,
          icon: const Icon(Icons.check_rounded),
          label: Text(context.l10n.t('quizSubmit')),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const Key('quiz-advance'),
        onPressed: onAdvance,
        icon: Icon(
          isLastQuestion ? Icons.flag_rounded : Icons.arrow_forward_rounded,
        ),
        label: Text(
          context.l10n.t(isLastQuestion ? 'quizSeeResult' : 'quizNext'),
        ),
      ),
    );
  }
}

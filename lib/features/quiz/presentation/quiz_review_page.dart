import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/calcademy_design.dart';
import 'package:calcademy/core/widgets/empty_state.dart';
import 'package:calcademy/features/quiz/application/quiz_session_controller.dart';
import 'package:calcademy/features/quiz/domain/quiz_result.dart';
import 'package:calcademy/features/quiz/presentation/quiz_labels.dart';
import 'package:calcademy/features/quiz/presentation/quiz_navigation.dart';
import 'package:calcademy/features/quiz/presentation/widgets/quiz_feedback_panel.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every question the learner missed, each with the rule behind it.
class QuizReviewPage extends ConsumerWidget {
  const QuizReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(quizResultProvider);
    final entries = result?.incorrectEntries ?? const <QuizReviewEntry>[];
    if (result == null || entries.isEmpty) {
      return CalcademyScaffold(
        title: Text(context.l10n.t('quizReviewTitle')),
        body: Center(
          child: EmptyState(
            key: const Key('quiz-review-empty'),
            icon: Icons.task_alt_rounded,
            title: context.l10n.t(
              result == null ? 'quizNoSessionTitle' : 'quizAllCorrectTitle',
            ),
            body: context.l10n.t(
              result == null ? 'quizNoSessionBody' : 'quizAllCorrectBody',
            ),
            action: FilledButton(
              onPressed: () => leaveQuizFlow(context),
              child: Text(context.l10n.t('quizBackToTopics')),
            ),
          ),
        ),
      );
    }

    return CalcademyScaffold(
      title: Text(context.l10n.t('quizReviewTitle')),
      body: SafeArea(
        key: const Key('quiz-review-safe-area'),
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            key: const Key('quiz-review-scroll'),
            padding: AppBreakpoints.pagePadding(
              constraints.maxWidth,
            ).copyWith(top: AppSpacing.md, bottom: AppSpacing.xl),
            children: [
              StudyHeader(
                compact: true,
                eyebrow: '${entries.length} / ${result.totalQuestions}',
                title: context.l10n.t('quizReviewTitle'),
                subtitle: context.l10n.t('quizReviewSubtitle'),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final entry in entries) ...[
                _ReviewEntryCard(entry: entry),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewEntryCard extends StatelessWidget {
  const _ReviewEntryCard({required this.entry});

  final QuizReviewEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = entry.question;
    final language = Localizations.localeOf(context).languageCode;
    return Column(
      key: Key('quiz-review-${question.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${quizPromptLabel(context, question.prompt)}  ·  '
          '${question.subtopic.title(language)}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        SelectableText(
          quizExpressionText(question),
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'monospace',
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        QuizFeedbackPanel(
          isCorrect: false,
          correctAnswer: quizAnswerText(question.correctAnswer),
          submittedAnswer: quizSubmittedText(question, entry.submittedText),
          explanation: quizExplanationText(context, question),
        ),
      ],
    );
  }
}

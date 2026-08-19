import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_radius.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/calcademy_design.dart';
import 'package:calcademy/core/widgets/empty_state.dart';
import 'package:calcademy/features/quiz/application/quiz_session_controller.dart';
import 'package:calcademy/features/quiz/domain/quiz_result.dart';
import 'package:calcademy/features/quiz/presentation/quiz_navigation.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Score, verdict, and the three ways out: review, retry, or back to topics.
class QuizResultPage extends ConsumerWidget {
  const QuizResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(quizResultProvider);
    final session = ref.watch(quizSessionProvider);
    if (result == null || session == null || result.totalQuestions == 0) {
      return CalcademyScaffold(
        title: Text(context.l10n.t('quizResultTitle')),
        body: Center(
          child: EmptyState(
            key: const Key('quiz-result-empty'),
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

    final incorrect = result.incorrectCount;
    return CalcademyScaffold(
      title: Text(context.l10n.t('quizResultTitle')),
      body: SafeArea(
        key: const Key('quiz-result-safe-area'),
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            key: const Key('quiz-result-scroll'),
            padding: AppBreakpoints.pagePadding(
              constraints.maxWidth,
            ).copyWith(top: AppSpacing.md, bottom: AppSpacing.xl),
            children: [
              _ScorePanel(result: result),
              const SizedBox(height: AppSpacing.lg),
              SectionLabel(
                title: context.l10n.t('quizScore'),
                icon: Icons.insights_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _Tally(
                      key: const Key('quiz-result-correct'),
                      label: context.l10n.t('quizCorrect'),
                      value: '${result.correctCount}',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _Tally(
                      key: const Key('quiz-result-incorrect'),
                      label: context.l10n.t('quizIncorrect'),
                      value: '$incorrect',
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
              // Noted answers scored, so they never reach the review screen.
              // The result is the only place they can be raised at all.
              if (result.noteKeys.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _Notes(
                  key: const Key('quiz-result-notes'),
                  noteKeys: result.noteKeys,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (incorrect > 0)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('quiz-result-review'),
                    onPressed: () => context.push('/quiz/review'),
                    icon: const Icon(Icons.rate_review_rounded),
                    label: Text(context.l10n.t('quizReviewWrong')),
                  ),
                )
              else
                _AllCorrectNote(key: const Key('quiz-result-all-correct')),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('quiz-result-retry'),
                  onPressed: () {
                    ref.read(quizSessionProvider.notifier).restart();
                    context.pushReplacement('/quiz/session');
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.l10n.t('quizRetry')),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  key: const Key('quiz-result-topics'),
                  onPressed: () => leaveQuizFlow(
                    context,
                    location: '/quiz/subject/${session.config.subject.id}',
                  ),
                  icon: const Icon(Icons.list_alt_rounded),
                  label: Text(context.l10n.t('quizBackToTopics')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({required this.result});

  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: AppRadius.hero,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.surfaceContainerLowest],
        ),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.upperCase(context.l10n.t('quizScore')),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${result.correctCount} / ${result.totalQuestions}',
            key: const Key('quiz-result-score'),
            style: theme.textTheme.displaySmall?.copyWith(
              color: colors.onSurface,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            key: const Key('quiz-result-score-bar'),
            value: result.score,
            minHeight: 8,
            borderRadius: AppRadius.button,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${result.scorePercent}%  ·  ${context.l10n.t(_verdictKey(result))}',
            key: const Key('quiz-result-verdict'),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static String _verdictKey(QuizResult result) => switch (result.scorePercent) {
    >= 90 => 'quizResultExcellent',
    >= 60 => 'quizResultGood',
    _ => 'quizResultNeedsWork',
  };
}

class _Tally extends StatelessWidget {
  const _Tally({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      // Square edges, as in QuizFeedbackPanel: a left accent rule and a corner
      // radius cannot be painted together.
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          left: BorderSide(color: color, width: 4),
          top: BorderSide(color: theme.colorScheme.outlineVariant),
          right: BorderSide(color: theme.colorScheme.outlineVariant),
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

/// The reminders a session earned, e.g. an indefinite integral answered
/// correctly but without its constant of integration.
class _Notes extends StatelessWidget {
  const _Notes({required this.noteKeys, super.key});

  final List<String> noteKeys;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(
          left: BorderSide(color: colors.tertiary, width: 4),
          top: BorderSide(color: colors.outlineVariant),
          right: BorderSide(color: colors.outlineVariant),
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.upperCase(context.l10n.t('quizNote')),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          for (final noteKey in noteKeys)
            Text(context.l10n.t(noteKey), style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _AllCorrectNote extends StatelessWidget {
  const _AllCorrectNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: AppRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.t('quizAllCorrectTitle'),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            context.l10n.t('quizAllCorrectBody'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

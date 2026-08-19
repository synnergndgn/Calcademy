import 'package:calcademy/app/theme/app_radius.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The verdict shown after a graded answer, and the same block reused for each
/// entry on the review screen.
class QuizFeedbackPanel extends StatelessWidget {
  const QuizFeedbackPanel({
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
    this.noteKey,
    this.submittedAnswer,
    this.showVerdict = true,
    super.key,
  });

  final bool isCorrect;
  final String correctAnswer;

  /// Already resolved to the active locale by the caller, which is the only
  /// place that knows which question is on screen.
  final String explanation;

  /// Localization key for a reminder shown above the explanation, e.g. a
  /// correct antiderivative written without its constant of integration.
  final String? noteKey;

  /// Null when the answer is not worth echoing back, e.g. it was correct.
  final String? submittedAnswer;

  /// False in end-of-session mode, where the verdict is withheld until the
  /// result screen but the answer still needs acknowledging.
  final bool showVerdict;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = !showVerdict
        ? colors.outline
        : isCorrect
        ? colors.primary
        : colors.error;
    return Container(
      key: const Key('quiz-feedback-panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      // Square edges: a left accent rule is a non-uniform border, which
      // Flutter cannot paint together with a corner radius. The same trade is
      // what gives StudyHeader its ruled-margin look.
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(
          left: BorderSide(color: accent, width: 4),
          top: BorderSide(color: colors.outlineVariant),
          right: BorderSide(color: colors.outlineVariant),
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                !showVerdict
                    ? Icons.done_rounded
                    : isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: accent,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                context.l10n.t(
                  !showVerdict
                      ? 'quizAnswerRecorded'
                      : isCorrect
                      ? 'quizCorrect'
                      : 'quizIncorrect',
                ),
                key: const Key('quiz-feedback-verdict'),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (showVerdict) ...[
            if (submittedAnswer case final submittedAnswer?) ...[
              const SizedBox(height: AppSpacing.sm),
              _Line(
                label: context.l10n.t('quizYourAnswer'),
                value: submittedAnswer.isEmpty
                    ? context.l10n.t('quizNoAnswer')
                    : submittedAnswer,
                valueColor: colors.error,
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            _Line(
              label: context.l10n.t('quizCorrectAnswer'),
              value: correctAnswer,
              valueColor: colors.onSurface,
              valueKey: const Key('quiz-feedback-correct-answer'),
            ),
            // A note is part of the verdict, so end-of-session mode holds it
            // back with everything else rather than half-revealing a pass.
            if (noteKey case final noteKey?) ...[
              const SizedBox(height: AppSpacing.sm),
              _Note(noteKey: noteKey),
            ],
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.upperCase(context.l10n.t('quizExplanation')),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(explanation, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// The reminder that rides along with an answer that scored but was not
/// quite complete.
///
/// Set apart from the explanation rather than folded into it: it is about the
/// learner's own answer, not about the rule.
class _Note extends StatelessWidget {
  const _Note({required this.noteKey});

  final String noteKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      key: const Key('quiz-feedback-note'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: AppRadius.control,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: colors.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              context.l10n.t(noteKey),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    required this.valueColor,
    this.valueKey,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          key: valueKey,
          style: theme.textTheme.titleSmall?.copyWith(
            color: valueColor,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

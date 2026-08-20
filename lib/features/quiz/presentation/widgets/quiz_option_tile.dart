import 'package:calcademy/app/theme/app_radius.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/presentation/widgets/math_formula.dart';
import 'package:flutter/material.dart';

/// How an option should be painted once the question has been graded.
enum QuizOptionState { idle, selected, correct, incorrect }

class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    required this.option,
    required this.label,
    required this.state,
    this.onTap,
    super.key,
  });

  final QuizOption option;

  /// The A/B/C/D marker, derived from position rather than the option id so
  /// shuffling does not scramble the alphabet.
  final String label;
  final QuizOptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (background, border, foreground, icon) = switch (state) {
      QuizOptionState.idle => (
        colors.surfaceContainerLow,
        colors.outlineVariant,
        colors.onSurface,
        null,
      ),
      QuizOptionState.selected => (
        colors.primaryContainer,
        colors.primary,
        colors.onPrimaryContainer,
        null,
      ),
      QuizOptionState.correct => (
        colors.secondaryContainer,
        colors.primary,
        colors.onSecondaryContainer,
        Icons.check_circle_rounded,
      ),
      QuizOptionState.incorrect => (
        colors.errorContainer,
        colors.error,
        colors.onErrorContainer,
        Icons.cancel_rounded,
      ),
    };
    final emphasized =
        state == QuizOptionState.correct || state == QuizOptionState.incorrect;
    return Material(
      color: background,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(
              color: border,
              width: state == QuizOptionState.idle ? 1 : 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: AppRadius.button,
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: MathFormula(
                  option.text,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: emphasized ? FontWeight.w700 : null,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(icon, color: border),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:calcademy/app/theme/app_radius.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// The selection row used by the subject, topic, and mode screens.
///
/// One instrument-panel card shape shared by all three keeps the funnel
/// reading as a single flow rather than three unrelated lists.
class QuizChoiceCard extends StatelessWidget {
  const QuizChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.trailingText,
    this.selected = false,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final String? trailingText;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = selected ? colors.primary : colors.outlineVariant;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
        borderRadius: AppRadius.card,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadius.card,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.card,
              border: Border.all(color: accent, width: selected ? 2 : 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: AppRadius.control,
                  ),
                  child: Icon(
                    icon,
                    size: 21,
                    color: colors.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (trailingText case final trailingText?) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          trailingText,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (enabled) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    color: selected ? colors.primary : colors.outline,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

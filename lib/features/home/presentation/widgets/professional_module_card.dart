import 'package:calcademy/app/theme/app_radius.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/home/models/academy_module.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfessionalModuleCard extends StatelessWidget {
  const ProfessionalModuleCard({
    required this.module,
    this.compact = false,
    super.key,
  });

  final AcademyModule module;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = context.l10n.t(module.titleKey);
    final category = context.l10n.t(module.category.localizationKey);
    final actionLabel = context.l10n.t(
      module.available ? (compact ? 'open' : 'openModule') : 'comingSoon',
    );
    return Semantics(
      button: true,
      label: '$title, $category',
      child: Material(
        key: Key('module-card-${module.id}'),
        color: colors.surfaceContainerLowest,
        borderRadius: AppRadius.card,
        clipBehavior: Clip.hardEdge,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: module.available ? colors.primary : colors.outline,
                width: 3,
              ),
              bottom: BorderSide(color: colors.outlineVariant),
            ),
          ),
          child: InkWell(
            onTap: () => module.available
                ? context.push(module.route!)
                : context.push('/coming-soon/${module.id}'),
            child: Padding(
              padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: compact ? 40 : 48,
                        height: compact ? 40 : 48,
                        decoration: BoxDecoration(
                          color: module.available
                              ? colors.primaryContainer.withValues(alpha: 0.75)
                              : colors.surfaceContainerHighest,
                          borderRadius: AppRadius.button,
                        ),
                        child: Icon(
                          module.icon,
                          color: module.available
                              ? colors.onPrimaryContainer
                              : colors.onSurfaceVariant,
                        ),
                      ),
                      if (!compact) ...[
                        const Spacer(),
                        _CategoryBadge(label: category),
                      ],
                    ],
                  ),
                  SizedBox(height: compact ? AppSpacing.xs : AppSpacing.md),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: compact
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.t(module.descriptionKey),
                    maxLines: compact ? 2 : null,
                    overflow: compact ? TextOverflow.ellipsis : null,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: compact ? AppSpacing.xs : AppSpacing.md),
                  if (compact)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            actionLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: module.available
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          module.available
                              ? Icons.arrow_forward_rounded
                              : Icons.schedule_rounded,
                          size: 18,
                          color: module.available
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: colors.outlineVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          module.available
                              ? Icons.arrow_forward_rounded
                              : Icons.schedule_rounded,
                          size: 18,
                          color: module.available
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            actionLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: module.available
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxs),
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

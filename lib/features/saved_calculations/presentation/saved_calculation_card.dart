import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class SavedCalculationCard extends StatelessWidget {
  const SavedCalculationCard({
    super.key,
    required this.item,
    required this.onCopy,
    required this.onFavorite,
    required this.onDelete,
    required this.onOpenSavedItem,
  });

  final SavedCalculation item;
  final VoidCallback onCopy;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;
  final VoidCallback? onOpenSavedItem;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final material = MaterialLocalizations.of(context);
    final localDate = item.createdAt.toLocal();
    final timestamp =
        '${material.formatCompactDate(localDate)} '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(localDate))}';
    return Card(
      key: ValueKey('saved-card-${item.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        timestamp,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: ValueKey('saved-favorite-${item.id}'),
                  tooltip: l10n.t(
                    item.isFavorite ? 'savedUnfavorite' : 'savedFavorite',
                  ),
                  onPressed: onFavorite,
                  icon: Icon(
                    item.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.extension_rounded, size: 16),
                  label: Text(l10n.t(item.module.titleKey)),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(item.calculationType),
                ),
              ],
            ),
            if (item.inputSummary.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.inputSummary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: SelectableText(item.resultSummary, maxLines: 5),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: [
                if (onOpenSavedItem != null)
                  TextButton.icon(
                    key: ValueKey('saved-open-${item.id}'),
                    onPressed: onOpenSavedItem,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(l10n.t('savedOpenItem')),
                  ),
                TextButton.icon(
                  key: ValueKey('saved-copy-${item.id}'),
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(l10n.t('copyResult')),
                ),
                TextButton.icon(
                  key: ValueKey('saved-delete-${item.id}'),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(l10n.t('delete')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

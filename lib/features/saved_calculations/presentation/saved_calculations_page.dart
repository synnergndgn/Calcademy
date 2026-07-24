import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/empty_state.dart';
import 'package:calcademy/features/saved_calculations/application/saved_calculation_restore.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_failure.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_limits.dart';
import 'package:calcademy/features/saved_calculations/presentation/save_result_action.dart';
import 'package:calcademy/features/saved_calculations/presentation/saved_calculation_card.dart';
import 'package:calcademy/features/saved_calculations/presentation/saved_calculations_controller.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SavedCalculationsPage extends ConsumerWidget {
  const SavedCalculationsPage({
    super.key,
    this.embedded = false,
    this.footer,
    this.suppressEmptyState = false,
  });

  final bool embedded;
  final Widget? footer;
  final bool suppressEmptyState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savedCalculationsProvider);
    final controller = ref.read(savedCalculationsProvider.notifier);
    final items = state.error == null ? controller.visibleItems : const [];
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final showStatus =
        state.error != null || (items.isEmpty && !suppressEmptyState);
    final content = SafeArea(
      top: false,
      child: ListView.builder(
        key: const Key('saved-calculations-list'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg + bottomInset,
        ),
        itemCount:
            1 + (showStatus ? 1 : items.length) + (footer == null ? 0 : 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _SavedFilters(state: state);
          }
          if (showStatus) {
            if (index == 1) {
              if (state.error case final SavedCalculationsIssue error) {
                return EmptyState(
                  icon: Icons.storage_rounded,
                  title: context.l10n.t('savedLoadFailed'),
                  body: context.l10n.t(savedIssueKey(error)),
                  action: FilledButton.icon(
                    onPressed: controller.reload,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.l10n.t('retry')),
                  ),
                );
              }
              final filtered = state.items.isNotEmpty;
              return EmptyState(
                icon: filtered
                    ? Icons.search_off_rounded
                    : Icons.bookmarks_outlined,
                title: context.l10n.t(
                  filtered ? 'savedNoResults' : 'savedEmptyTitle',
                ),
                body: context.l10n.t(
                  filtered ? 'savedNoResultsBody' : 'savedEmptyBody',
                ),
              );
            }
            return footer!;
          }
          if (index > items.length) return footer!;
          final item = items[index - 1];
          final restoreRoute = savedCalculationRestoreRoute(item);
          return SavedCalculationCard(
            item: item,
            onCopy: () async {
              await Clipboard.setData(ClipboardData(text: item.resultSummary));
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(context.l10n.t('copied'))));
            },
            onFavorite: () =>
                _runAction(context, () => controller.toggleFavorite(item.id)),
            onDelete: () => _confirmDelete(context, ref, item.id),
            onOpenSavedItem: restoreRoute == null
                ? null
                : () => context.push(restoreRoute),
          );
        },
      ),
    );
    if (embedded) return content;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.t('saved')),
        actions: [
          IconButton(
            key: const Key('saved-clear-all'),
            tooltip: context.l10n.t('savedClearAll'),
            onPressed: state.items.isEmpty
                ? null
                : () => _confirmClear(context, ref),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: content,
    );
  }

  static Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.t('savedDeleteTitle')),
        content: Text(dialogContext.l10n.t('savedDeleteBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.t('cancel')),
          ),
          FilledButton(
            key: const Key('saved-confirm-delete'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.t('delete')),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _runAction(
        context,
        () => ref.read(savedCalculationsProvider.notifier).delete(id),
      );
    }
  }

  static Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.t('savedClearTitle')),
        content: Text(dialogContext.l10n.t('savedClearBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.t('cancel')),
          ),
          FilledButton(
            key: const Key('saved-confirm-clear'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.t('savedClearAll')),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _runAction(
        context,
        ref.read(savedCalculationsProvider.notifier).clear,
      );
    }
  }

  static Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on SavedCalculationsException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t(savedIssueKey(error.issue)))),
      );
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('savedErrorStorageWrite'))),
      );
    }
  }
}

class _SavedFilters extends ConsumerWidget {
  const _SavedFilters({required this.state});

  final SavedCalculationsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(savedCalculationsProvider.notifier);
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('saved-search'),
            maxLength: SavedCalculationsLimits.maxSearchQueryLength,
            decoration: InputDecoration(
              labelText: l10n.t('savedSearch'),
              prefixIcon: const Icon(Icons.search_rounded),
              counterText: '',
            ),
            onChanged: controller.setQuery,
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<SavedCalculationsScope>(
              key: const Key('saved-scope-filter'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: SavedCalculationsScope.all,
                  label: Text(l10n.t('savedAll')),
                ),
                ButtonSegment(
                  value: SavedCalculationsScope.favorites,
                  label: Text(l10n.t('savedFavorites')),
                ),
              ],
              selected: {state.scope},
              onSelectionChanged: (selection) =>
                  controller.setScope(selection.first),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final module = _moduleFilter(context, controller);
              final sort = _sortFilter(context, controller);
              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    module,
                    const SizedBox(height: AppSpacing.sm),
                    sort,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: module),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: sort),
                ],
              );
            },
          ),
          if (state.skippedItemCount > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.t('savedCorruptItemsSkipped'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _moduleFilter(
    BuildContext context,
    SavedCalculationsController controller,
  ) => DropdownButtonFormField<SavedCalculationModule?>(
    key: const Key('saved-module-filter'),
    initialValue: state.module,
    isExpanded: true,
    decoration: InputDecoration(labelText: context.l10n.t('savedModule')),
    items: [
      DropdownMenuItem(
        value: null,
        child: Text(context.l10n.t('savedAllModules')),
      ),
      for (final module in SavedCalculationModule.values)
        if (module != SavedCalculationModule.unknown)
          DropdownMenuItem(
            value: module,
            child: Text(context.l10n.t(module.titleKey)),
          ),
    ],
    onChanged: controller.setModule,
  );

  Widget _sortFilter(
    BuildContext context,
    SavedCalculationsController controller,
  ) => DropdownButtonFormField<SavedCalculationsSort>(
    key: const Key('saved-sort'),
    initialValue: state.sort,
    isExpanded: true,
    decoration: InputDecoration(labelText: context.l10n.t('savedSort')),
    items: [
      DropdownMenuItem(
        value: SavedCalculationsSort.newestFirst,
        child: Text(context.l10n.t('savedNewestFirst')),
      ),
      DropdownMenuItem(
        value: SavedCalculationsSort.oldestFirst,
        child: Text(context.l10n.t('savedOldestFirst')),
      ),
      DropdownMenuItem(
        value: SavedCalculationsSort.favoritesFirst,
        child: Text(context.l10n.t('savedFavoritesFirst')),
      ),
    ],
    onChanged: (value) {
      if (value != null) controller.setSort(value);
    },
  );
}

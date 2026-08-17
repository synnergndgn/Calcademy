import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/calcademy_design.dart';
import 'package:calcademy/features/history/domain/calculation_record.dart';
import 'package:calcademy/features/history/presentation/history_controller.dart';
import 'package:calcademy/features/saved/presentation/saved_controller.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(historyProvider);
    final normalizedQuery = query.trim().toLowerCase();
    final filtered = records
        .where(
          (item) =>
              item.expression.toLowerCase().contains(normalizedQuery) ||
              item.result.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
    final groups = <String, List<CalculationRecord>>{};
    for (final record in filtered) {
      groups.putIfAbsent(_groupLabel(record.createdAt), () => []).add(record);
    }
    return CalcademyScaffold(
      title: Text(context.l10n.t('history')),
      actions: [
        IconButton(
          tooltip: context.l10n.t('clearHistory'),
          onPressed: records.isEmpty ? null : _confirmClear,
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/calculator'),
        icon: const Icon(Icons.calculate_rounded),
        label: Text(context.l10n.t('calculator')),
      ),
      body: records.isEmpty
          ? EmptyStateIllustration(
              icon: Icons.history_toggle_off_rounded,
              title: context.l10n.t('noHistory'),
              body: context.l10n.t('noHistoryBody'),
            )
          : SafeArea(
              top: false,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search_rounded),
                          hintText: context.l10n.t('searchHistory'),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: context.l10n.t('clear'),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => query = '');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                        onChanged: (value) => setState(() => query = value),
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateIllustration(
                        icon: Icons.search_off_rounded,
                        title: context.l10n.t('homeNoResultsTitle'),
                        body: context.l10n.t('homeNoResultsBody'),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        96,
                      ),
                      sliver: SliverList.list(
                        children: [
                          for (final group in groups.entries) ...[
                            SectionLabel(
                              title: group.key,
                              icon: Icons.schedule_rounded,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            for (
                              var index = 0;
                              index < group.value.length;
                              index++
                            )
                              _HistoryTimelineEntry(
                                record: group.value[index],
                                isLast: index == group.value.length - 1,
                              ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  String _groupLabel(DateTime date) {
    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return context.l10n.t('today');
    if (day == today.subtract(const Duration(days: 1))) {
      return context.l10n.t('yesterday');
    }
    if (today.difference(day).inDays < 7) {
      return context.l10n.t('thisWeek');
    }
    return context.l10n.t('older');
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('clearHistory')),
        content: Text(context.l10n.t('clearHistoryQuestion')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.t('clear')),
          ),
        ],
      ),
    );
    if (confirmed == true) await ref.read(historyProvider.notifier).clear();
  }
}

class _HistoryTimelineEntry extends ConsumerWidget {
  const _HistoryTimelineEntry({required this.record, required this.isLast});

  final CalculationRecord record;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route =
        '/calculator?expression=${Uri.encodeQueryComponent(record.expression)}';
    return TimelineCalculationItem(
      expression: record.expression,
      result: record.result,
      metadata:
          '${DateFormat.Hm().format(record.createdAt)} · '
          '${record.angleMode.name == 'degrees' ? 'DEG' : 'RAD'}',
      isLast: isLast,
      onTap: () => context.push(route),
      actions: [
        IconButton(
          tooltip: context.l10n.t('reuse'),
          onPressed: () => context.push(route),
          icon: const Icon(Icons.replay_rounded, size: 20),
        ),
        IconButton(
          tooltip: context.l10n.t('save'),
          onPressed: record.isSaved
              ? null
              : () => ref.read(savedProvider.notifier).addFromRecord(record),
          icon: Icon(
            record.isSaved
                ? Icons.bookmark_rounded
                : Icons.bookmark_add_outlined,
            size: 20,
          ),
        ),
        IconButton(
          tooltip: context.l10n.t('delete'),
          onPressed: () => ref.read(historyProvider.notifier).remove(record.id),
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
        ),
      ],
    );
  }
}

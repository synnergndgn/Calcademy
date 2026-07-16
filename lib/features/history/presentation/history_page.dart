import 'package:calcademy/core/widgets/empty_state.dart';
import 'package:calcademy/features/history/domain/calculation_record.dart';
import 'package:calcademy/features/history/presentation/history_controller.dart';
import 'package:calcademy/features/saved/presentation/saved_controller.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(historyProvider);
    final filtered = records
        .where(
          (item) =>
              item.expression.toLowerCase().contains(query.toLowerCase()) ||
              item.result.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    final groups = <String, List<CalculationRecord>>{};
    for (final record in filtered) {
      groups.putIfAbsent(_groupLabel(record.createdAt), () => []).add(record);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.t('history')),
        actions: [
          IconButton(
            tooltip: context.l10n.t('clearHistory'),
            onPressed: records.isEmpty ? null : _confirmClear,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: records.isEmpty
          ? EmptyState(
              icon: Icons.history_toggle_off_rounded,
              title: context.l10n.t('noHistory'),
              body: context.l10n.t('noHistoryBody'),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: context.l10n.t('searchHistory'),
                    ),
                    onChanged: (value) => setState(() => query = value),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      for (final group in groups.entries) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                          child: Text(
                            group.key,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Card(
                          child: Column(
                            children: [
                              for (final record in group.value)
                                _HistoryTile(record: record),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/calculator'),
        icon: const Icon(Icons.calculate_rounded),
        label: Text(context.l10n.t('calculator')),
      ),
    );
  }

  String _groupLabel(DateTime date) {
    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) {
      return context.l10n.t('today');
    }
    if (day == today.subtract(const Duration(days: 1))) {
      return context.l10n.t('yesterday');
    }
    return DateFormat.yMMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date);
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
    if (confirmed == true) {
      await ref.read(historyProvider.notifier).clear();
    }
  }
}

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.record});
  final CalculationRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      onTap: () => context.push(
        '/calculator?expression=${Uri.encodeQueryComponent(record.expression)}',
      ),
      title: Text(
        record.expression,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '= ${record.result}  •  ${DateFormat.Hm().format(record.createdAt)}  •  ${record.angleMode.name == 'degrees' ? 'DEG' : 'RAD'}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'reuse') {
            context.push(
              '/calculator?expression=${Uri.encodeQueryComponent(record.expression)}',
            );
          }
          if (value == 'copy') {
            await Clipboard.setData(
              ClipboardData(text: '${record.expression} = ${record.result}'),
            );
          }
          if (value == 'save') {
            await ref.read(savedProvider.notifier).addFromRecord(record);
          }
          if (value == 'delete') {
            await ref.read(historyProvider.notifier).remove(record.id);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'reuse', child: Text(context.l10n.t('reuse'))),
          PopupMenuItem(
            value: 'copy',
            child: Text(context.l10n.t('copyResult')),
          ),
          PopupMenuItem(
            value: 'save',
            enabled: !record.isSaved,
            child: Text(context.l10n.t('save')),
          ),
          PopupMenuItem(value: 'delete', child: Text(context.l10n.t('delete'))),
        ],
      ),
    );
  }
}

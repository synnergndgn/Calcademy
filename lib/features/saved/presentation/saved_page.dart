import 'package:calcademy/core/widgets/empty_state.dart';
import 'package:calcademy/features/history/domain/saved_calculation.dart';
import 'package:calcademy/features/saved/presentation/saved_controller.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SavedPage extends ConsumerWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(savedProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.t('saved'))),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.bookmark_border_rounded,
              title: context.l10n.t('noSaved'),
              body: context.l10n.t('noSavedBody'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) => _SavedCard(item: items[index]),
            ),
    );
  }
}

class _SavedCard extends ConsumerWidget {
  const _SavedCard({required this.item});
  final SavedCalculation item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.t('edit'),
                  onPressed: () => _edit(context, ref),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: context.l10n.t('delete'),
                  onPressed: () =>
                      ref.read(savedProvider.notifier).remove(item.id),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            Text(item.expression),
            const SizedBox(height: 4),
            Text(
              '= ${item.result}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (item.note?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(item.note!),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat.yMMMd(
                      Localizations.localeOf(context).toLanguageTag(),
                    ).add_Hm().format(item.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push(
                    '/calculator?expression=${Uri.encodeQueryComponent(item.expression)}',
                  ),
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(context.l10n.t('reuse')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController(text: item.title);
    final note = TextEditingController(text: item.note);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('editSaved')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: InputDecoration(labelText: context.l10n.t('title')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: InputDecoration(labelText: context.l10n.t('note')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.t('save')),
          ),
        ],
      ),
    );
    if (confirmed == true && title.text.trim().isNotEmpty) {
      await ref
          .read(savedProvider.notifier)
          .update(item.id, title.text, note.text);
    }
    title.dispose();
    note.dispose();
  }
}

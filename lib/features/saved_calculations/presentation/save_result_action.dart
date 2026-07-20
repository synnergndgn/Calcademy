import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_failure.dart';
import 'package:calcademy/features/saved_calculations/presentation/saved_calculations_controller.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SaveResultAction extends ConsumerStatefulWidget {
  const SaveResultAction({super.key, required this.draft, this.buttonKey});

  final SavedCalculationDraft draft;
  final Key? buttonKey;

  @override
  ConsumerState<SaveResultAction> createState() => _SaveResultActionState();
}

class _SaveResultActionState extends ConsumerState<SaveResultAction> {
  var _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(savedCalculationsProvider.notifier).save(widget.draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('savedCalculationSaved'))),
      );
    } on SavedCalculationsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t(savedIssueKey(error.issue)))),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('savedErrorStorageWrite'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    key: widget.buttonKey,
    onPressed: _saving ? null : _save,
    icon: _saving
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.bookmark_add_outlined, size: 18),
    label: Text(context.l10n.t('saveResult')),
  );
}

String savedIssueKey(SavedCalculationsIssue issue) => switch (issue) {
  SavedCalculationsIssue.storageRead => 'savedErrorStorageRead',
  SavedCalculationsIssue.storageWrite => 'savedErrorStorageWrite',
  SavedCalculationsIssue.invalidSchema => 'savedErrorInvalidSchema',
  SavedCalculationsIssue.invalidPayload => 'savedErrorInvalidPayload',
  SavedCalculationsIssue.itemLimit => 'savedErrorItemLimit',
  SavedCalculationsIssue.titleTooLong => 'savedErrorTitleLength',
  SavedCalculationsIssue.summaryTooLong => 'savedErrorSummaryLength',
  SavedCalculationsIssue.payloadTooLarge => 'savedErrorPayloadSize',
  SavedCalculationsIssue.searchQueryTooLong => 'savedErrorSearchLength',
  SavedCalculationsIssue.unknownModule => 'savedErrorUnknownModule',
};

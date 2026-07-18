import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/integer_programming/data/integer_program_repository.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program_examples.dart';
import 'package:calcademy/features/integer_programming/domain/mip_result.dart';
import 'package:calcademy/features/integer_programming/domain/saved_integer_program.dart';
import 'package:calcademy/features/integer_programming/presentation/integer_model_editor_page.dart';
import 'package:calcademy/features/integer_programming/presentation/integer_program_controller.dart';
import 'package:calcademy/features/integer_programming/presentation/integer_program_draft.dart';
import 'package:calcademy/features/integer_programming/presentation/integer_solution_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The `/integer-programming` route: welcome text, ready-made templates,
/// the model editor, and the solution report, all on one scrollable page -
/// the same single-page workspace shape the linear programming module
/// already uses, so the two optimization modules feel like one family.
class IntegerProgramHomePage extends ConsumerStatefulWidget {
  const IntegerProgramHomePage({super.key, this.savedId});

  final String? savedId;

  @override
  ConsumerState<IntegerProgramHomePage> createState() =>
      _IntegerProgramHomePageState();
}

class _IntegerProgramHomePageState
    extends ConsumerState<IntegerProgramHomePage> {
  late IntegerProgramDraft _draft;
  final _dirty = ValueNotifier(false);
  String? _activeSavedId;

  @override
  void initState() {
    super.initState();
    final saved = widget.savedId == null
        ? null
        : ref.read(savedIntegerProgramsProvider.notifier).find(widget.savedId!);
    _draft = saved == null
        ? IntegerProgramDraft()
        : IntegerProgramDraft.fromProgram(saved.program);
    _activeSavedId = saved?.id;
    if (saved != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(integerProgramWorkspaceProvider.notifier)
            .solve(saved.program, savedId: saved.id);
      });
    }
  }

  @override
  void dispose() {
    _draft.dispose();
    _dirty.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty.value) _dirty.value = true;
  }

  void _replaceDraft(IntegerProgram program) {
    _draft.dispose();
    _draft = IntegerProgramDraft.fromProgram(program);
    _dirty.value = true;
    _activeSavedId = null;
    ref.read(integerProgramWorkspaceProvider.notifier).clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('integerProgramming'))),
      // On tablets and desktop widths the editor's fixed-width coefficient
      // cells would leave a lot of dead space if the cards stretched
      // edge-to-edge, so the whole workspace is centred inside a bounded
      // column; phones are unaffected (the constraint is wider than any
      // phone viewport).
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                l10n.t('mipWelcome'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.t('mipWelcomeBody')),
              const SizedBox(height: AppSpacing.md),
              _Templates(onSelect: _replaceDraft),
              const SizedBox(height: AppSpacing.md),
              IntegerModelEditor(
                draft: _draft,
                onChanged: _markDirty,
                onSolve: _solve,
              ),
              const SizedBox(height: AppSpacing.md),
              ValueListenableBuilder<bool>(
                valueListenable: _dirty,
                builder: (context, dirty, _) => IntegerSolutionPanel(
                  dirty: dirty,
                  activeSavedId: _activeSavedId,
                  onSave: _save,
                  onNew: _new,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _solve() async {
    try {
      final program = _draft.buildProgram();
      _dirty.value = false;
      await ref
          .read(integerProgramWorkspaceProvider.notifier)
          .solve(program, savedId: _activeSavedId);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('mipInvalidInput'))),
      );
    }
  }

  Future<void> _save(
    IntegerProgram program,
    MipResult result, {
    bool copy = false,
  }) async {
    final title = TextEditingController(text: program.title);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('lpSaveModel')),
        content: TextField(
          controller: title,
          decoration: InputDecoration(
            labelText: context.l10n.t('lpModelTitle'),
          ),
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
      final now = DateTime.now();
      final id = !copy && _activeSavedId != null
          ? _activeSavedId!
          : now.microsecondsSinceEpoch.toString();
      await ref
          .read(savedIntegerProgramsProvider.notifier)
          .upsert(
            SavedIntegerProgram(
              id: id,
              title: title.text.trim(),
              program: program,
              result: MipResultSummary.fromResult(result),
              createdAt: now,
              updatedAt: now,
            ),
          );
      _activeSavedId = id;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.t('mipSaved'))));
      }
    }
    title.dispose();
  }

  void _new() {
    _draft.dispose();
    _draft = IntegerProgramDraft();
    _activeSavedId = null;
    _dirty.value = false;
    ref.read(integerProgramWorkspaceProvider.notifier).clear();
    setState(() {});
  }
}

class _Templates extends StatelessWidget {
  const _Templates({required this.onSelect});
  final ValueChanged<IntegerProgram> onSelect;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.t('mipTemplates'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (
                var index = 0;
                index < IntegerProgramExamples.all.length;
                index++
              )
                ActionChip(
                  label: Text(context.l10n.t('mipExample$index')),
                  onPressed: () => onSelect(IntegerProgramExamples.all[index]),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

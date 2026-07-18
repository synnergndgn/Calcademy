// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/linear_programming/data/linear_program_repository.dart';
import 'package:calcademy/features/linear_programming/domain/dual_builder.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program_result.dart';
import 'package:calcademy/features/linear_programming/domain/lp_constants.dart';
import 'package:calcademy/features/linear_programming/domain/lp_examples.dart';
import 'package:calcademy/features/linear_programming/domain/saved_linear_program.dart';
import 'package:calcademy/features/linear_programming/domain/standard_form.dart';
import 'package:calcademy/features/linear_programming/presentation/linear_program_controller.dart';
import 'package:calcademy/features/linear_programming/presentation/linear_program_draft.dart';
import 'package:calcademy/features/linear_programming/presentation/lp_graph_view.dart';
import 'package:calcademy/features/linear_programming/presentation/simplex_steps_page.dart';
import 'package:calcademy/features/optimization/presentation/widgets/constraint_relation_options.dart';
import 'package:calcademy/features/optimization/presentation/widgets/responsive_constraint_card.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LinearProgramPage extends ConsumerStatefulWidget {
  const LinearProgramPage({super.key, this.savedId});
  final String? savedId;

  @override
  ConsumerState<LinearProgramPage> createState() => _LinearProgramPageState();
}

class _LinearProgramPageState extends ConsumerState<LinearProgramPage> {
  late LinearProgramDraft _draft;
  final _dirty = ValueNotifier(false);
  String? _activeSavedId;

  @override
  void initState() {
    super.initState();
    final saved = widget.savedId == null
        ? null
        : ref.read(savedLinearProgramsProvider.notifier).find(widget.savedId!);
    _draft = saved == null
        ? LinearProgramDraft()
        : LinearProgramDraft.fromProgram(saved.program);
    _activeSavedId = saved?.id;
    if (saved != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(linearProgramWorkspaceProvider.notifier)
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

  void _replaceDraft(LinearProgram program) {
    _draft.dispose();
    _draft = LinearProgramDraft.fromProgram(program);
    _dirty.value = true;
    _activeSavedId = null;
    ref.read(linearProgramWorkspaceProvider.notifier).clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.t('linearProgramming'))),
    // Same bounded-width workspace as the integer programming editor so
    // the two optimization modules keep one layout language on tablets.
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              context.l10n.t('lpWelcome'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(context.l10n.t('lpWelcomeBody')),
            const SizedBox(height: AppSpacing.md),
            _Examples(onSelect: _replaceDraft),
            const SizedBox(height: AppSpacing.md),
            _buildEditor(context),
            const SizedBox(height: AppSpacing.md),
            ValueListenableBuilder<bool>(
              valueListenable: _dirty,
              builder: (context, dirty, _) => _ResultPanel(
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

  Widget _buildEditor(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.t('lpNewModel'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('lp-title'),
            controller: _draft.title,
            onChanged: (_) => _markDirty(),
            decoration: InputDecoration(
              labelText: context.l10n.t('lpModelTitle'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<ObjectiveDirection>(
              segments: [
                ButtonSegment(
                  value: ObjectiveDirection.maximize,
                  label: Text(context.l10n.t('lpMaximize')),
                ),
                ButtonSegment(
                  value: ObjectiveDirection.minimize,
                  label: Text(context.l10n.t('lpMinimize')),
                ),
              ],
              selected: {_draft.direction},
              onSelectionChanged: (value) => setState(() {
                _draft.direction = value.first;
                _markDirty();
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${context.l10n.t('lpVariables')}: ${_draft.variableCount}',
                ),
              ),
              IconButton(
                tooltip: context.l10n.t('lpRemoveVariable'),
                onPressed: _draft.variableCount <= 1
                    ? null
                    : () => setState(() {
                        _draft.setVariableCount(_draft.variableCount - 1);
                        _markDirty();
                      }),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              IconButton(
                tooltip: context.l10n.t('lpAddVariable'),
                onPressed: _draft.variableCount >= LpConstants.maxVariables
                    ? null
                    : () => setState(() {
                        _draft.setVariableCount(_draft.variableCount + 1);
                        _markDirty();
                      }),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          Text(
            context.l10n.t('lpNonnegativeNotice'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < _draft.variableCount; index++)
                  SizedBox(
                    width: 112,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          TextField(
                            controller: _draft.variableNames[index],
                            onChanged: (_) => _markDirty(),
                            decoration: InputDecoration(
                              labelText:
                                  '${context.l10n.t('lpVariable')} ${index + 1}',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            key: Key('lp-objective-$index'),
                            controller: _draft.objective[index],
                            onChanged: (_) => _markDirty(),
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText:
                                  '${context.l10n.t('lpObjective')} c${index + 1}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.t('lpConstraints'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${_draft.constraints.length}/${LpConstants.maxConstraints}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (var index = 0; index < _draft.constraints.length; index++)
            _buildConstraintCard(context, index),
          FilledButton.tonalIcon(
            key: const Key('lp-add-constraint'),
            onPressed: _draft.constraints.length >= LpConstants.maxConstraints
                ? null
                : () => setState(() {
                    _draft.addConstraint();
                    _markDirty();
                  }),
            icon: const Icon(Icons.add),
            label: Text(context.l10n.t('lpAddConstraint')),
          ),
          ExpansionTile(
            title: Text(context.l10n.t('lpSummary')),
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_summaryText()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            key: const Key('lp-solve'),
            onPressed: _solve,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(context.l10n.t('lpSolve')),
          ),
        ],
      ),
    ),
  );

  Widget _buildConstraintCard(BuildContext context, int index) {
    final l10n = context.l10n;
    final draft = _draft.constraints[index];
    return ResponsiveConstraintCard<ConstraintRelation>(
      key: ValueKey(draft.id),
      title: '${l10n.t('constraintLabel')} ${index + 1}',
      variableLabels: [for (final name in _draft.variableNames) name.text],
      coefficientControllers: draft.coefficients,
      coefficientCellKeys: [
        for (var i = 0; i < draft.coefficients.length; i++)
          Key('lp-cell-${draft.id}-$i'),
      ],
      relation: draft.relation,
      relationOptions: constraintRelationOptions(l10n),
      onRelationChanged: (value) => setState(() {
        draft.relation = value;
        _markDirty();
      }),
      rhsController: draft.rhs,
      rhsFieldKey: Key('lp-rhs-${draft.id}'),
      relationFieldKey: Key('lp-relation-${draft.id}'),
      nameController: draft.name,
      relationLabel: l10n.t('relationLabel'),
      rhsLabel: l10n.t('rhsLabel'),
      nameLabel: l10n.t('lpConstraintName'),
      onChanged: _markDirty,
      deleteTooltip: l10n.t('delete'),
      onDelete: _draft.constraints.length == 1
          ? null
          : () => setState(() {
              _draft.removeConstraint(index);
              _markDirty();
            }),
      copyTooltip: l10n.t('lpCopyConstraint'),
      onCopy: _draft.constraints.length >= LpConstants.maxConstraints
          ? null
          : () => setState(() {
              _draft.constraints.insert(
                index + 1,
                _draft.constraints[index].copy(index + 1),
              );
              _markDirty();
            }),
      moveUpTooltip: l10n.t('lpMoveUp'),
      onMoveUp: index == 0
          ? null
          : () => setState(() {
              final item = _draft.constraints.removeAt(index);
              _draft.constraints.insert(index - 1, item);
              _markDirty();
            }),
      moveDownTooltip: l10n.t('lpMoveDown'),
      onMoveDown: index == _draft.constraints.length - 1
          ? null
          : () => setState(() {
              final item = _draft.constraints.removeAt(index);
              _draft.constraints.insert(index + 1, item);
              _markDirty();
            }),
    );
  }

  String _summaryText() {
    try {
      final program = _draft.buildProgram();
      final sign = program.direction == ObjectiveDirection.maximize
          ? 'max'
          : 'min';
      final objective = [
        for (var i = 0; i < program.objective.length; i++)
          '${formatLpNumber(program.objective[i])}${program.variables[i].name}',
      ].join(' + ');
      return '$sign z = $objective\n${program.constraints.length} ${context.l10n.t('lpConstraints').toLowerCase()} · ${context.l10n.t('lpNonnegativeShort')}';
    } on Object {
      return context.l10n.t('lpInvalidInput');
    }
  }

  Future<void> _solve() async {
    try {
      final program = _draft.buildProgram();
      _dirty.value = false;
      await ref
          .read(linearProgramWorkspaceProvider.notifier)
          .solve(program, savedId: _activeSavedId);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.t('lpInvalidInput'))));
    }
  }

  Future<void> _save(
    LinearProgram program,
    LinearProgramResult result, {
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
      final feasible = result is FeasibleLinearProgramResult ? result : null;
      final id = !copy && _activeSavedId != null
          ? _activeSavedId!
          : now.microsecondsSinceEpoch.toString();
      await ref
          .read(savedLinearProgramsProvider.notifier)
          .upsert(
            SavedLinearProgram(
              id: id,
              title: title.text.trim(),
              program: program,
              status: result.status,
              objectiveValue: feasible?.objectiveValue,
              createdAt: now,
              updatedAt: now,
            ),
          );
      _activeSavedId = id;
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.t('lpSaved'))));
    }
    title.dispose();
  }

  void _new() {
    _draft.dispose();
    _draft = LinearProgramDraft();
    _activeSavedId = null;
    _dirty.value = false;
    ref.read(linearProgramWorkspaceProvider.notifier).clear();
    setState(() {});
  }
}

class _Examples extends StatelessWidget {
  const _Examples({required this.onSelect});
  final ValueChanged<LinearProgram> onSelect;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.t('lpExamples'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < LpExamples.all.length; index++)
                ActionChip(
                  label: Text(context.l10n.t('lpExample$index')),
                  onPressed: () => onSelect(LpExamples.all[index]),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ResultPanel extends ConsumerWidget {
  const _ResultPanel({
    required this.dirty,
    required this.activeSavedId,
    required this.onSave,
    required this.onNew,
  });
  final bool dirty;
  final String? activeSavedId;
  final Future<void> Function(LinearProgram, LinearProgramResult, {bool copy})
  onSave;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(
      linearProgramWorkspaceProvider.select((state) => state.loading),
    );
    final result = ref.watch(
      linearProgramWorkspaceProvider.select((state) => state.result),
    );
    final program = ref.watch(
      linearProgramWorkspaceProvider.select((state) => state.program),
    );
    final error = ref.watch(
      linearProgramWorkspaceProvider.select((state) => state.error),
    );
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null)
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(context.l10n.t('lpNumericError')),
        ),
      );
    if (result == null || program == null) return const SizedBox.shrink();
    if (dirty)
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(context.l10n.t('lpResultStale')),
        ),
      );
    final feasible = result is FeasibleLinearProgramResult ? result : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.t('lpResult'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              context.l10n.t('lpStatus${result.status.name}'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              '${context.l10n.t('lpMethod')}: ${context.l10n.t(result.method == SimplexMethod.primal ? 'lpPrimal' : 'lpTwoPhase')}',
            ),
            Text('${context.l10n.t('lpIterations')}: ${result.iterationCount}'),
            if (feasible != null) ...[
              const Divider(),
              Text(
                'z = ${formatLpNumber(feasible.objectiveValue)}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              for (final entry in feasible.variableValues.entries)
                Text('${entry.key} = ${formatLpNumber(entry.value)}'),
              const SizedBox(height: 8),
              Text(
                context.l10n.t('lpConstraintAnalysis'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final item in feasible.constraintAnalysis)
                Text(
                  '${item.name}: ${item.active ? context.l10n.t('lpActive') : context.l10n.t('lpInactive')} · ${context.l10n.t('lpSlackSurplus')} ${formatLpNumber(item.slackOrSurplus)}',
                ),
              Text(
                '${context.l10n.t('lpBasicVariables')}: ${feasible.basicVariables.join(', ')}',
              ),
              Text(
                '${context.l10n.t('lpDegenerate')}: ${feasible.degenerate ? context.l10n.t('yes') : context.l10n.t('no')}',
              ),
              ExpansionTile(
                title: Text(context.l10n.t('lpSensitivity')),
                children: [
                  for (final entry in feasible.reducedCosts.entries)
                    ListTile(
                      dense: true,
                      title: Text(entry.key),
                      trailing: Text(
                        '${context.l10n.t('lpReducedCost')}: ${formatLpNumber(entry.value)}',
                      ),
                    ),
                  ListTile(
                    dense: true,
                    title: Text(context.l10n.t('lpSensitivityNotice')),
                  ),
                ],
              ),
              if (program.variables.length == 2) ...[
                Text(
                  context.l10n.t('lpGraphicalSolution'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                LpGraphView(program: program),
              ],
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SimplexStepsPage(result: result),
                    ),
                  ),
                  icon: const Icon(Icons.table_chart),
                  label: Text(context.l10n.t('lpSteps')),
                ),
                OutlinedButton.icon(
                  onPressed: () => onSave(program, result),
                  icon: const Icon(Icons.save),
                  label: Text(
                    context.l10n.t(
                      activeSavedId == null ? 'lpSaveModel' : 'lpSaveChanges',
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => onSave(program, result, copy: true),
                  icon: const Icon(Icons.copy_all),
                  label: Text(context.l10n.t('lpSaveCopy')),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: _copyText(program, result)),
                    );
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l10n.t('copied'))),
                      );
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(context.l10n.t('lpCopyResult')),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    final dual = const DualBuilder().build(program);
                    showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(context.l10n.t('lpDual')),
                        content: Text(
                          dual is DualBuildSuccess
                              ? '${dual.program.direction.name}: ${dual.program.variables.length} ${context.l10n.t('lpVariables').toLowerCase()}'
                              : context.l10n.t('lpDualUnsupported'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(context.l10n.t('close')),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(context.l10n.t('lpDual')),
                ),
                OutlinedButton.icon(
                  onPressed: onNew,
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.t('lpNewModel')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _copyText(LinearProgram program, LinearProgramResult result) {
    final buffer = StringBuffer('${program.title}\n${result.status.name}');
    if (result is FeasibleLinearProgramResult) {
      buffer.write('\nz = ${formatLpNumber(result.objectiveValue)}');
      for (final entry in result.variableValues.entries)
        buffer.write('\n${entry.key} = ${formatLpNumber(entry.value)}');
    }
    if (result.iterations.isNotEmpty) {
      final tableau = result.iterations.last.tableau;
      buffer.write('\n\n${tableau.columnNames.join('\t')}\tRHS');
      for (final row in tableau.rows)
        buffer.write('\n${row.map(formatLpNumber).join('\t')}');
    }
    return buffer.toString();
  }
}

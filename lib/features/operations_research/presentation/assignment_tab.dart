import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart'
    show parseLpNumber;
import 'package:calcademy/features/operations_research/domain/operations_research_limits.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_problem.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';
import 'package:calcademy/features/operations_research/presentation/operations_research_controller.dart';
import 'package:calcademy/features/operations_research/presentation/operations_research_input_widgets.dart';
import 'package:calcademy/features/operations_research/presentation/operations_research_result_card.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssignmentTab extends ConsumerStatefulWidget {
  const AssignmentTab({super.key});

  @override
  ConsumerState<AssignmentTab> createState() => _AssignmentTabState();
}

class _AssignmentTabState extends ConsumerState<AssignmentTab> {
  var _rows = 2;
  var _columns = 2;
  var _objective = OperationsResearchObjective.minimize;
  final _values = <List<TextEditingController>>[];

  @override
  void initState() {
    super.initState();
    _resize(_rows, _columns);
  }

  void _resize(int rows, int columns) {
    while (_values.length < rows) {
      _values.add([
        for (var column = 0; column < columns; column++)
          TextEditingController(text: '0'),
      ]);
    }
    while (_values.length > rows) {
      for (final controller in _values.removeLast()) {
        controller.dispose();
      }
    }
    for (final row in _values) {
      while (row.length < columns) {
        row.add(TextEditingController(text: '0'));
      }
      while (row.length > columns) {
        row.removeLast().dispose();
      }
    }
    _rows = rows;
    _columns = columns;
  }

  @override
  void dispose() {
    for (final row in _values) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _solve() async {
    try {
      final problem = AssignmentProblem(
        values: [
          for (final row in _values)
            [for (final controller in row) parseLpNumber(controller.text)],
        ],
        objective: _objective,
      );
      await ref
          .read(operationsResearchProvider.notifier)
          .solveAssignment(problem);
    } on Object {
      ref
          .read(operationsResearchProvider.notifier)
          .reportIssue(OperationsResearchIssue.invalidNumber);
    }
  }

  void _clear() {
    for (final row in _values) {
      for (final controller in row) {
        controller.text = '0';
      }
    }
    ref.read(operationsResearchProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(operationsResearchProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            OrCountSelector(
              label: l10n.t('orWorkers'),
              value: _rows,
              minimum: OperationsResearchLimits.minAssignmentRows,
              maximum: OperationsResearchLimits.maxAssignmentRows,
              onChanged: (value) => setState(() => _resize(value, _columns)),
              increaseKey: const Key('or-assignment-add-row'),
            ),
            OrCountSelector(
              label: l10n.t('orJobs'),
              value: _columns,
              minimum: OperationsResearchLimits.minAssignmentColumns,
              maximum: OperationsResearchLimits.maxAssignmentColumns,
              onChanged: (value) => setState(() => _resize(_rows, value)),
              increaseKey: const Key('or-assignment-add-column'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<OperationsResearchObjective>(
          key: const Key('or-assignment-objective'),
          isExpanded: true,
          initialValue: _objective,
          decoration: InputDecoration(labelText: l10n.t('orObjective')),
          items: [
            for (final value in OperationsResearchObjective.values)
              DropdownMenuItem(
                value: value,
                child: Text(
                  l10n.t(
                    value == OperationsResearchObjective.minimize
                        ? 'orMinimizeCost'
                        : 'orMaximizeProfit',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _objective = value);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.t('orAssignmentMatrix'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          key: const Key('or-assignment-grid-scroll'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Column(
            children: [
              for (var row = 0; row < _rows; row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      SizedBox(width: 42, child: Text('W${row + 1}')),
                      for (var column = 0; column < _columns; column++) ...[
                        OrMatrixField(
                          fieldKey: Key('or-assignment-value-$row-$column'),
                          controller: _values[row][column],
                          label: 'J${column + 1}',
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('or-assignment-solve'),
                onPressed: state.loading ? null : _solve,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.t('orSolve')),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton(
              onPressed: state.loading ? null : _clear,
              child: Text(l10n.t('orClear')),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.loading)
          const Center(child: CircularProgressIndicator())
        else if (state.result != null)
          OperationsResearchResultCard(result: state.result!),
      ],
    );
  }
}

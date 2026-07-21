import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart'
    show formatLpNumber;
import 'package:calcademy/features/operations_research/domain/operations_research_problem.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';
import 'package:calcademy/features/operations_research/presentation/cpm_pert_result_card.dart';
import 'package:calcademy/features/operations_research/presentation/goal_programming_result_card.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/operations_research_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/presentation/save_result_action.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String operationsResearchIssueKey(
  OperationsResearchIssue issue,
) => switch (issue) {
  OperationsResearchIssue.invalidSourceCount => 'orErrorSourceCount',
  OperationsResearchIssue.invalidDestinationCount => 'orErrorDestinationCount',
  OperationsResearchIssue.invalidAssignmentRowCount => 'orErrorRowCount',
  OperationsResearchIssue.invalidAssignmentColumnCount => 'orErrorColumnCount',
  OperationsResearchIssue.invalidGoalVariableCount => 'orErrorGoalVariables',
  OperationsResearchIssue.invalidHardConstraintCount =>
    'orErrorHardConstraintCount',
  OperationsResearchIssue.invalidGoalCount => 'orErrorGoalCount',
  OperationsResearchIssue.invalidWeight => 'orErrorGoalWeight',
  OperationsResearchIssue.allGoalWeightsZero => 'orErrorAllWeightsZero',
  OperationsResearchIssue.goalUnbounded => 'orErrorGoalUnbounded',
  OperationsResearchIssue.invalidActivityCount => 'orErrorActivityCount',
  OperationsResearchIssue.emptyActivityId => 'orErrorEmptyActivityId',
  OperationsResearchIssue.duplicateActivityId => 'orErrorDuplicateActivityId',
  OperationsResearchIssue.missingPredecessor => 'orErrorMissingPredecessor',
  OperationsResearchIssue.cyclicNetwork => 'orErrorCyclicNetwork',
  OperationsResearchIssue.invalidDuration => 'orErrorDuration',
  OperationsResearchIssue.invalidPertTimes => 'orErrorPertTimes',
  OperationsResearchIssue.tooManyPredecessors => 'orErrorTooManyPredecessors',
  OperationsResearchIssue.invalidDimensions => 'orErrorDimensions',
  OperationsResearchIssue.invalidNumber => 'orErrorInvalidNumber',
  OperationsResearchIssue.negativeSupply => 'orErrorNegativeSupply',
  OperationsResearchIssue.negativeDemand => 'orErrorNegativeDemand',
  OperationsResearchIssue.zeroSupply => 'orErrorZeroSupply',
  OperationsResearchIssue.zeroDemand => 'orErrorZeroDemand',
  OperationsResearchIssue.zeroSupplyRow => 'orErrorZeroSupplyRow',
  OperationsResearchIssue.zeroDemandColumn => 'orErrorZeroDemandColumn',
  OperationsResearchIssue.tooLarge => 'orErrorTooLarge',
  OperationsResearchIssue.iterationLimit => 'orErrorIterationLimit',
  OperationsResearchIssue.modiCycleNotFound => 'orErrorModiCycle',
  OperationsResearchIssue.infeasible => 'orErrorInfeasible',
  OperationsResearchIssue.solverFailure => 'orErrorSolverFailure',
};

class OperationsResearchResultCard extends StatelessWidget {
  const OperationsResearchResultCard({super.key, required this.result});

  final OperationsResearchResult result;

  @override
  Widget build(BuildContext context) {
    if (result case OperationsResearchFailureResult(:final issue)) {
      return Card(
        key: const Key('or-result-error'),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(context.l10n.t(operationsResearchIssueKey(issue))),
              ),
            ],
          ),
        ),
      );
    }
    final content = switch (result) {
      TransportationResult transportation => _TransportationResultBody(
        result: transportation,
      ),
      AssignmentResult assignment => _AssignmentResultBody(result: assignment),
      GoalProgrammingResult goal => GoalProgrammingResultBody(result: goal),
      CpmPertResult network => CpmPertResultBody(result: network),
      OperationsResearchFailureResult() => const SizedBox.shrink(),
    };
    return Card(
      key: const Key('or-result-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: content,
      ),
    );
  }
}

class _TransportationResultBody extends StatelessWidget {
  const _TransportationResultBody({required this.result});

  final TransportationResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final totalLabel = result.objective == OperationsResearchObjective.minimize
        ? l10n.t('orTotalCost')
        : l10n.t('orTotalProfit');
    final copyText = _copyText(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.t('orTransportationResult'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          result.isOptimal
              ? l10n.t('orOptimalSolution')
              : l10n.t('orInitialSolution'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: result.isOptimal
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.tertiary,
          ),
        ),
        Text('${l10n.t('orMethodUsed')}: ${result.methodName}'),
        Text(
          '${l10n.t('orInitialMethod')}: ${l10n.t(result.initialMethod == TransportationInitialMethod.northWestCorner ? 'orNorthWestCorner' : 'orLeastCost')}',
        ),
        Text('${l10n.t('orIterations')}: ${result.iterations}'),
        Text(
          '${l10n.t('orSupplyTotal')}: ${formatLpNumber(result.totalSupply)} · ${l10n.t('orDemandTotal')}: ${formatLpNumber(result.totalDemand)}',
        ),
        const Divider(),
        Text(
          '$totalLabel: ${formatLpNumber(result.totalValue)}',
          key: const Key('or-total-value'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.t('orAllocationMatrix'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        _AllocationTable(result: result),
        _Warnings(keys: result.warnings),
        _ResultActions(
          copyText: copyText,
          draft: OperationsResearchSavedAdapter.transportation(result),
          saveKey: const Key('or-save-result'),
        ),
      ],
    );
  }

  String _copyText(AppLocalizations l10n) {
    final buffer = StringBuffer(
      '${l10n.t('orTransportation')} · ${result.methodName}\n'
      '${l10n.t('orTotalValue')}: ${formatLpNumber(result.totalValue)}',
    );
    for (var row = 0; row < result.allocations.length; row++) {
      for (var column = 0; column < result.allocations[row].length; column++) {
        final value = result.allocations[row][column];
        if (value != 0) {
          buffer.write(
            '\nS${row + 1} → D${column + 1}: ${formatLpNumber(value)}',
          );
        }
      }
    }
    return buffer.toString();
  }
}

class _AllocationTable extends StatelessWidget {
  const _AllocationTable({required this.result});

  final TransportationResult result;

  @override
  Widget build(BuildContext context) {
    const cellWidth = 84.0;
    final columns = result.allocations.first.length;
    return SingleChildScrollView(
      key: const Key('or-allocation-scroll'),
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: cellWidth * (columns + 1),
        child: Table(
          border: TableBorder.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          defaultColumnWidth: const FixedColumnWidth(cellWidth),
          children: [
            TableRow(
              children: [
                const _TableCellText(''),
                for (var column = 0; column < columns; column++)
                  _TableCellText(
                    column == result.dummyDestinationIndex
                        ? context.l10n.t('orDummy')
                        : 'D${column + 1}',
                  ),
              ],
            ),
            for (var row = 0; row < result.allocations.length; row++)
              TableRow(
                children: [
                  _TableCellText(
                    row == result.dummySourceIndex
                        ? context.l10n.t('orDummy')
                        : 'S${row + 1}',
                  ),
                  for (final value in result.allocations[row])
                    _TableCellText(formatLpNumber(value)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentResultBody extends StatelessWidget {
  const _AssignmentResultBody({required this.result});

  final AssignmentResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final totalLabel = result.objective == OperationsResearchObjective.minimize
        ? l10n.t('orTotalCost')
        : l10n.t('orTotalProfit');
    final realAssignments = result.assignments.where((item) => !item.isDummy);
    final copyText = [
      '${l10n.t('orAssignment')} · ${result.methodName}',
      '$totalLabel: ${formatLpNumber(result.totalValue)}',
      for (final item in realAssignments)
        'W${item.row + 1} → J${item.column + 1}: ${formatLpNumber(item.value)}',
    ].join('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.t('orAssignmentResult'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text('${l10n.t('orMethodUsed')}: ${result.methodName}'),
        Text('${l10n.t('orIterations')}: ${result.iterations}'),
        const Divider(),
        Text(
          '$totalLabel: ${formatLpNumber(result.totalValue)}',
          key: const Key('or-total-value'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.t('orAssignments'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final item in realAssignments)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.link_rounded),
            title: Text('W${item.row + 1} → J${item.column + 1}'),
            trailing: Text(formatLpNumber(item.value)),
          ),
        if (result.hasDummyAssignments)
          Text(
            l10n.t('orDummyAssignmentsExcluded'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        _Warnings(keys: result.warnings),
        _ResultActions(
          copyText: copyText,
          draft: OperationsResearchSavedAdapter.assignment(result),
          saveKey: const Key('or-save-result'),
        ),
      ],
    );
  }
}

class _Warnings extends StatelessWidget {
  const _Warnings({required this.keys});

  final List<String> keys;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final key in keys)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.xs),
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: Text(context.l10n.t(key)),
        ),
    ],
  );
}

class _ResultActions extends StatelessWidget {
  const _ResultActions({
    required this.copyText,
    required this.draft,
    required this.saveKey,
  });

  final String copyText;
  final SavedCalculationDraft draft;
  final Key saveKey;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.end,
      children: [
        TextButton.icon(
          key: const Key('or-copy-result'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: copyText));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(context.l10n.t('copied'))));
            }
          },
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: Text(context.l10n.t('copyResult')),
        ),
        SaveResultAction(buttonKey: saveKey, draft: draft),
      ],
    ),
  );
}

class _TableCellText extends StatelessWidget {
  const _TableCellText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.xs),
    child: Text(text, textAlign: TextAlign.center),
  );
}

import 'package:calcademy/features/linear_programming/domain/linear_program.dart'
    show formatLpNumber;
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/saved_adapter_utils.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_limits.dart';

abstract final class OperationsResearchSavedAdapter {
  static SavedCalculationDraft transportation(TransportationResult result) {
    requireFinite([
      result.totalValue,
      result.totalSupply,
      result.totalDemand,
      ...result.allocations.expand((row) => row),
    ]);
    final preview = <Map<String, Object?>>[];
    var nonZeroCount = 0;
    for (var row = 0; row < result.allocations.length; row++) {
      for (var column = 0; column < result.allocations[row].length; column++) {
        final value = result.allocations[row][column];
        if (value == 0) continue;
        nonZeroCount++;
        if (preview.length < SavedCalculationsLimits.maxMatrixPreviewCells) {
          preview.add({'source': row, 'destination': column, 'value': value});
        }
      }
    }
    final objective = result.objective.name;
    final balance = result.wasBalanced ? 'balanced' : 'balanced with dummy';
    return SavedCalculationDraft(
      title:
          'Transportation · ${result.originalSourceCount}×${result.originalDestinationCount}',
      module: SavedCalculationModule.operationsResearch,
      calculationType: 'transportation',
      inputSummary:
          '$objective · ${result.originalSourceCount} sources · ${result.originalDestinationCount} destinations · $balance',
      resultSummary:
          '${result.methodName} · total ${formatLpNumber(result.totalValue)} · ${result.isOptimal ? 'optimal' : 'initial feasible'}',
      fullInputJson: {
        'sourceCount': result.originalSourceCount,
        'destinationCount': result.originalDestinationCount,
        'objective': objective,
        'initialMethod': result.initialMethod.name,
        'totalSupply': result.totalSupply,
        'totalDemand': result.totalDemand,
      },
      resultJson: {
        'totalValue': result.totalValue,
        'isOptimal': result.isOptimal,
        'isInitialOnly': result.isInitialOnly,
        'iterations': result.iterations,
        'allocationCount': nonZeroCount,
        'allocationPreview': preview,
        'previewTruncated': nonZeroCount > preview.length,
        'dummySource': result.dummySourceIndex,
        'dummyDestination': result.dummyDestinationIndex,
      },
    );
  }

  static SavedCalculationDraft assignment(AssignmentResult result) {
    requireFinite([
      result.totalValue,
      ...result.assignments.map((item) => item.value),
    ]);
    final preview = result.assignments
        .take(SavedCalculationsLimits.maxVariableSummaryCount)
        .map(
          (item) => {
            'row': item.row,
            'column': item.column,
            'value': item.value,
            'dummy': item.isDummy,
          },
        )
        .toList();
    return SavedCalculationDraft(
      title:
          'Assignment · ${result.originalRowCount}×${result.originalColumnCount}',
      module: SavedCalculationModule.operationsResearch,
      calculationType: 'assignment',
      inputSummary:
          '${result.objective.name} · ${result.originalRowCount} workers · ${result.originalColumnCount} jobs',
      resultSummary:
          '${result.methodName} · total ${formatLpNumber(result.totalValue)} · ${result.hasDummyAssignments ? 'dummy assignment used' : 'square'}',
      fullInputJson: {
        'rowCount': result.originalRowCount,
        'columnCount': result.originalColumnCount,
        'objective': result.objective.name,
      },
      resultJson: {
        'totalValue': result.totalValue,
        'assignmentCount': result.assignments.length,
        'assignmentPreview': preview,
        'previewTruncated': result.assignments.length > preview.length,
        'hasDummyAssignments': result.hasDummyAssignments,
      },
    );
  }

  static SavedCalculationDraft goalProgramming(GoalProgrammingResult result) {
    requireFinite([
      result.totalWeightedDeviation,
      ...result.decisionVariables.values,
      ...result.deviations.expand(
        (item) => [item.under, item.over, item.weightedContribution],
      ),
    ]);
    final decisions = result.decisionVariables.entries
        .take(SavedCalculationsLimits.maxVariableSummaryCount)
        .map((entry) => {'name': entry.key, 'value': entry.value})
        .toList();
    final deviations = result.deviations
        .take(SavedCalculationsLimits.maxVariableSummaryCount)
        .map(
          (item) => {
            'goal': item.goalIndex,
            'under': item.under,
            'over': item.over,
            'satisfied': item.satisfied,
          },
        )
        .toList();
    return SavedCalculationDraft(
      title: 'Weighted Goal Programming · ${result.goalCount} goals',
      module: SavedCalculationModule.operationsResearch,
      calculationType: 'goal-programming',
      inputSummary:
          '${result.decisionVariables.length} variables · ${result.hardConstraintCount} hard constraints · ${result.goalCount} goals',
      resultSummary:
          '${result.methodName} · weighted deviation ${formatLpNumber(result.totalWeightedDeviation)} · optimal',
      fullInputJson: {
        'variableCount': result.decisionVariables.length,
        'hardConstraintCount': result.hardConstraintCount,
        'goalCount': result.goalCount,
      },
      resultJson: {
        'status': result.status.name,
        'totalWeightedDeviation': result.totalWeightedDeviation,
        'decisionPreview': decisions,
        'deviationPreview': deviations,
        'previewTruncated':
            result.decisionVariables.length > decisions.length ||
            result.deviations.length > deviations.length,
      },
    );
  }

  static SavedCalculationDraft cpmPert(CpmPertResult result) {
    requireFinite([
      result.projectDuration,
      if (result.projectVariance != null) result.projectVariance!,
      if (result.projectStandardDeviation != null)
        result.projectStandardDeviation!,
      ...result.activities.expand(
        (item) => [
          item.duration,
          item.earliestStart,
          item.earliestFinish,
          item.latestStart,
          item.latestFinish,
          item.totalFloat,
        ],
      ),
    ]);
    final activityPreview = result.activities
        .take(SavedCalculationsLimits.maxVariableSummaryCount)
        .map(
          (item) => {
            'id': item.id,
            'duration': item.duration,
            'slack': item.totalFloat,
            'critical': item.critical,
          },
        )
        .toList();
    final path = result.criticalPaths.isEmpty
        ? result.criticalActivities.join(' → ')
        : result.criticalPaths.first.join(' → ');
    return SavedCalculationDraft(
      title: '${result.methodName} · ${result.activities.length} activities',
      module: SavedCalculationModule.operationsResearch,
      calculationType: 'cpm-pert',
      inputSummary:
          '${result.methodName} · ${result.activities.length} activities',
      resultSummary:
          'duration ${formatLpNumber(result.projectDuration)} · critical path $path${result.projectStandardDeviation == null ? '' : ' · σ ${formatLpNumber(result.projectStandardDeviation!)}'}',
      fullInputJson: {
        'mode': result.mode.name,
        'activityCount': result.activities.length,
      },
      resultJson: {
        'projectDuration': result.projectDuration,
        'criticalActivities': result.criticalActivities,
        'criticalPathPreview': result.criticalPaths.take(1).toList(),
        'projectVariance': result.projectVariance,
        'projectStandardDeviation': result.projectStandardDeviation,
        'activityPreview': activityPreview,
        'previewTruncated': result.activities.length > activityPreview.length,
      },
    );
  }
}

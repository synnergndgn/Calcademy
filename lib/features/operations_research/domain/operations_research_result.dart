import 'dart:collection';

import 'package:calcademy/features/operations_research/domain/operations_research_problem.dart';
import 'package:calcademy/features/operations_research/domain/goal_programming_problem.dart';
import 'package:calcademy/features/operations_research/domain/project_network_problem.dart';

enum OperationsResearchIssue {
  invalidSourceCount,
  invalidDestinationCount,
  invalidAssignmentRowCount,
  invalidAssignmentColumnCount,
  invalidGoalVariableCount,
  invalidHardConstraintCount,
  invalidGoalCount,
  invalidWeight,
  allGoalWeightsZero,
  goalUnbounded,
  invalidActivityCount,
  emptyActivityId,
  duplicateActivityId,
  missingPredecessor,
  cyclicNetwork,
  invalidDuration,
  invalidPertTimes,
  tooManyPredecessors,
  invalidDimensions,
  invalidNumber,
  negativeSupply,
  negativeDemand,
  zeroSupply,
  zeroDemand,
  zeroSupplyRow,
  zeroDemandColumn,
  tooLarge,
  iterationLimit,
  modiCycleNotFound,
  infeasible,
  solverFailure,
}

sealed class OperationsResearchResult {
  const OperationsResearchResult();
}

class OperationsResearchFailureResult extends OperationsResearchResult {
  const OperationsResearchFailureResult(this.issue);

  final OperationsResearchIssue issue;
}

class TransportationInitialSolution {
  TransportationInitialSolution({
    required List<List<double>> allocations,
    required Set<(int, int)> basis,
    required this.value,
    required this.degenerate,
  }) : allocations = UnmodifiableListView([
         for (final row in allocations) UnmodifiableListView(row),
       ]),
       basis = UnmodifiableSetView(basis);

  final List<List<double>> allocations;
  final Set<(int, int)> basis;
  final double value;
  final bool degenerate;
}

class TransportationResult extends OperationsResearchResult {
  TransportationResult({
    required this.objective,
    required this.initialMethod,
    required List<List<double>> allocations,
    required this.totalValue,
    required this.originalSourceCount,
    required this.originalDestinationCount,
    required this.balancedSourceCount,
    required this.balancedDestinationCount,
    required this.totalSupply,
    required this.totalDemand,
    required this.isOptimal,
    required this.isInitialOnly,
    required this.iterations,
    required this.degenerate,
    required List<String> warnings,
    this.dummySourceIndex,
    this.dummyDestinationIndex,
  }) : allocations = UnmodifiableListView([
         for (final row in allocations) UnmodifiableListView(row),
       ]),
       warnings = UnmodifiableListView(warnings);

  final OperationsResearchObjective objective;
  final TransportationInitialMethod initialMethod;
  final List<List<double>> allocations;
  final double totalValue;
  final int originalSourceCount;
  final int originalDestinationCount;
  final int balancedSourceCount;
  final int balancedDestinationCount;
  final double totalSupply;
  final double totalDemand;
  final bool isOptimal;
  final bool isInitialOnly;
  final int iterations;
  final bool degenerate;
  final List<String> warnings;
  final int? dummySourceIndex;
  final int? dummyDestinationIndex;

  bool get wasBalanced =>
      dummySourceIndex == null && dummyDestinationIndex == null;
  String get methodName => isOptimal ? 'MODI / U-V' : 'Initial feasible';
}

class AssignmentMatch {
  const AssignmentMatch({
    required this.row,
    required this.column,
    required this.value,
    required this.isDummy,
  });

  final int row;
  final int column;
  final double value;
  final bool isDummy;
}

class AssignmentResult extends OperationsResearchResult {
  AssignmentResult({
    required this.objective,
    required List<AssignmentMatch> assignments,
    required this.totalValue,
    required this.originalRowCount,
    required this.originalColumnCount,
    required this.balancedSize,
    required this.iterations,
    required List<String> warnings,
  }) : assignments = UnmodifiableListView(assignments),
       warnings = UnmodifiableListView(warnings);

  final OperationsResearchObjective objective;
  final List<AssignmentMatch> assignments;
  final double totalValue;
  final int originalRowCount;
  final int originalColumnCount;
  final int balancedSize;
  final int iterations;
  final List<String> warnings;

  bool get hasDummyAssignments => assignments.any((item) => item.isDummy);
  String get methodName => 'Hungarian algorithm';
}

class GoalDeviation {
  const GoalDeviation({
    required this.goalIndex,
    required this.relation,
    required this.under,
    required this.over,
    required this.weightedContribution,
    required this.satisfied,
  });

  final int goalIndex;
  final GoalTargetRelation relation;
  final double under;
  final double over;
  final double weightedContribution;
  final bool satisfied;
}

enum GoalProgrammingStatus { optimal, multipleOptimal }

class GoalProgrammingResult extends OperationsResearchResult {
  GoalProgrammingResult({
    required this.totalWeightedDeviation,
    required Map<String, double> decisionVariables,
    required List<GoalDeviation> deviations,
    required this.hardConstraintCount,
    required this.goalCount,
    required this.hardConstraintsSatisfied,
    required this.status,
    required this.iterations,
    required List<String> warnings,
  }) : decisionVariables = UnmodifiableMapView(decisionVariables),
       deviations = UnmodifiableListView(deviations),
       warnings = UnmodifiableListView(warnings);

  final double totalWeightedDeviation;
  final Map<String, double> decisionVariables;
  final List<GoalDeviation> deviations;
  final int hardConstraintCount;
  final int goalCount;
  final bool hardConstraintsSatisfied;
  final GoalProgrammingStatus status;
  final int iterations;
  final List<String> warnings;

  bool get multipleOptimal => status == GoalProgrammingStatus.multipleOptimal;
  String get methodName => 'Weighted Goal Programming / Simplex';
}

class ProjectActivitySchedule {
  ProjectActivitySchedule({
    required this.id,
    required List<String> predecessors,
    required this.duration,
    required this.variance,
    required this.earliestStart,
    required this.earliestFinish,
    required this.latestStart,
    required this.latestFinish,
    required this.totalFloat,
    required this.freeFloat,
    required this.critical,
  }) : predecessors = UnmodifiableListView(predecessors);

  final String id;
  final List<String> predecessors;
  final double duration;
  final double variance;
  final double earliestStart;
  final double earliestFinish;
  final double latestStart;
  final double latestFinish;
  final double totalFloat;
  final double freeFloat;
  final bool critical;
}

class CpmPertResult extends OperationsResearchResult {
  CpmPertResult({
    required this.mode,
    required this.projectDuration,
    required List<String> criticalActivities,
    required List<List<String>> criticalPaths,
    required List<ProjectActivitySchedule> activities,
    required this.projectVariance,
    required this.projectStandardDeviation,
    required List<String> warnings,
  }) : criticalActivities = UnmodifiableListView(criticalActivities),
       criticalPaths = UnmodifiableListView([
         for (final path in criticalPaths) UnmodifiableListView(path),
       ]),
       activities = UnmodifiableListView(activities),
       warnings = UnmodifiableListView(warnings);

  final ProjectScheduleMode mode;
  final double projectDuration;
  final List<String> criticalActivities;
  final List<List<String>> criticalPaths;
  final List<ProjectActivitySchedule> activities;
  final double? projectVariance;
  final double? projectStandardDeviation;
  final List<String> warnings;

  String get methodName => mode == ProjectScheduleMode.cpm ? 'CPM' : 'PERT';
}

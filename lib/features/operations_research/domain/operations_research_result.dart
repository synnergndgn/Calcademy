import 'dart:collection';

import 'package:calcademy/features/operations_research/domain/operations_research_problem.dart';

enum OperationsResearchIssue {
  invalidSourceCount,
  invalidDestinationCount,
  invalidAssignmentRowCount,
  invalidAssignmentColumnCount,
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

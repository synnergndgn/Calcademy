import 'dart:collection';

import 'package:calcademy/features/integer_programming/domain/branch_node.dart';
import 'package:calcademy/features/integer_programming/domain/branching_strategy.dart';
import 'package:calcademy/features/integer_programming/domain/node_selection_strategy.dart';

/// Why a search stopped before every node could be fathomed, leaving the
/// result unproven (either with a "best found so far" incumbent, in
/// [FeasibleIntegerSolution], or with no incumbent at all, in
/// [NodeLimitReached] / [IterationLimitReached]).
enum LimitReason { nodeLimit, depthLimit, iterationLimit }

/// A recorded improvement to the incumbent, in the order it was found.
class IncumbentUpdate {
  IncumbentUpdate({
    required this.nodeId,
    required this.objectiveValue,
    required Map<String, double> variableValues,
    required this.order,
  }) : variableValues = UnmodifiableMapView(variableValues);

  final String nodeId;
  final double objectiveValue;
  final Map<String, double> variableValues;
  final int order;
}

/// The outcome of a single Branch-and-Bound run. Every variant carries the
/// same search-report fields (nodes solved, prune counts, the branch tree,
/// ...) so the UI can show a consistent report regardless of how the search
/// ended; only the solution-specific fields differ by variant.
sealed class MipResult {
  MipResult({
    required this.rootRelaxationObjective,
    required this.nodesSolved,
    required this.openNodes,
    required this.maxDepthReached,
    required Map<PruneReason, int> pruneCounts,
    required List<BranchNode> branchTree,
    required List<IncumbentUpdate> incumbentHistory,
    required this.branchingStrategy,
    required this.nodeSelectionStrategy,
    required this.elapsedMicroseconds,
    required List<String> warnings,
  }) : pruneCounts = UnmodifiableMapView(pruneCounts),
       branchTree = UnmodifiableListView(branchTree),
       incumbentHistory = UnmodifiableListView(incumbentHistory),
       warnings = UnmodifiableListView(warnings);

  /// The root node's LP relaxation objective, i.e. the initial bound before
  /// any branching. Null only when the root itself failed (infeasible,
  /// unbounded or a numerical failure).
  final double? rootRelaxationObjective;
  final int nodesSolved;
  final int openNodes;
  final int maxDepthReached;
  final Map<PruneReason, int> pruneCounts;
  final List<BranchNode> branchTree;
  final List<IncumbentUpdate> incumbentHistory;
  final BranchingStrategy branchingStrategy;
  final NodeSelectionStrategy nodeSelectionStrategy;
  final int elapsedMicroseconds;
  final List<String> warnings;
}

/// Shared shape for results that carry an actual solution.
sealed class IncumbentMipResult extends MipResult {
  IncumbentMipResult({
    required super.rootRelaxationObjective,
    required super.nodesSolved,
    required super.openNodes,
    required super.maxDepthReached,
    required super.pruneCounts,
    required super.branchTree,
    required super.incumbentHistory,
    required super.branchingStrategy,
    required super.nodeSelectionStrategy,
    required super.elapsedMicroseconds,
    required super.warnings,
    required this.objectiveValue,
    required Map<String, double> variableValues,
    required this.bestBound,
  }) : variableValues = UnmodifiableMapView(variableValues);

  final double objectiveValue;
  final Map<String, double> variableValues;

  /// The tightest still-valid bound on the optimum: the incumbent value
  /// itself once the search is proven complete, or the best bound among the
  /// remaining open nodes when the search was truncated.
  final double bestBound;

  double get absoluteGap => (objectiveValue - bestBound).abs();

  double get relativeGap =>
      absoluteGap / (objectiveValue.abs() < 1 ? 1 : objectiveValue.abs());
}

/// The search completed and proved [objectiveValue] optimal: every open
/// node was fathomed, so [bestBound] equals [objectiveValue] and the gap is
/// zero.
class OptimalIntegerSolution extends IncumbentMipResult {
  OptimalIntegerSolution({
    required super.rootRelaxationObjective,
    required super.nodesSolved,
    required super.openNodes,
    required super.maxDepthReached,
    required super.pruneCounts,
    required super.branchTree,
    required super.incumbentHistory,
    required super.branchingStrategy,
    required super.nodeSelectionStrategy,
    required super.elapsedMicroseconds,
    required super.warnings,
    required super.objectiveValue,
    required super.variableValues,
  }) : super(bestBound: objectiveValue);
}

/// The best integer-feasible solution found before a search limit was hit;
/// optimality is not proven ([bestBound] may still be strictly better than
/// [objectiveValue]).
class FeasibleIntegerSolution extends IncumbentMipResult {
  FeasibleIntegerSolution({
    required super.rootRelaxationObjective,
    required super.nodesSolved,
    required super.openNodes,
    required super.maxDepthReached,
    required super.pruneCounts,
    required super.branchTree,
    required super.incumbentHistory,
    required super.branchingStrategy,
    required super.nodeSelectionStrategy,
    required super.elapsedMicroseconds,
    required super.warnings,
    required super.objectiveValue,
    required super.variableValues,
    required super.bestBound,
    required this.limitReason,
  });

  final LimitReason limitReason;
}

/// The root LP relaxation is already infeasible, or the whole tree was
/// fathomed without ever finding an integer-feasible point.
class InfeasibleIntegerProgram extends MipResult {
  InfeasibleIntegerProgram({
    required super.rootRelaxationObjective,
    required super.nodesSolved,
    required super.openNodes,
    required super.maxDepthReached,
    required super.pruneCounts,
    required super.branchTree,
    required super.incumbentHistory,
    required super.branchingStrategy,
    required super.nodeSelectionStrategy,
    required super.elapsedMicroseconds,
    required super.warnings,
  });
}

/// The root LP relaxation is unbounded. This release does not attempt to
/// prove whether integrality would still bound the objective; it reports
/// the relaxation's own status directly (see the module README for this
/// known limitation).
class UnboundedRelaxation extends MipResult {
  UnboundedRelaxation({
    required super.nodesSolved,
    required super.openNodes,
    required super.maxDepthReached,
    required super.pruneCounts,
    required super.branchTree,
    required super.incumbentHistory,
    required super.branchingStrategy,
    required super.nodeSelectionStrategy,
    required super.elapsedMicroseconds,
    required super.warnings,
  }) : super(rootRelaxationObjective: null);
}

/// A node or iteration limit was reached before any integer-feasible
/// solution was ever found, so there is nothing to report but the search
/// statistics.
class NodeLimitReached extends MipResult {
  NodeLimitReached({
    required super.rootRelaxationObjective,
    required super.nodesSolved,
    required super.openNodes,
    required super.maxDepthReached,
    required super.pruneCounts,
    required super.branchTree,
    required super.incumbentHistory,
    required super.branchingStrategy,
    required super.nodeSelectionStrategy,
    required super.elapsedMicroseconds,
    required super.warnings,
    required this.reason,
  });

  final LimitReason reason;
}

/// The cumulative LP iteration budget across all nodes was exhausted
/// before any integer-feasible solution was found.
class IterationLimitReached extends MipResult {
  IterationLimitReached({
    required super.rootRelaxationObjective,
    required super.nodesSolved,
    required super.openNodes,
    required super.maxDepthReached,
    required super.pruneCounts,
    required super.branchTree,
    required super.incumbentHistory,
    required super.branchingStrategy,
    required super.nodeSelectionStrategy,
    required super.elapsedMicroseconds,
    required super.warnings,
  });
}

/// The root relaxation could not be solved reliably (a numerical failure or
/// LP iteration limit inside the simplex solver itself).
class NumericalFailure extends MipResult {
  NumericalFailure({
    required super.nodesSolved,
    required super.openNodes,
    required super.maxDepthReached,
    required super.pruneCounts,
    required super.branchTree,
    required super.incumbentHistory,
    required super.branchingStrategy,
    required super.nodeSelectionStrategy,
    required super.elapsedMicroseconds,
    required super.warnings,
  }) : super(rootRelaxationObjective: null);
}

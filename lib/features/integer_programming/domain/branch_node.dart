import 'dart:collection';

import 'package:calcademy/features/integer_programming/domain/branch_decision.dart';

/// The terminal (or in-flight) state of a single Branch-and-Bound node.
///
/// `integerFeasible` and `prunedIntegral` are both "closed because the
/// relaxation is already integral" outcomes; they are kept distinct so the
/// tree can show *why* a node was closed: `integerFeasible` is a node whose
/// solution improved the incumbent, `prunedIntegral` is an integral node
/// that did not (it is still closed - an integral relaxation is never
/// branched on - but it did not become the best-known solution).
enum NodeStatus {
  pending,
  solving,
  fractional,
  integerFeasible,
  prunedByBound,
  prunedInfeasible,
  prunedIntegral,
  unbounded,
  error,
}

/// Aggregate reasons a node stopped being explored, used for the
/// tree-wide prune counters in [MipResult]. This is intentionally wider
/// than [NodeStatus]: it also tracks nodes that were never created because
/// the depth limit was reached, which have no [BranchNode] of their own.
enum PruneReason { bound, infeasible, integral, depthLimit, unbounded, error }

class BranchNode {
  BranchNode({
    required this.id,
    required this.parentId,
    required this.depth,
    required List<BranchConstraint> additionalConstraints,
    required this.status,
    required this.order,
    this.relaxationObjective,
    Map<String, double>? relaxationValues,
    this.branchDecision,
    this.pruneReason,
    this.isIncumbent = false,
  }) : additionalConstraints = UnmodifiableListView(additionalConstraints),
       relaxationValues = relaxationValues == null
           ? null
           : UnmodifiableMapView(relaxationValues);

  final String id;
  final String? parentId;
  final int depth;
  final List<BranchConstraint> additionalConstraints;
  final NodeStatus status;
  final double? relaxationObjective;
  final Map<String, double>? relaxationValues;
  final BranchDecision? branchDecision;
  final String? pruneReason;
  final bool isIncumbent;

  /// Insertion order in the search, used only to keep traversal and any
  /// tie-breaking deterministic; not shown to the user.
  final int order;

  BranchNode copyWith({
    NodeStatus? status,
    double? relaxationObjective,
    Map<String, double>? relaxationValues,
    BranchDecision? branchDecision,
    String? pruneReason,
    bool? isIncumbent,
  }) => BranchNode(
    id: id,
    parentId: parentId,
    depth: depth,
    additionalConstraints: additionalConstraints,
    status: status ?? this.status,
    order: order,
    relaxationObjective: relaxationObjective ?? this.relaxationObjective,
    relaxationValues: relaxationValues ?? this.relaxationValues,
    branchDecision: branchDecision ?? this.branchDecision,
    pruneReason: pruneReason ?? this.pruneReason,
    isIncumbent: isIncumbent ?? this.isIncumbent,
  );
}

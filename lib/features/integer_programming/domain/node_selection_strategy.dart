import 'package:calcademy/features/integer_programming/domain/branch_decision.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';

/// Which open node the solver expands next.
///
/// - `depthFirst` dives to the bottom of one branch before backtracking,
///   which keeps the tree small and easy to follow for teaching-sized
///   models. It is the default.
/// - `bestBound` always expands the open node whose inherited relaxation
///   bound is most favourable, which tends to find a good incumbent (and a
///   tight optimality gap) sooner on larger models.
///
/// Both orders are fully deterministic: ties are broken by node creation
/// order, so re-solving the same model always visits nodes in the same
/// sequence.
enum NodeSelectionStrategy { depthFirst, bestBound }

/// A not-yet-solved node waiting in the search queue. [estimatedBound] is
/// the parent's *actual* solved relaxation objective, inherited as a valid
/// bound for every descendant (adding constraints can only make a linear
/// relaxation's objective equal or worse, never better). It is used only to
/// order `bestBound` traversal; the node's own true bound is computed once
/// it is popped and solved.
class PendingNode {
  const PendingNode({
    required this.id,
    required this.parentId,
    required this.depth,
    required this.additionalConstraints,
    required this.estimatedBound,
    required this.order,
  });

  final String id;
  final String? parentId;
  final int depth;
  final List<BranchConstraint> additionalConstraints;
  final double estimatedBound;
  final int order;
}

/// A pending-node queue that expands nodes in the order dictated by a
/// [NodeSelectionStrategy].
class NodeQueue {
  NodeQueue({required this.strategy, required this.direction});

  final NodeSelectionStrategy strategy;
  final ObjectiveDirection direction;
  final _pending = <PendingNode>[];

  bool get isEmpty => _pending.isEmpty;
  int get length => _pending.length;

  void add(PendingNode node) => _pending.add(node);

  PendingNode removeNext() {
    if (strategy == NodeSelectionStrategy.depthFirst) {
      return _pending.removeLast();
    }

    var bestIndex = 0;
    for (var index = 1; index < _pending.length; index++) {
      if (_isBetter(_pending[index], _pending[bestIndex])) bestIndex = index;
    }
    return _pending.removeAt(bestIndex);
  }

  bool _isBetter(PendingNode candidate, PendingNode current) {
    final better = direction == ObjectiveDirection.maximize
        ? candidate.estimatedBound > current.estimatedBound
        : candidate.estimatedBound < current.estimatedBound;
    if (better) return true;
    final tied = candidate.estimatedBound == current.estimatedBound;
    return tied && candidate.order < current.order;
  }

  List<PendingNode> get remaining => List.unmodifiable(_pending);
}

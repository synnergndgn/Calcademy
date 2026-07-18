/// Which side of a fractional split a [BranchConstraint] represents.
enum BranchDirection { lowerBranch, upperBranch }

/// A single extra bound added to a node's relaxation, e.g. `x1 <= 3` or
/// `x1 >= 4`. Child nodes accumulate their ancestors' constraints, so the
/// full list for a node is the path from the root to that node.
class BranchConstraint {
  const BranchConstraint({
    required this.variableId,
    required this.variableName,
    required this.direction,
    required this.bound,
  });

  final String variableId;
  final String variableName;
  final BranchDirection direction;
  final double bound;

  String describe() => direction == BranchDirection.lowerBranch
      ? '$variableName ≤ $bound'
      : '$variableName ≥ $bound';
}

/// The branching decision made at a node: which fractional integer/binary
/// variable was selected, and the floor/ceil values used to create the two
/// child nodes.
class BranchDecision {
  const BranchDecision({
    required this.variableId,
    required this.variableName,
    required this.fractionalValue,
    required this.floorValue,
    required this.ceilValue,
  });

  final String variableId;
  final String variableName;
  final double fractionalValue;
  final double floorValue;
  final double ceilValue;

  BranchConstraint get lowerBranchConstraint => BranchConstraint(
    variableId: variableId,
    variableName: variableName,
    direction: BranchDirection.lowerBranch,
    bound: floorValue,
  );

  BranchConstraint get upperBranchConstraint => BranchConstraint(
    variableId: variableId,
    variableName: variableName,
    direction: BranchDirection.upperBranch,
    bound: ceilValue,
  );
}

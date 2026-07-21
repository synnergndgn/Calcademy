import 'dart:collection';

enum GoalConstraintRelation { lessOrEqual, equal, greaterOrEqual }

enum GoalTargetRelation { equal, atLeast, atMost }

class GoalHardConstraint {
  GoalHardConstraint({
    required List<double> coefficients,
    required this.relation,
    required this.rhs,
  }) : coefficients = UnmodifiableListView(coefficients);

  final List<double> coefficients;
  final GoalConstraintRelation relation;
  final double rhs;
}

class GoalTarget {
  GoalTarget({
    required List<double> coefficients,
    required this.relation,
    required this.target,
    required this.underWeight,
    required this.overWeight,
  }) : coefficients = UnmodifiableListView(coefficients);

  final List<double> coefficients;
  final GoalTargetRelation relation;
  final double target;
  final double underWeight;
  final double overWeight;
}

class GoalProgrammingProblem {
  GoalProgrammingProblem({
    required this.variableCount,
    required List<GoalHardConstraint> hardConstraints,
    required List<GoalTarget> goals,
  }) : hardConstraints = UnmodifiableListView(hardConstraints),
       goals = UnmodifiableListView(goals);

  final int variableCount;
  final List<GoalHardConstraint> hardConstraints;
  final List<GoalTarget> goals;
}

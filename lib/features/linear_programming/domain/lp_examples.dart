import 'package:calcademy/features/linear_programming/domain/linear_program.dart';

abstract final class LpExamples {
  static List<LinearProgram> get all => [
    productMix,
    minimization,
    equality,
    infeasible,
    unbounded,
    multiple,
  ];

  static LinearProgram get productMix => _program(
    'Product mix',
    ObjectiveDirection.maximize,
    [3, 2],
    [
      ([1.0, 1.0], ConstraintRelation.lessOrEqual, 4.0),
      ([1.0, 0.0], ConstraintRelation.lessOrEqual, 2.0),
      ([0.0, 1.0], ConstraintRelation.lessOrEqual, 3.0),
    ],
  );

  static LinearProgram get minimization => _program(
    'Minimum nutrition',
    ObjectiveDirection.minimize,
    [1, 1],
    [
      ([1.0, 2.0], ConstraintRelation.greaterOrEqual, 4.0),
      ([2.0, 1.0], ConstraintRelation.greaterOrEqual, 4.0),
    ],
  );

  static LinearProgram get equality => _program(
    'Equality model',
    ObjectiveDirection.maximize,
    [2, 1],
    [
      ([1.0, 1.0], ConstraintRelation.equal, 4.0),
      ([1.0, 0.0], ConstraintRelation.lessOrEqual, 3.0),
    ],
  );

  static LinearProgram get infeasible => _program(
    'Infeasible model',
    ObjectiveDirection.maximize,
    [1, 1],
    [
      ([1.0, 1.0], ConstraintRelation.lessOrEqual, 1.0),
      ([1.0, 1.0], ConstraintRelation.greaterOrEqual, 3.0),
    ],
  );

  static LinearProgram get unbounded => _program(
    'Unbounded model',
    ObjectiveDirection.maximize,
    [1, 1],
    [
      ([1.0, -1.0], ConstraintRelation.greaterOrEqual, 1.0),
    ],
  );

  static LinearProgram get multiple => _program(
    'Multiple optima',
    ObjectiveDirection.maximize,
    [1, 1],
    [
      ([1.0, 1.0], ConstraintRelation.lessOrEqual, 4.0),
      ([1.0, 0.0], ConstraintRelation.lessOrEqual, 4.0),
      ([0.0, 1.0], ConstraintRelation.lessOrEqual, 4.0),
    ],
  );

  static LinearProgram _program(
    String title,
    ObjectiveDirection direction,
    List<num> objective,
    List<(List<double>, ConstraintRelation, double)> constraints,
  ) => LinearProgram(
    title: title,
    direction: direction,
    variables: [
      for (var index = 0; index < objective.length; index++)
        DecisionVariable(id: 'x${index + 1}', name: 'x${index + 1}'),
    ],
    objective: objective.map((value) => value.toDouble()).toList(),
    constraints: [
      for (var index = 0; index < constraints.length; index++)
        LinearConstraint(
          id: 'c${index + 1}',
          name: 'C${index + 1}',
          coefficients: constraints[index].$1,
          relation: constraints[index].$2,
          rhs: constraints[index].$3,
        ),
    ],
  );
}

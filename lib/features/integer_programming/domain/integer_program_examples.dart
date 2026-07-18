import 'package:calcademy/features/integer_programming/domain/integer_program.dart';
import 'package:calcademy/features/integer_programming/domain/optimization_variable_type.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';

/// Ready-made integer programs used both as UI template chips and as the
/// fixtures for [test/features/integer_programming]. Every optimum quoted
/// in the doc comments below was worked out by hand (brute-force
/// enumeration for the binary models, corner-point/branch tracing for the
/// continuous-mixed ones) before the solver existed, so the tests assert
/// against an independently derived expectation rather than the solver's
/// own output.
abstract final class IntegerProgramExamples {
  static List<IntegerProgram> get all => [
    knapsack,
    projectSelection,
    assignment,
    fixedChargeProduction,
    pureIntegerProduction,
    infeasibleInteger,
    fractionalRelaxation,
  ];

  /// 0-1 knapsack. Optimal: x1 = 1, x3 = 1, others 0, Z = 22 (verified by
  /// enumerating all 16 subsets of {4,3,6,5} weights against capacity 10).
  static IntegerProgram get knapsack => IntegerProgram(
    linearModel: LinearProgram(
      title: '0-1 Knapsack',
      direction: ObjectiveDirection.maximize,
      variables: [
        DecisionVariable(id: 'x1', name: 'x1'),
        DecisionVariable(id: 'x2', name: 'x2'),
        DecisionVariable(id: 'x3', name: 'x3'),
        DecisionVariable(id: 'x4', name: 'x4'),
      ],
      objective: [10, 7, 12, 8],
      constraints: [
        LinearConstraint(
          id: 'capacity',
          name: 'Capacity',
          coefficients: [4, 3, 6, 5],
          relation: ConstraintRelation.lessOrEqual,
          rhs: 10,
        ),
      ],
    ),
    variableTypes: {
      'x1': OptimizationVariableType.binary,
      'x2': OptimizationVariableType.binary,
      'x3': OptimizationVariableType.binary,
      'x4': OptimizationVariableType.binary,
    },
  );

  /// Project selection with a budget and a dependency (project 3 needs
  /// project 1). Optimal: x1 = 1, x2 = 1, others 0, Z = 35 (every subset
  /// including x3 needs cost >= 22 > budget 20, so x3 is never selectable;
  /// among the rest {1,2} = 35 beats {1,4} = 30 and {2,4} = 25).
  static IntegerProgram get projectSelection => IntegerProgram(
    linearModel: LinearProgram(
      title: 'Project selection',
      direction: ObjectiveDirection.maximize,
      variables: [
        DecisionVariable(id: 'x1', name: 'x1'),
        DecisionVariable(id: 'x2', name: 'x2'),
        DecisionVariable(id: 'x3', name: 'x3'),
        DecisionVariable(id: 'x4', name: 'x4'),
      ],
      objective: [20, 15, 25, 10],
      constraints: [
        LinearConstraint(
          id: 'budget',
          name: 'Budget',
          coefficients: [10, 8, 12, 6],
          relation: ConstraintRelation.lessOrEqual,
          rhs: 20,
        ),
        LinearConstraint(
          id: 'dependency',
          name: 'x3 requires x1',
          coefficients: [-1, 0, 1, 0],
          relation: ConstraintRelation.lessOrEqual,
          rhs: 0,
        ),
      ],
    ),
    variableTypes: {
      'x1': OptimizationVariableType.binary,
      'x2': OptimizationVariableType.binary,
      'x3': OptimizationVariableType.binary,
      'x4': OptimizationVariableType.binary,
    },
  );

  /// 3x3 assignment problem (minimize cost, each worker exactly one job).
  /// Optimal: worker0-job1, worker1-job0, worker2-job2, Z = 9 (checked
  /// against all 6 permutations of a 3x3 matrix by hand).
  static IntegerProgram get assignment {
    const cost = [
      [9.0, 2.0, 7.0],
      [6.0, 4.0, 3.0],
      [5.0, 8.0, 1.0],
    ];
    final variables = <DecisionVariable>[];
    final objective = <double>[];
    for (var worker = 0; worker < 3; worker++) {
      for (var job = 0; job < 3; job++) {
        variables.add(
          DecisionVariable(id: 'x${worker}_$job', name: 'x${worker}_$job'),
        );
        objective.add(cost[worker][job]);
      }
    }
    final constraints = <LinearConstraint>[];
    for (var worker = 0; worker < 3; worker++) {
      constraints.add(
        LinearConstraint(
          id: 'worker$worker',
          name: 'Worker $worker → exactly one job',
          coefficients: [
            for (var w = 0; w < 3; w++)
              for (var j = 0; j < 3; j++) w == worker ? 1.0 : 0.0,
          ],
          relation: ConstraintRelation.equal,
          rhs: 1,
        ),
      );
    }
    for (var job = 0; job < 3; job++) {
      constraints.add(
        LinearConstraint(
          id: 'job$job',
          name: 'Job $job ← exactly one worker',
          coefficients: [
            for (var w = 0; w < 3; w++)
              for (var j = 0; j < 3; j++) j == job ? 1.0 : 0.0,
          ],
          relation: ConstraintRelation.equal,
          rhs: 1,
        ),
      );
    }
    return IntegerProgram(
      linearModel: LinearProgram(
        title: 'Assignment (3x3)',
        direction: ObjectiveDirection.minimize,
        variables: variables,
        objective: objective,
        constraints: constraints,
      ),
      variableTypes: {
        for (final variable in variables)
          variable.id: OptimizationVariableType.binary,
      },
    );
  }

  /// Fixed-charge production: `x <= M*y` ties production `x` to the
  /// on/off decision `y`, with M = 6 set to the production capacity itself
  /// (the tightest safe value - any larger M would let x exceed capacity
  /// once y = 1, any smaller M would cut off feasible production).
  /// Optimal: y = 1, x = 6, Z = 4*6 - 15 = 9 (checked by hand: profit is
  /// 9*y for y in [0,1], so y = 1 is optimal even at the LP relaxation).
  static IntegerProgram get fixedChargeProduction => IntegerProgram(
    linearModel: LinearProgram(
      title: 'Fixed-charge production',
      direction: ObjectiveDirection.maximize,
      variables: [
        DecisionVariable(id: 'x', name: 'x'),
        DecisionVariable(id: 'y', name: 'y'),
      ],
      objective: [4, -15],
      constraints: [
        LinearConstraint(
          id: 'capacity',
          name: 'Capacity',
          coefficients: [1, 0],
          relation: ConstraintRelation.lessOrEqual,
          rhs: 6,
        ),
        LinearConstraint(
          id: 'link',
          name: 'x ≤ M·y (M = 6)',
          coefficients: [1, -6],
          relation: ConstraintRelation.lessOrEqual,
          rhs: 0,
        ),
      ],
    ),
    variableTypes: {
      'x': OptimizationVariableType.integer,
      'y': OptimizationVariableType.binary,
    },
  );

  /// Pure integer product mix (no binaries). The LP relaxation optimum is
  /// the fractional vertex (3, 1.5) with Z = 21, but the true integer
  /// optimum is (4, 0) with Z = 20 - simple rounding of the relaxation
  /// would guess (3, 2) or (3, 1), both worse or infeasible, so this
  /// example specifically exercises real branching. Verified by
  /// enumerating every integer point under both constraints by hand.
  static IntegerProgram get pureIntegerProduction => IntegerProgram(
    linearModel: LinearProgram(
      title: 'Pure integer product mix',
      direction: ObjectiveDirection.maximize,
      variables: [
        DecisionVariable(id: 'x1', name: 'x1'),
        DecisionVariable(id: 'x2', name: 'x2'),
      ],
      objective: [5, 4],
      constraints: [
        LinearConstraint(
          id: 'material',
          name: 'Material',
          coefficients: [6, 4],
          relation: ConstraintRelation.lessOrEqual,
          rhs: 24,
        ),
        LinearConstraint(
          id: 'labor',
          name: 'Labor',
          coefficients: [1, 2],
          relation: ConstraintRelation.lessOrEqual,
          rhs: 6,
        ),
      ],
    ),
    variableTypes: {
      'x1': OptimizationVariableType.integer,
      'x2': OptimizationVariableType.integer,
    },
  );

  /// LP-feasible but integer-infeasible: the equality forces
  /// `x1 + x2 = 3.5`, which no pair of integers can satisfy, even though
  /// the LP relaxation itself is feasible (e.g. x1 = 3.5, x2 = 0).
  static IntegerProgram get infeasibleInteger => IntegerProgram(
    linearModel: LinearProgram(
      title: 'Infeasible integer model',
      direction: ObjectiveDirection.maximize,
      variables: [
        DecisionVariable(id: 'x1', name: 'x1'),
        DecisionVariable(id: 'x2', name: 'x2'),
      ],
      objective: [1, 1],
      constraints: [
        LinearConstraint(
          id: 'cap',
          name: 'Capacity',
          coefficients: [1, 1],
          relation: ConstraintRelation.lessOrEqual,
          rhs: 5,
        ),
        LinearConstraint(
          id: 'parity',
          name: 'Odd total (×2)',
          coefficients: [2, 2],
          relation: ConstraintRelation.equal,
          rhs: 7,
        ),
      ],
    ),
    variableTypes: {
      'x1': OptimizationVariableType.integer,
      'x2': OptimizationVariableType.integer,
    },
  );

  /// The smallest possible "needs one branch" example: the LP relaxation
  /// optimum is x1 = 2.5 (Z = 2.5); branching x1 <= 2 gives the true
  /// integer optimum Z = 2, while x1 >= 3 is immediately infeasible
  /// (2 * 3 = 6 > 5).
  static IntegerProgram get fractionalRelaxation => IntegerProgram(
    linearModel: LinearProgram(
      title: 'Fractional relaxation',
      direction: ObjectiveDirection.maximize,
      variables: [DecisionVariable(id: 'x1', name: 'x1')],
      objective: [1],
      constraints: [
        LinearConstraint(
          id: 'cap',
          name: 'Capacity',
          coefficients: [2],
          relation: ConstraintRelation.lessOrEqual,
          rhs: 5,
        ),
      ],
    ),
    variableTypes: {'x1': OptimizationVariableType.integer},
  );
}

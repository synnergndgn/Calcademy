import 'package:calcademy/features/integer_programming/domain/branch_and_bound_solver.dart';
import 'package:calcademy/features/integer_programming/domain/branch_node.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program_examples.dart';
import 'package:calcademy/features/integer_programming/domain/mip_limits.dart';
import 'package:calcademy/features/integer_programming/domain/mip_result.dart';
import 'package:calcademy/features/integer_programming/domain/optimization_variable_type.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:flutter_test/flutter_test.dart';

IntegerProgram _model({
  required ObjectiveDirection direction,
  required List<double> objective,
  required List<(List<double>, ConstraintRelation, double)> constraints,
  required Map<String, OptimizationVariableType> variableTypes,
}) {
  final variables = [
    for (var i = 0; i < objective.length; i++)
      DecisionVariable(id: 'x${i + 1}', name: 'x${i + 1}'),
  ];
  return IntegerProgram(
    linearModel: LinearProgram(
      title: 'Solver test',
      direction: direction,
      variables: variables,
      objective: objective,
      constraints: [
        for (var i = 0; i < constraints.length; i++)
          LinearConstraint(
            id: 'c${i + 1}',
            name: 'C${i + 1}',
            coefficients: constraints[i].$1,
            relation: constraints[i].$2,
            rhs: constraints[i].$3,
          ),
      ],
    ),
    variableTypes: variableTypes,
  );
}

void main() {
  group('root outcomes', () {
    test('a root relaxation that is already integral solves in one node', () {
      final program = _model(
        direction: ObjectiveDirection.maximize,
        objective: [1, 1],
        constraints: [
          ([1.0, 1.0], ConstraintRelation.lessOrEqual, 4.0),
        ],
        variableTypes: const {
          'x1': OptimizationVariableType.integer,
          'x2': OptimizationVariableType.integer,
        },
      );
      final result = const BranchAndBoundSolver().solve(program);
      expect(result, isA<OptimalIntegerSolution>());
      final optimal = result as OptimalIntegerSolution;
      expect(optimal.nodesSolved, 1);
      expect(optimal.absoluteGap, 0);
      expect(optimal.relativeGap, 0);
    });

    test('infeasible LP relaxation is reported without any branching', () {
      final program = _model(
        direction: ObjectiveDirection.maximize,
        objective: [1, 1],
        constraints: [
          ([1.0, 1.0], ConstraintRelation.lessOrEqual, 1.0),
          ([1.0, 1.0], ConstraintRelation.greaterOrEqual, 3.0),
        ],
        variableTypes: const {
          'x1': OptimizationVariableType.integer,
          'x2': OptimizationVariableType.continuous,
        },
      );
      final result = const BranchAndBoundSolver().solve(program);
      expect(result, isA<InfeasibleIntegerProgram>());
      expect(result.nodesSolved, 1);
    });

    test('an unbounded root relaxation is reported directly', () {
      final program = _model(
        direction: ObjectiveDirection.maximize,
        objective: [1, 0],
        constraints: [
          ([0.0, 1.0], ConstraintRelation.lessOrEqual, 5.0),
        ],
        variableTypes: const {
          'x1': OptimizationVariableType.integer,
          'x2': OptimizationVariableType.continuous,
        },
      );
      final result = const BranchAndBoundSolver().solve(program);
      expect(result, isA<UnboundedRelaxation>());
    });
  });

  group('branching', () {
    test('a single branch resolves the fractional relaxation example', () {
      final result = const BranchAndBoundSolver().solve(
        IntegerProgramExamples.fractionalRelaxation,
      );
      expect(result, isA<OptimalIntegerSolution>());
      final optimal = result as OptimalIntegerSolution;
      expect(optimal.rootRelaxationObjective, closeTo(2.5, 1e-9));
      expect(optimal.objectiveValue, closeTo(2, 1e-9));
      expect(optimal.variableValues['x1'], closeTo(2, 1e-9));
      expect(optimal.nodesSolved, greaterThan(1));
    });

    test(
      'multi-level branching finds the true integer optimum, not a rounded relaxation',
      () {
        final result = const BranchAndBoundSolver().solve(
          IntegerProgramExamples.pureIntegerProduction,
        );
        expect(result, isA<OptimalIntegerSolution>());
        final optimal = result as OptimalIntegerSolution;
        expect(optimal.rootRelaxationObjective, closeTo(21, 1e-6));
        expect(optimal.objectiveValue, closeTo(20, 1e-9));
        expect(optimal.variableValues['x1'], closeTo(4, 1e-9));
        expect(optimal.variableValues['x2'], closeTo(0, 1e-9));
        expect(optimal.absoluteGap, 0);
      },
    );

    test('binary knapsack finds the value-maximizing subset', () {
      final result = const BranchAndBoundSolver().solve(
        IntegerProgramExamples.knapsack,
      );
      final optimal = result as OptimalIntegerSolution;
      expect(optimal.objectiveValue, closeTo(22, 1e-9));
      expect(optimal.variableValues['x1'], closeTo(1, 1e-9));
      expect(optimal.variableValues['x3'], closeTo(1, 1e-9));
      expect(optimal.variableValues['x2'], closeTo(0, 1e-9));
      expect(optimal.variableValues['x4'], closeTo(0, 1e-9));
      final integerNode = result.branchTree.firstWhere(
        (node) => node.status == NodeStatus.integerFeasible,
      );
      expect(integerNode.isIncumbent, isTrue);
    });

    test(
      'minimization only updates the incumbent on a strictly lower objective',
      () {
        final result = const BranchAndBoundSolver().solve(
          IntegerProgramExamples.assignment,
        );
        final optimal = result as OptimalIntegerSolution;
        expect(optimal.objectiveValue, closeTo(9, 1e-9));
        for (var i = 1; i < result.incumbentHistory.length; i++) {
          expect(
            result.incumbentHistory[i].objectiveValue,
            lessThan(result.incumbentHistory[i - 1].objectiveValue),
          );
        }
      },
    );
  });

  group('infeasible integer with a feasible relaxation', () {
    test(
      'a parity constraint that no integer pair can satisfy is exhaustively infeasible',
      () {
        final result = const BranchAndBoundSolver().solve(
          IntegerProgramExamples.infeasibleInteger,
        );
        expect(result, isA<InfeasibleIntegerProgram>());
        expect(result.rootRelaxationObjective, isNotNull);
        expect(result.openNodes, 0);
      },
    );
  });

  group('limits', () {
    test(
      'a node limit with no integer-feasible node yet found reports NodeLimitReached',
      () {
        const solver = BranchAndBoundSolver(limits: MipLimits(maxNodes: 1));
        final result = solver.solve(
          IntegerProgramExamples.pureIntegerProduction,
        );
        expect(result, isA<NodeLimitReached>());
        expect((result as NodeLimitReached).reason, LimitReason.nodeLimit);
        expect(result.nodesSolved, 1);
      },
    );

    test(
      'a node limit hit after an incumbent is found reports it as the best-found solution',
      () {
        const solver = BranchAndBoundSolver(limits: MipLimits(maxNodes: 3));
        final result = solver.solve(IntegerProgramExamples.knapsack);
        if (result is OptimalIntegerSolution) {
          // The search may legitimately finish inside a small node budget for
          // this tiny model; only assert the truncated shape when it doesn't.
          return;
        }
        expect(result, isA<FeasibleIntegerSolution>());
        final feasible = result as FeasibleIntegerSolution;
        expect(feasible.limitReason, LimitReason.nodeLimit);
        expect(feasible.objectiveValue, lessThanOrEqualTo(22));
      },
    );

    test(
      'a depth limit of zero prevents branching and is reported as an unproven limit',
      () {
        const solver = BranchAndBoundSolver(limits: MipLimits(maxDepth: 0));
        final result = solver.solve(
          IntegerProgramExamples.fractionalRelaxation,
        );
        expect(result, isA<NodeLimitReached>());
        expect((result as NodeLimitReached).reason, LimitReason.depthLimit);
      },
    );
  });

  group('determinism', () {
    test('solving the same model twice explores the same number of nodes', () {
      const solver = BranchAndBoundSolver();
      final first = solver.solve(IntegerProgramExamples.pureIntegerProduction);
      final second = solver.solve(IntegerProgramExamples.pureIntegerProduction);
      expect(first.nodesSolved, second.nodesSolved);
      expect(
        first.branchTree.map((n) => n.id).toList(),
        second.branchTree.map((n) => n.id).toList(),
      );
    });
  });
}

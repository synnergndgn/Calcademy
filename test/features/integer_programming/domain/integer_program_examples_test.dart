import 'package:calcademy/features/integer_programming/domain/branch_and_bound_solver.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program_examples.dart';
import 'package:calcademy/features/integer_programming/domain/mip_result.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every expected value here was derived independently of the solver (see
/// the doc comments in `integer_program_examples.dart` for the hand
/// calculation), not copied from a prior run's output.
void main() {
  const solver = BranchAndBoundSolver();

  test('0-1 knapsack: optimum is x1=1, x3=1, Z=22', () {
    final result =
        solver.solve(IntegerProgramExamples.knapsack) as OptimalIntegerSolution;
    expect(result.objectiveValue, closeTo(22, 1e-9));
    expect(result.variableValues['x1'], closeTo(1, 1e-9));
    expect(result.variableValues['x2'], closeTo(0, 1e-9));
    expect(result.variableValues['x3'], closeTo(1, 1e-9));
    expect(result.variableValues['x4'], closeTo(0, 1e-9));
  });

  test('project selection: optimum is x1=1, x2=1, Z=35', () {
    final result =
        solver.solve(IntegerProgramExamples.projectSelection)
            as OptimalIntegerSolution;
    expect(result.objectiveValue, closeTo(35, 1e-9));
    expect(result.variableValues['x1'], closeTo(1, 1e-9));
    expect(result.variableValues['x2'], closeTo(1, 1e-9));
    expect(result.variableValues['x3'], closeTo(0, 1e-9));
  });

  test(
    'assignment (3x3): optimum cost is 9 via worker0-job1, worker1-job0, worker2-job2',
    () {
      final result =
          solver.solve(IntegerProgramExamples.assignment)
              as OptimalIntegerSolution;
      expect(result.objectiveValue, closeTo(9, 1e-9));
      expect(result.variableValues['x0_1'], closeTo(1, 1e-9));
      expect(result.variableValues['x1_0'], closeTo(1, 1e-9));
      expect(result.variableValues['x2_2'], closeTo(1, 1e-9));
      // Every worker assigned exactly one job and vice versa.
      for (var worker = 0; worker < 3; worker++) {
        var sum = 0.0;
        for (var job = 0; job < 3; job++) {
          sum += result.variableValues['x${worker}_$job']!;
        }
        expect(sum, closeTo(1, 1e-9));
      }
    },
  );

  test('fixed-charge production: optimum is y=1, x=6, Z=9', () {
    final result =
        solver.solve(IntegerProgramExamples.fixedChargeProduction)
            as OptimalIntegerSolution;
    expect(result.objectiveValue, closeTo(9, 1e-9));
    expect(result.variableValues['x'], closeTo(6, 1e-9));
    expect(result.variableValues['y'], closeTo(1, 1e-9));
  });

  test(
    'pure integer product mix: optimum is (4, 0), Z=20, not the rounded relaxation',
    () {
      final result =
          solver.solve(IntegerProgramExamples.pureIntegerProduction)
              as OptimalIntegerSolution;
      expect(result.rootRelaxationObjective, closeTo(21, 1e-6));
      expect(result.objectiveValue, closeTo(20, 1e-9));
      expect(result.variableValues['x1'], closeTo(4, 1e-9));
      expect(result.variableValues['x2'], closeTo(0, 1e-9));
    },
  );

  test('infeasible integer model: LP-feasible but no integer point exists', () {
    final result = solver.solve(IntegerProgramExamples.infeasibleInteger);
    expect(result, isA<InfeasibleIntegerProgram>());
    expect(result.rootRelaxationObjective, isNotNull);
  });

  test(
    'fractional relaxation: LP optimum 2.5 branches down to the integer optimum 2',
    () {
      final result =
          solver.solve(IntegerProgramExamples.fractionalRelaxation)
              as OptimalIntegerSolution;
      expect(result.rootRelaxationObjective, closeTo(2.5, 1e-9));
      expect(result.objectiveValue, closeTo(2, 1e-9));
    },
  );

  test('all() exposes exactly the seven documented examples', () {
    expect(IntegerProgramExamples.all, hasLength(7));
  });
}

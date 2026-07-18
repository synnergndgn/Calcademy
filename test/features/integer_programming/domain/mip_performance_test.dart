import 'package:calcademy/features/integer_programming/domain/branch_and_bound_solver.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program_examples.dart';
import 'package:calcademy/features/integer_programming/domain/mip_result.dart';
import 'package:calcademy/features/integer_programming/domain/optimization_variable_type.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 10-binary-variable knapsack stress model; forces real branching
/// (fractional relaxation) without being pathological.
IntegerProgram _tenBinaryKnapsack() {
  const values = [12.0, 7.0, 11.0, 8.0, 9.0, 6.0, 13.0, 5.0, 10.0, 4.0];
  const weights = [5.0, 3.0, 6.0, 4.0, 5.0, 2.0, 7.0, 3.0, 5.0, 2.0];
  final variables = [
    for (var i = 0; i < 10; i++) DecisionVariable(id: 'x$i', name: 'x$i'),
  ];
  return IntegerProgram(
    linearModel: LinearProgram(
      title: 'Stress knapsack',
      direction: ObjectiveDirection.maximize,
      variables: variables,
      objective: values,
      constraints: [
        LinearConstraint(
          id: 'cap',
          name: 'Capacity',
          coefficients: weights,
          relation: ConstraintRelation.lessOrEqual,
          rhs: 20,
        ),
      ],
    ),
    variableTypes: {
      for (final v in variables) v.id: OptimizationVariableType.binary,
    },
  );
}

void main() {
  test('bounded MIP workloads complete promptly and report clear timings', () {
    const solver = BranchAndBoundSolver();
    final timings = <String, int>{};
    final stats = <String, String>{};

    void run(String label, IntegerProgram program) {
      final stopwatch = Stopwatch()..start();
      final result = solver.solve(program);
      stopwatch.stop();
      timings[label] = stopwatch.elapsedMicroseconds;
      stats[label] =
          'nodes=${result.nodesSolved} depth=${result.maxDepthReached} '
          'prunes=${result.pruneCounts.values.fold(0, (a, b) => a + b)}';
      // Sanity: each workload must terminate with a definitive status
      // (nothing here should hit a node or iteration limit).
      expect(
        result,
        anyOf(isA<OptimalIntegerSolution>(), isA<InfeasibleIntegerProgram>()),
        reason: label,
      );
    }

    run('knapsack4', IntegerProgramExamples.knapsack);
    run('knapsack10', _tenBinaryKnapsack());
    run('assignment3x3', IntegerProgramExamples.assignment);
    run('mixedFixedCharge', IntegerProgramExamples.fixedChargeProduction);
    run('pureInteger', IntegerProgramExamples.pureIntegerProduction);
    run('integerInfeasible', IntegerProgramExamples.infeasibleInteger);

    // Unit is explicitly microseconds (µs); 1000 µs = 1 ms.
    final line = timings.entries.map((e) => '${e.key}=${e.value}').join(' ');
    // ignore: avoid_print
    print('mip-performance-us $line');
    for (final entry in stats.entries) {
      // ignore: avoid_print
      print('mip-stats ${entry.key}: ${entry.value}');
    }

    // Generous ceilings: these exist to catch complexity regressions (an
    // accidental exponential blow-up), not to benchmark the host machine.
    expect(timings['knapsack4']!, lessThan(2000000));
    expect(timings['knapsack10']!, lessThan(10000000));
    expect(timings['assignment3x3']!, lessThan(10000000));
  });
}

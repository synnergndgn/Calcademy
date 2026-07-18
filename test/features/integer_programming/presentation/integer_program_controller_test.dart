import 'dart:async';

import 'package:calcademy/features/integer_programming/domain/branch_and_bound_solver.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program_examples.dart';
import 'package:calcademy/features/integer_programming/domain/mip_result.dart';
import 'package:calcademy/features/integer_programming/presentation/integer_program_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises the generation guard directly at the controller level, with a
/// fake executor whose completion order the test controls - the reliable
/// way to prove a slow first solve can never overwrite a later one.
void main() {
  test('a late first result does not overwrite a newer solve', () async {
    final gates = <Completer<void>>[Completer(), Completer()];
    var callIndex = 0;
    final container = ProviderContainer(
      overrides: [
        integerProgramSolveExecutorProvider.overrideWithValue((program) async {
          final index = callIndex++;
          await gates[index].future;
          return const BranchAndBoundSolver().solve(program);
        }),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      integerProgramWorkspaceProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(integerProgramWorkspaceProvider.notifier);

    final first = controller.solve(IntegerProgramExamples.fractionalRelaxation);
    final second = controller.solve(IntegerProgramExamples.knapsack);

    // Finish the *second* request first, then release the stale first one.
    gates[1].complete();
    await second;
    final settled = container.read(integerProgramWorkspaceProvider);
    expect(settled.result, isA<OptimalIntegerSolution>());
    expect(
      (settled.result! as OptimalIntegerSolution).objectiveValue,
      closeTo(22, 1e-9),
    );

    gates[0].complete();
    await first;
    final afterStale = container.read(integerProgramWorkspaceProvider);
    expect(
      (afterStale.result! as OptimalIntegerSolution).objectiveValue,
      closeTo(22, 1e-9),
      reason: 'the stale fractionalRelaxation result (Z=2) must be dropped',
    );
    expect(afterStale.program!.title, IntegerProgramExamples.knapsack.title);
  });

  test('clear() invalidates an in-flight solve', () async {
    final gate = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        integerProgramSolveExecutorProvider.overrideWithValue((program) async {
          await gate.future;
          return const BranchAndBoundSolver().solve(program);
        }),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      integerProgramWorkspaceProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(integerProgramWorkspaceProvider.notifier);

    final pending = controller.solve(IntegerProgramExamples.knapsack);
    expect(container.read(integerProgramWorkspaceProvider).loading, isTrue);

    controller.clear();
    gate.complete();
    await pending;

    final state = container.read(integerProgramWorkspaceProvider);
    expect(state.result, isNull);
    expect(state.loading, isFalse);
  });

  test('an executor failure surfaces as an error state, not a crash', () async {
    final container = ProviderContainer(
      overrides: [
        integerProgramSolveExecutorProvider.overrideWithValue(
          (program) async => throw StateError('boom'),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      integerProgramWorkspaceProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(integerProgramWorkspaceProvider.notifier);

    await controller.solve(IntegerProgramExamples.knapsack);
    final state = container.read(integerProgramWorkspaceProvider);
    expect(state.error, isNotNull);
    expect(state.loading, isFalse);
    expect(state.result, isNull);
  });

  test('IntegerProgram survives an isolate-style send/decode round-trip', () {
    // compute() requires sendable data; JSON round-tripping is a strict
    // superset of that requirement and doubles as the persistence check.
    final IntegerProgram program = IntegerProgramExamples.fixedChargeProduction;
    final decoded = IntegerProgram.fromJson(program.toJson());
    final result = const BranchAndBoundSolver().solve(decoded);
    expect(result, isA<OptimalIntegerSolution>());
    expect((result as OptimalIntegerSolution).objectiveValue, closeTo(9, 1e-9));
  });
}

import 'package:calcademy/features/integer_programming/domain/branch_and_bound_solver.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program.dart';
import 'package:calcademy/features/integer_programming/domain/mip_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Runs on a background isolate via [compute]. Must stay a top-level
/// function (not a closure) and take/return only sendable, immutable data -
/// [IntegerProgram] and [MipResult] are plain data classes with no
/// closures, streams or platform handles, so they cross the isolate
/// boundary safely.
MipResult runBranchAndBoundInIsolate(IntegerProgram program) =>
    const BranchAndBoundSolver().solve(program);

/// How the controller actually runs a solve. Defaults to the real
/// background isolate; widget tests override this to call the solver
/// in-place instead, since spawning a genuine OS isolate from inside
/// `flutter test`'s fake-async harness is slow and can make
/// `pumpAndSettle` time out for reasons that have nothing to do with the
/// behaviour under test. The solver logic itself is identical either way -
/// only the "where it runs" hop is swapped.
final integerProgramSolveExecutorProvider =
    Provider<Future<MipResult> Function(IntegerProgram)>(
      (ref) =>
          (program) => compute(runBranchAndBoundInIsolate, program),
    );

final integerProgramWorkspaceProvider =
    NotifierProvider.autoDispose<
      IntegerProgramWorkspaceController,
      IntegerProgramWorkspaceState
    >(IntegerProgramWorkspaceController.new);

class IntegerProgramWorkspaceState {
  const IntegerProgramWorkspaceState({
    this.loading = false,
    this.program,
    this.result,
    this.error,
    this.activeSavedId,
  });

  final bool loading;
  final IntegerProgram? program;
  final MipResult? result;
  final String? error;
  final String? activeSavedId;
}

/// Mirrors [LinearProgramWorkspaceController]'s generation-guard pattern:
/// `compute` cannot be cancelled mid-flight, so a stale response (the user
/// edited the model, solved again, or left the page while a solve was
/// still running) is simply dropped instead of overwriting newer state.
class IntegerProgramWorkspaceController
    extends Notifier<IntegerProgramWorkspaceState> {
  var _generation = 0;

  @override
  IntegerProgramWorkspaceState build() {
    ref.onDispose(() => _generation++);
    return const IntegerProgramWorkspaceState();
  }

  Future<void> solve(IntegerProgram program, {String? savedId}) async {
    final generation = ++_generation;
    state = IntegerProgramWorkspaceState(
      loading: true,
      program: program,
      activeSavedId: savedId ?? state.activeSavedId,
    );
    try {
      final result = await ref.read(integerProgramSolveExecutorProvider)(
        program,
      );
      if (generation != _generation) return;
      state = IntegerProgramWorkspaceState(
        program: program,
        result: result,
        activeSavedId: savedId ?? state.activeSavedId,
      );
    } on Object catch (error) {
      if (generation != _generation) return;
      state = IntegerProgramWorkspaceState(
        program: program,
        error: error.toString(),
      );
    }
  }

  void clear() {
    _generation++;
    state = const IntegerProgramWorkspaceState();
  }
}

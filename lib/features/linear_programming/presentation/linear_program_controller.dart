import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program_result.dart';
import 'package:calcademy/features/linear_programming/domain/simplex_solver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final simplexSolverProvider = Provider<SimplexSolver>(
  (ref) => const SimplexSolver(),
);

final linearProgramWorkspaceProvider =
    NotifierProvider.autoDispose<
      LinearProgramWorkspaceController,
      LinearProgramWorkspaceState
    >(LinearProgramWorkspaceController.new);

class LinearProgramWorkspaceState {
  const LinearProgramWorkspaceState({
    this.loading = false,
    this.program,
    this.result,
    this.error,
    this.activeSavedId,
  });

  final bool loading;
  final LinearProgram? program;
  final LinearProgramResult? result;
  final String? error;
  final String? activeSavedId;
}

class LinearProgramWorkspaceController
    extends Notifier<LinearProgramWorkspaceState> {
  var _generation = 0;

  @override
  LinearProgramWorkspaceState build() {
    ref.onDispose(() => _generation++);
    return const LinearProgramWorkspaceState();
  }

  Future<void> solve(LinearProgram program, {String? savedId}) async {
    final generation = ++_generation;
    state = LinearProgramWorkspaceState(
      loading: true,
      program: program,
      activeSavedId: savedId ?? state.activeSavedId,
    );
    await Future<void>.delayed(Duration.zero);
    try {
      final result = ref.read(simplexSolverProvider).solve(program);
      if (generation != _generation) return;
      state = LinearProgramWorkspaceState(
        program: program,
        result: result,
        activeSavedId: savedId ?? state.activeSavedId,
      );
    } on Object catch (error) {
      if (generation != _generation) return;
      state = LinearProgramWorkspaceState(
        program: program,
        error: error.toString(),
      );
    }
  }

  void clear() {
    _generation++;
    state = const LinearProgramWorkspaceState();
  }
}

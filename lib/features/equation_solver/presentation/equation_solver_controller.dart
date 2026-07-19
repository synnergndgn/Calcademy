import 'package:calcademy/features/equation_solver/application/linear_system_service.dart';
import 'package:calcademy/features/equation_solver/application/numerical_method_service.dart';
import 'package:calcademy/features/equation_solver/application/single_equation_service.dart';
import 'package:calcademy/features/equation_solver/domain/equation_solver_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final singleEquationServiceProvider = Provider<SingleEquationService>(
  (ref) => const SingleEquationService(),
);
final numericalMethodServiceProvider = Provider<NumericalMethodService>(
  (ref) => const NumericalMethodService(),
);
final linearSystemServiceProvider = Provider<LinearSystemService>(
  (ref) => const LinearSystemService(),
);

/// One shared workspace state for the three solver tabs. Solves are fast
/// (hundreds of evaluations at most), but the generation counter still
/// guards against a rapid double-tap racing two solves: only the latest
/// request may write its result into state.
class EquationWorkspaceState {
  const EquationWorkspaceState({
    this.loading = false,
    this.singleResult,
    this.systemResult,
    this.methodResult,
  });

  final bool loading;
  final SingleEquationResult? singleResult;
  final LinearSystemServiceResult? systemResult;
  final NumericalMethodResult? methodResult;

  EquationWorkspaceState copyWith({
    bool? loading,
    SingleEquationResult? singleResult,
    LinearSystemServiceResult? systemResult,
    NumericalMethodResult? methodResult,
    bool clearResults = false,
  }) => EquationWorkspaceState(
    loading: loading ?? this.loading,
    singleResult: clearResults ? null : singleResult ?? this.singleResult,
    systemResult: clearResults ? null : systemResult ?? this.systemResult,
    methodResult: clearResults ? null : methodResult ?? this.methodResult,
  );
}

final equationWorkspaceProvider =
    NotifierProvider.autoDispose<
      EquationWorkspaceController,
      EquationWorkspaceState
    >(EquationWorkspaceController.new);

class EquationWorkspaceController extends Notifier<EquationWorkspaceState> {
  var _generation = 0;

  @override
  EquationWorkspaceState build() {
    ref.onDispose(() => _generation++);
    return const EquationWorkspaceState();
  }

  Future<void> solveSingle(
    String input, {
    required double scanMin,
    required double scanMax,
  }) async {
    final generation = ++_generation;
    state = state.copyWith(loading: true);
    await Future<void>.delayed(Duration.zero);
    final result = ref
        .read(singleEquationServiceProvider)
        .solve(input, scanMin: scanMin, scanMax: scanMax);
    if (generation != _generation) return;
    state = EquationWorkspaceState(singleResult: result);
  }

  Future<void> solveSystem(
    List<List<double>> coefficients,
    List<double> rhs,
  ) async {
    final generation = ++_generation;
    state = state.copyWith(loading: true);
    await Future<void>.delayed(Duration.zero);
    final result = ref
        .read(linearSystemServiceProvider)
        .solve(coefficients, rhs);
    if (generation != _generation) return;
    state = EquationWorkspaceState(systemResult: result);
  }

  Future<void> runMethod(
    NumericalMethodResult Function(NumericalMethodService service) run,
  ) async {
    final generation = ++_generation;
    state = state.copyWith(loading: true);
    await Future<void>.delayed(Duration.zero);
    final result = run(ref.read(numericalMethodServiceProvider));
    if (generation != _generation) return;
    state = EquationWorkspaceState(methodResult: result);
  }

  void clear() {
    _generation++;
    state = const EquationWorkspaceState();
  }
}

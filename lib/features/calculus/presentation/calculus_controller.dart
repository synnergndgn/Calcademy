import 'package:calcademy/features/calculus/application/differentiation_service.dart';
import 'package:calcademy/features/calculus/application/function_analysis_service.dart';
import 'package:calcademy/features/calculus/application/integration_service.dart';
import 'package:calcademy/features/calculus/domain/calculus_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final differentiationServiceProvider = Provider<DifferentiationService>(
  (ref) => const DifferentiationService(),
);
final integrationServiceProvider = Provider<IntegrationService>(
  (ref) => const IntegrationService(),
);
final functionAnalysisServiceProvider = Provider<FunctionAnalysisService>(
  (ref) => const FunctionAnalysisService(),
);

/// Workspace state for the three calculus tabs. Solves are quick, but the
/// generation counter still guarantees a rapid double-tap can never let a
/// stale result overwrite a newer one - the same guard every other
/// Calcademy workspace uses.
class CalculusWorkspaceState {
  const CalculusWorkspaceState({this.loading = false, this.result});

  final bool loading;
  final CalculusResult? result;
}

final calculusWorkspaceProvider =
    NotifierProvider.autoDispose<
      CalculusWorkspaceController,
      CalculusWorkspaceState
    >(CalculusWorkspaceController.new);

class CalculusWorkspaceController extends Notifier<CalculusWorkspaceState> {
  var _generation = 0;

  @override
  CalculusWorkspaceState build() {
    ref.onDispose(() => _generation++);
    return const CalculusWorkspaceState();
  }

  Future<void> run(CalculusResult Function() solve) async {
    final generation = ++_generation;
    state = const CalculusWorkspaceState(loading: true);
    await Future<void>.delayed(Duration.zero);
    final result = solve();
    if (generation != _generation) return;
    state = CalculusWorkspaceState(result: result);
  }

  void clear() {
    _generation++;
    state = const CalculusWorkspaceState();
  }
}

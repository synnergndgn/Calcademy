import 'package:calcademy/features/operations_research/application/assignment_solver.dart';
import 'package:calcademy/features/operations_research/application/cpm_pert_service.dart';
import 'package:calcademy/features/operations_research/application/goal_programming_service.dart';
import 'package:calcademy/features/operations_research/application/transportation_solver.dart';
import 'package:calcademy/features/operations_research/domain/goal_programming_problem.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_problem.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';
import 'package:calcademy/features/operations_research/domain/project_network_problem.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transportationSolverProvider = Provider<TransportationSolver>(
  (ref) => const TransportationSolver(),
);
final assignmentSolverProvider = Provider<AssignmentSolver>(
  (ref) => const AssignmentSolver(),
);
final goalProgrammingServiceProvider = Provider<GoalProgrammingService>(
  (ref) => const GoalProgrammingService(),
);
final cpmPertServiceProvider = Provider<CpmPertService>(
  (ref) => const CpmPertService(),
);

final operationsResearchProvider =
    NotifierProvider.autoDispose<
      OperationsResearchController,
      OperationsResearchState
    >(OperationsResearchController.new);

class OperationsResearchState {
  const OperationsResearchState({this.loading = false, this.result});

  final bool loading;
  final OperationsResearchResult? result;
}

class OperationsResearchController extends Notifier<OperationsResearchState> {
  var _generation = 0;

  @override
  OperationsResearchState build() {
    ref.onDispose(() => _generation++);
    return const OperationsResearchState();
  }

  Future<void> solveTransportation(TransportationProblem problem) async {
    final generation = ++_generation;
    state = const OperationsResearchState(loading: true);
    await Future<void>.delayed(Duration.zero);
    final result = ref.read(transportationSolverProvider).solve(problem);
    if (generation == _generation) {
      state = OperationsResearchState(result: result);
    }
  }

  Future<void> solveAssignment(AssignmentProblem problem) async {
    final generation = ++_generation;
    state = const OperationsResearchState(loading: true);
    await Future<void>.delayed(Duration.zero);
    final result = ref.read(assignmentSolverProvider).solve(problem);
    if (generation == _generation) {
      state = OperationsResearchState(result: result);
    }
  }

  Future<void> solveGoalProgramming(GoalProgrammingProblem problem) async {
    final generation = ++_generation;
    state = const OperationsResearchState(loading: true);
    await Future<void>.delayed(Duration.zero);
    final result = ref.read(goalProgrammingServiceProvider).solve(problem);
    if (generation == _generation) {
      state = OperationsResearchState(result: result);
    }
  }

  Future<void> solveProjectNetwork(ProjectNetworkProblem problem) async {
    final generation = ++_generation;
    state = const OperationsResearchState(loading: true);
    await Future<void>.delayed(Duration.zero);
    final result = ref.read(cpmPertServiceProvider).solve(problem);
    if (generation == _generation) {
      state = OperationsResearchState(result: result);
    }
  }

  void reportIssue(OperationsResearchIssue issue) {
    _generation++;
    state = OperationsResearchState(
      result: OperationsResearchFailureResult(issue),
    );
  }

  void clear() {
    _generation++;
    state = const OperationsResearchState();
  }
}

import 'dart:math' as math;

import 'package:calcademy/features/operations_research/application/cpm_pert_service.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';
import 'package:calcademy/features/operations_research/domain/project_network_problem.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = CpmPertService();

  test('calculates a simple CPM chain', () {
    final result =
        service.solve(
              ProjectNetworkProblem(
                mode: ProjectScheduleMode.cpm,
                activities: [
                  _cpm('A', 2),
                  _cpm('B', 3, ['A']),
                  _cpm('C', 1, ['B']),
                ],
              ),
            )
            as CpmPertResult;

    expect(result.projectDuration, closeTo(6, 1e-9));
    expect(result.criticalPaths, [
      ['A', 'B', 'C'],
    ]);
    expect(result.activities.every((row) => row.critical), isTrue);
  });

  test('calculates branching forward/backward passes and slack', () {
    final result =
        service.solve(
              ProjectNetworkProblem(
                mode: ProjectScheduleMode.cpm,
                activities: [
                  _cpm('A', 2),
                  _cpm('B', 4, ['A']),
                  _cpm('C', 2, ['A']),
                  _cpm('D', 3, ['B', 'C']),
                ],
              ),
            )
            as CpmPertResult;
    final rows = {for (final row in result.activities) row.id: row};

    expect(result.projectDuration, closeTo(9, 1e-9));
    expect(rows['D']!.earliestStart, closeTo(6, 1e-9));
    expect(rows['C']!.latestStart, closeTo(4, 1e-9));
    expect(rows['C']!.totalFloat, closeTo(2, 1e-9));
    expect(rows['C']!.freeFloat, closeTo(2, 1e-9));
    expect(result.criticalPaths, [
      ['A', 'B', 'D'],
    ]);
  });

  test('supports disconnected components with a virtual-end warning', () {
    final result =
        service.solve(
              ProjectNetworkProblem(
                mode: ProjectScheduleMode.cpm,
                activities: [_cpm('A', 4), _cpm('B', 2)],
              ),
            )
            as CpmPertResult;

    expect(result.projectDuration, closeTo(4, 1e-9));
    expect(result.warnings, contains('orWarningDisconnectedNetwork'));
    expect(result.criticalActivities, ['A']);
  });

  test('validates duplicate IDs, missing predecessors and cycles', () {
    final duplicate =
        service.solve(
              ProjectNetworkProblem(
                mode: ProjectScheduleMode.cpm,
                activities: [_cpm('A', 1), _cpm('A', 2)],
              ),
            )
            as OperationsResearchFailureResult;
    final missing =
        service.solve(
              ProjectNetworkProblem(
                mode: ProjectScheduleMode.cpm,
                activities: [
                  _cpm('A', 1, ['Z']),
                ],
              ),
            )
            as OperationsResearchFailureResult;
    final cycle =
        service.solve(
              ProjectNetworkProblem(
                mode: ProjectScheduleMode.cpm,
                activities: [
                  _cpm('A', 1, ['B']),
                  _cpm('B', 1, ['A']),
                ],
              ),
            )
            as OperationsResearchFailureResult;

    expect(duplicate.issue, OperationsResearchIssue.duplicateActivityId);
    expect(missing.issue, OperationsResearchIssue.missingPredecessor);
    expect(cycle.issue, OperationsResearchIssue.cyclicNetwork);
  });

  test('validates CPM duration and ordered PERT estimates', () {
    final duration =
        service.solve(
              ProjectNetworkProblem(
                mode: ProjectScheduleMode.cpm,
                activities: [_cpm('A', 0)],
              ),
            )
            as OperationsResearchFailureResult;
    final pert =
        service.solve(
              ProjectNetworkProblem(
                mode: ProjectScheduleMode.pert,
                activities: [_pert('A', 3, 2, 4)],
              ),
            )
            as OperationsResearchFailureResult;

    expect(duration.issue, OperationsResearchIssue.invalidDuration);
    expect(pert.issue, OperationsResearchIssue.invalidPertTimes);
  });

  test('calculates PERT expected duration, variance and critical variance', () {
    final result =
        service.solve(
              ProjectNetworkProblem(
                mode: ProjectScheduleMode.pert,
                activities: [
                  _pert('A', 1, 2, 3),
                  _pert('B', 2, 2, 2, ['A']),
                ],
              ),
            )
            as CpmPertResult;
    final rows = {for (final row in result.activities) row.id: row};

    expect(rows['A']!.duration, closeTo(2, 1e-9));
    expect(rows['A']!.variance, closeTo(1 / 9, 1e-9));
    expect(result.projectDuration, closeTo(4, 1e-9));
    expect(result.projectVariance, closeTo(1 / 9, 1e-9));
    expect(result.projectStandardDeviation, closeTo(1 / 3, 1e-9));
  });

  test('uses the largest critical-path variance when paths tie', () {
    final result =
        service.solve(
              ProjectNetworkProblem(
                mode: ProjectScheduleMode.pert,
                activities: [_pert('A', 1, 2, 3), _pert('B', 2, 2, 2)],
              ),
            )
            as CpmPertResult;

    expect(result.criticalPaths, hasLength(2));
    expect(result.projectVariance, closeTo(math.pow(1 / 3, 2), 1e-9));
    expect(result.warnings, contains('orWarningMultipleCriticalPaths'));
  });
}

ProjectActivity _cpm(
  String id,
  double duration, [
  List<String> predecessors = const [],
]) => ProjectActivity(id: id, duration: duration, predecessors: predecessors);

ProjectActivity _pert(
  String id,
  double optimistic,
  double mostLikely,
  double pessimistic, [
  List<String> predecessors = const [],
]) => ProjectActivity(
  id: id,
  optimistic: optimistic,
  mostLikely: mostLikely,
  pessimistic: pessimistic,
  predecessors: predecessors,
);

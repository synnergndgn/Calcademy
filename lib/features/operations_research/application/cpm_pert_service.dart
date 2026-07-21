import 'dart:math' as math;

import 'package:calcademy/features/operations_research/domain/operations_research_limits.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';
import 'package:calcademy/features/operations_research/domain/project_network_problem.dart';

class CpmPertService {
  const CpmPertService();

  OperationsResearchResult solve(ProjectNetworkProblem problem) {
    final validation = _validate(problem);
    if (validation.issue != null) {
      return OperationsResearchFailureResult(validation.issue!);
    }
    try {
      final activities = {
        for (final activity in problem.activities) activity.id.trim(): activity,
      };
      final successors = <String, List<String>>{
        for (final id in activities.keys) id: [],
      };
      final indegree = <String, int>{};
      for (final entry in activities.entries) {
        indegree[entry.key] = entry.value.predecessors.length;
        for (final predecessor in entry.value.predecessors) {
          successors[predecessor.trim()]!.add(entry.key);
        }
      }
      final queue = <String>[
        for (final entry in indegree.entries)
          if (entry.value == 0) entry.key,
      ]..sort();
      final order = <String>[];
      while (queue.isNotEmpty) {
        final id = queue.removeAt(0);
        order.add(id);
        for (final successor in successors[id]!) {
          indegree[successor] = indegree[successor]! - 1;
          if (indegree[successor] == 0) {
            queue.add(successor);
            queue.sort();
          }
        }
      }
      if (order.length != activities.length) {
        return const OperationsResearchFailureResult(
          OperationsResearchIssue.cyclicNetwork,
        );
      }

      final durations = <String, double>{};
      final variances = <String, double>{};
      for (final entry in activities.entries) {
        final activity = entry.value;
        if (problem.mode == ProjectScheduleMode.cpm) {
          durations[entry.key] = activity.duration!;
          variances[entry.key] = 0;
        } else {
          final optimistic = activity.optimistic!;
          final mostLikely = activity.mostLikely!;
          final pessimistic = activity.pessimistic!;
          durations[entry.key] =
              (optimistic + 4 * mostLikely + pessimistic) / 6;
          variances[entry.key] = math
              .pow((pessimistic - optimistic) / 6, 2)
              .toDouble();
        }
      }

      final earliestStart = <String, double>{};
      final earliestFinish = <String, double>{};
      for (final id in order) {
        final predecessors = activities[id]!.predecessors;
        final start = predecessors.isEmpty
            ? 0.0
            : predecessors
                  .map((item) => earliestFinish[item.trim()]!)
                  .reduce(math.max);
        earliestStart[id] = _clean(start);
        earliestFinish[id] = _clean(start + durations[id]!);
      }
      final projectDuration = earliestFinish.values.reduce(math.max);
      final latestStart = <String, double>{};
      final latestFinish = <String, double>{};
      for (final id in order.reversed) {
        final next = successors[id]!;
        final finish = next.isEmpty
            ? projectDuration
            : next.map((item) => latestStart[item]!).reduce(math.min);
        latestFinish[id] = _clean(finish);
        latestStart[id] = _clean(finish - durations[id]!);
      }

      final rows = <ProjectActivitySchedule>[];
      for (final id in order) {
        final next = successors[id]!;
        final freeFinish = next.isEmpty
            ? projectDuration
            : next.map((item) => earliestStart[item]!).reduce(math.min);
        final totalFloat = _clean(latestStart[id]! - earliestStart[id]!);
        rows.add(
          ProjectActivitySchedule(
            id: id,
            predecessors: activities[id]!.predecessors,
            duration: _clean(durations[id]!),
            variance: _clean(variances[id]!),
            earliestStart: earliestStart[id]!,
            earliestFinish: earliestFinish[id]!,
            latestStart: latestStart[id]!,
            latestFinish: latestFinish[id]!,
            totalFloat: totalFloat,
            freeFloat: _clean(freeFinish - earliestFinish[id]!),
            critical: totalFloat.abs() <= OperationsResearchLimits.tolerance,
          ),
        );
      }
      final criticalSet = {
        for (final row in rows)
          if (row.critical) row.id,
      };
      final criticalPaths = _criticalPaths(
        order: order,
        activities: activities,
        successors: successors,
        earliestStart: earliestStart,
        earliestFinish: earliestFinish,
        critical: criticalSet,
        projectDuration: projectDuration,
      );
      final warnings = <String>[
        if (validation.disconnected) 'orWarningDisconnectedNetwork',
        if (criticalPaths.length > 1) 'orWarningMultipleCriticalPaths',
        if (criticalPaths.length >= OperationsResearchLimits.maxCriticalPaths)
          'orWarningCriticalPathsTruncated',
      ];
      double? projectVariance;
      double? projectStandardDeviation;
      if (problem.mode == ProjectScheduleMode.pert) {
        projectVariance = criticalPaths.isEmpty
            ? criticalSet.fold<double>(0, (sum, id) => sum + variances[id]!)
            : criticalPaths
                  .map(
                    (path) =>
                        path.fold<double>(0, (sum, id) => sum + variances[id]!),
                  )
                  .reduce(math.max);
        projectVariance = _clean(projectVariance);
        projectStandardDeviation = _clean(math.sqrt(projectVariance));
      }
      return CpmPertResult(
        mode: problem.mode,
        projectDuration: _clean(projectDuration),
        criticalActivities: [
          for (final id in order)
            if (criticalSet.contains(id)) id,
        ],
        criticalPaths: criticalPaths,
        activities: rows,
        projectVariance: projectVariance,
        projectStandardDeviation: projectStandardDeviation,
        warnings: warnings,
      );
    } on Object {
      return const OperationsResearchFailureResult(
        OperationsResearchIssue.solverFailure,
      );
    }
  }

  _NetworkValidation _validate(ProjectNetworkProblem problem) {
    if (problem.activities.length < OperationsResearchLimits.minActivities) {
      return const _NetworkValidation(
        issue: OperationsResearchIssue.invalidActivityCount,
      );
    }
    if (problem.activities.length > OperationsResearchLimits.maxActivities) {
      return const _NetworkValidation(issue: OperationsResearchIssue.tooLarge);
    }
    final ids = <String>{};
    for (final activity in problem.activities) {
      final id = activity.id.trim();
      if (id.isEmpty) {
        return const _NetworkValidation(
          issue: OperationsResearchIssue.emptyActivityId,
        );
      }
      if (!ids.add(id)) {
        return const _NetworkValidation(
          issue: OperationsResearchIssue.duplicateActivityId,
        );
      }
      if (activity.predecessors.length >
          OperationsResearchLimits.maxPredecessorsPerActivity) {
        return const _NetworkValidation(
          issue: OperationsResearchIssue.tooManyPredecessors,
        );
      }
      if (problem.mode == ProjectScheduleMode.cpm) {
        if (activity.duration == null ||
            !activity.duration!.isFinite ||
            activity.duration! <= 0) {
          return const _NetworkValidation(
            issue: OperationsResearchIssue.invalidDuration,
          );
        }
      } else {
        final optimistic = activity.optimistic;
        final mostLikely = activity.mostLikely;
        final pessimistic = activity.pessimistic;
        if (optimistic == null ||
            mostLikely == null ||
            pessimistic == null ||
            !optimistic.isFinite ||
            !mostLikely.isFinite ||
            !pessimistic.isFinite ||
            optimistic <= 0 ||
            optimistic > mostLikely ||
            mostLikely > pessimistic) {
          return const _NetworkValidation(
            issue: OperationsResearchIssue.invalidPertTimes,
          );
        }
      }
    }
    final adjacency = <String, Set<String>>{for (final id in ids) id: {}};
    for (final activity in problem.activities) {
      final id = activity.id.trim();
      final seen = <String>{};
      for (final predecessorSource in activity.predecessors) {
        final predecessor = predecessorSource.trim();
        if (!ids.contains(predecessor)) {
          return const _NetworkValidation(
            issue: OperationsResearchIssue.missingPredecessor,
          );
        }
        if (!seen.add(predecessor)) {
          return const _NetworkValidation(
            issue: OperationsResearchIssue.invalidDimensions,
          );
        }
        adjacency[id]!.add(predecessor);
        adjacency[predecessor]!.add(id);
      }
    }
    final visited = <String>{};
    final pending = <String>[ids.first];
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      if (!visited.add(current)) continue;
      pending.addAll(adjacency[current]!.where((id) => !visited.contains(id)));
    }
    return _NetworkValidation(disconnected: visited.length != ids.length);
  }

  List<List<String>> _criticalPaths({
    required List<String> order,
    required Map<String, ProjectActivity> activities,
    required Map<String, List<String>> successors,
    required Map<String, double> earliestStart,
    required Map<String, double> earliestFinish,
    required Set<String> critical,
    required double projectDuration,
  }) {
    final paths = <List<String>>[];
    final starts = order.where(
      (id) =>
          critical.contains(id) &&
          activities[id]!.predecessors.isEmpty &&
          earliestStart[id]!.abs() <= OperationsResearchLimits.tolerance,
    );
    void visit(String id, List<String> path) {
      if (paths.length >= OperationsResearchLimits.maxCriticalPaths) return;
      final next =
          successors[id]!
              .where(
                (successor) =>
                    critical.contains(successor) &&
                    (earliestFinish[id]! - earliestStart[successor]!).abs() <=
                        OperationsResearchLimits.tolerance,
              )
              .toList()
            ..sort();
      final updated = [...path, id];
      if (next.isEmpty) {
        if ((earliestFinish[id]! - projectDuration).abs() <=
            OperationsResearchLimits.tolerance) {
          paths.add(updated);
        }
        return;
      }
      for (final successor in next) {
        visit(successor, updated);
      }
    }

    for (final start in starts) {
      visit(start, const []);
    }
    return paths;
  }

  double _clean(double value) =>
      value.abs() <= OperationsResearchLimits.tolerance ? 0 : value;
}

class _NetworkValidation {
  const _NetworkValidation({this.issue, this.disconnected = false});

  final OperationsResearchIssue? issue;
  final bool disconnected;
}

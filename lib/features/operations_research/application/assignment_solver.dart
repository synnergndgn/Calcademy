import 'dart:math' as math;

import 'package:calcademy/features/operations_research/application/operations_research_validation.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_problem.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';

class AssignmentSolver {
  const AssignmentSolver();

  OperationsResearchResult solve(AssignmentProblem problem) {
    final issue = OperationsResearchValidation.assignment(problem);
    if (issue != null) return OperationsResearchFailureResult(issue);
    try {
      final size = math.max(problem.rowCount, problem.columnCount);
      final original = [
        for (var row = 0; row < size; row++)
          [
            for (var column = 0; column < size; column++)
              row < problem.rowCount && column < problem.columnCount
                  ? problem.values[row][column]
                  : 0.0,
          ],
      ];
      final maximum = original
          .expand((row) => row)
          .fold<double>(double.negativeInfinity, math.max);
      final costs = [
        for (final row in original)
          [
            for (final value in row)
              problem.objective == OperationsResearchObjective.minimize
                  ? value
                  : maximum - value,
          ],
      ];
      final columnsByRow = _hungarian(costs);
      final assignments = <AssignmentMatch>[];
      var total = 0.0;
      for (var row = 0; row < size; row++) {
        final column = columnsByRow[row];
        final dummy = row >= problem.rowCount || column >= problem.columnCount;
        final value = dummy ? 0.0 : problem.values[row][column];
        if (!dummy) total += value;
        assignments.add(
          AssignmentMatch(
            row: row,
            column: column,
            value: value,
            isDummy: dummy,
          ),
        );
      }
      return AssignmentResult(
        objective: problem.objective,
        assignments: assignments,
        totalValue: total,
        originalRowCount: problem.rowCount,
        originalColumnCount: problem.columnCount,
        balancedSize: size,
        iterations: size,
        warnings: [
          if (problem.rowCount != problem.columnCount) 'orWarningRectangular',
          if (problem.rowCount != problem.columnCount)
            'orWarningDummyAssignment',
        ],
      );
    } on Object {
      return const OperationsResearchFailureResult(
        OperationsResearchIssue.solverFailure,
      );
    }
  }

  List<int> _hungarian(List<List<double>> costs) {
    final n = costs.length;
    final u = List<double>.filled(n + 1, 0);
    final v = List<double>.filled(n + 1, 0);
    final p = List<int>.filled(n + 1, 0);
    final way = List<int>.filled(n + 1, 0);
    for (var i = 1; i <= n; i++) {
      p[0] = i;
      var column0 = 0;
      final minValue = List<double>.filled(n + 1, double.infinity);
      final used = List<bool>.filled(n + 1, false);
      do {
        used[column0] = true;
        final row0 = p[column0];
        var delta = double.infinity;
        var column1 = 0;
        for (var column = 1; column <= n; column++) {
          if (used[column]) continue;
          final current = costs[row0 - 1][column - 1] - u[row0] - v[column];
          if (current < minValue[column]) {
            minValue[column] = current;
            way[column] = column0;
          }
          if (minValue[column] < delta) {
            delta = minValue[column];
            column1 = column;
          }
        }
        for (var column = 0; column <= n; column++) {
          if (used[column]) {
            u[p[column]] += delta;
            v[column] -= delta;
          } else {
            minValue[column] -= delta;
          }
        }
        column0 = column1;
      } while (p[column0] != 0);
      do {
        final column1 = way[column0];
        p[column0] = p[column1];
        column0 = column1;
      } while (column0 != 0);
    }
    final columnsByRow = List<int>.filled(n, -1);
    for (var column = 1; column <= n; column++) {
      columnsByRow[p[column] - 1] = column - 1;
    }
    return columnsByRow;
  }
}

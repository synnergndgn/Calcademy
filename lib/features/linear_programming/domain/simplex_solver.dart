// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:math' as math;

import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program_result.dart';
import 'package:calcademy/features/linear_programming/domain/lp_constants.dart';
import 'package:calcademy/features/linear_programming/domain/simplex_tableau.dart';
import 'package:calcademy/features/linear_programming/domain/standard_form.dart';

class SimplexSolver {
  const SimplexSolver({
    this.epsilon = LpConstants.simplexEpsilon,
    this.maxIterations = LpConstants.maxIterations,
  });

  final double epsilon;
  final int maxIterations;

  LinearProgramResult solve(LinearProgram program) {
    final standard = const LinearProgramStandardizer().standardize(program);
    var matrix = standard.tableau.rows.map((row) => row.toList()).toList();
    var columns = standard.tableau.columnNames.toList();
    var basis = standard.tableau.basis.toList();
    final iterations = <SimplexIteration>[];
    var totalPivots = 0;
    var degenerate = false;

    if (standard.method == SimplexMethod.twoPhase) {
      final phaseOneCosts = List<double>.filled(columns.length, 0);
      for (final column in standard.artificialColumns) {
        phaseOneCosts[column] = -1;
      }
      _setObjective(matrix, basis, phaseOneCosts);
      final phaseOne = _iterate(
        matrix,
        columns,
        basis,
        SimplexPhase.phaseOne,
        iterations,
        totalPivots,
      );
      totalPivots = phaseOne.pivots;
      degenerate |= phaseOne.degenerate;
      if (phaseOne.status == _RunStatus.limit) {
        return _failed(
          LinearProgramStatus.iterationLimit,
          standard,
          iterations,
          totalPivots,
        );
      }
      if (phaseOne.status == _RunStatus.numeric) {
        return _failed(
          LinearProgramStatus.numericError,
          standard,
          iterations,
          totalPivots,
        );
      }
      if (matrix.last.last < -epsilon) {
        return _failed(
          LinearProgramStatus.infeasible,
          standard,
          iterations,
          totalPivots,
        );
      }

      final redundantRows = <int>[];
      for (var row = 0; row < basis.length; row++) {
        if (!standard.artificialColumns.contains(basis[row])) continue;
        int? candidate;
        for (var column = 0; column < columns.length; column++) {
          if (!standard.artificialColumns.contains(column) &&
              matrix[row][column].abs() > epsilon) {
            candidate = column;
            break;
          }
        }
        if (candidate == null) {
          if (matrix[row].last.abs() > epsilon) {
            return _failed(
              LinearProgramStatus.infeasible,
              standard,
              iterations,
              totalPivots,
            );
          }
          redundantRows.add(row);
        } else {
          _pivot(matrix, basis, row, candidate);
        }
      }
      for (final row in redundantRows.reversed) {
        matrix.removeAt(row);
        basis.removeAt(row);
      }

      final keep = <int>[
        for (var index = 0; index < columns.length; index++)
          if (!standard.artificialColumns.contains(index)) index,
      ];
      final remap = <int, int>{
        for (var index = 0; index < keep.length; index++) keep[index]: index,
      };
      matrix = [
        for (final row in matrix)
          [...keep.map((column) => row[column]), row.last],
      ];
      columns = keep.map((column) => columns[column]).toList();
      basis = basis.map((column) => remap[column]!).toList();
    }

    final phaseTwoCosts = List<double>.filled(columns.length, 0);
    for (var index = 0; index < program.objective.length; index++) {
      phaseTwoCosts[index] = program.direction == ObjectiveDirection.maximize
          ? program.objective[index]
          : -program.objective[index];
    }
    _setObjective(matrix, basis, phaseTwoCosts);
    final phase = standard.method == SimplexMethod.primal
        ? SimplexPhase.primal
        : SimplexPhase.phaseTwo;
    final phaseTwo = _iterate(
      matrix,
      columns,
      basis,
      phase,
      iterations,
      totalPivots,
    );
    totalPivots = phaseTwo.pivots;
    degenerate |= phaseTwo.degenerate;
    if (phaseTwo.status == _RunStatus.unbounded) {
      return _failed(
        LinearProgramStatus.unbounded,
        standard,
        iterations,
        totalPivots,
      );
    }
    if (phaseTwo.status == _RunStatus.limit) {
      return _failed(
        LinearProgramStatus.iterationLimit,
        standard,
        iterations,
        totalPivots,
      );
    }
    if (phaseTwo.status == _RunStatus.numeric) {
      return _failed(
        LinearProgramStatus.numericError,
        standard,
        iterations,
        totalPivots,
      );
    }

    final values = List<double>.filled(program.variables.length, 0);
    for (var row = 0; row < basis.length; row++) {
      if (basis[row] < values.length)
        values[basis[row]] = _clean(matrix[row].last);
      if (matrix[row].last.abs() <= epsilon) degenerate = true;
    }
    final variableValues = <String, double>{
      for (var index = 0; index < values.length; index++)
        program.variables[index].name: values[index],
    };
    final analyses = <ConstraintAnalysis>[];
    for (final constraint in program.constraints) {
      var activity = 0.0;
      for (var index = 0; index < values.length; index++) {
        activity += constraint.coefficients[index] * values[index];
      }
      final gap = switch (constraint.relation) {
        ConstraintRelation.lessOrEqual => constraint.rhs - activity,
        ConstraintRelation.greaterOrEqual => activity - constraint.rhs,
        ConstraintRelation.equal => (activity - constraint.rhs).abs(),
      };
      analyses.add(
        ConstraintAnalysis(
          name: constraint.name,
          activity: _clean(activity),
          slackOrSurplus: _clean(gap),
          active: gap.abs() <= epsilon,
        ),
      );
    }
    var objective = 0.0;
    for (var index = 0; index < values.length; index++) {
      objective += program.objective[index] * values[index];
    }
    final basisSet = basis.toSet();
    var multiple = false;
    final reducedCosts = <String, double>{};
    for (var index = 0; index < program.variables.length; index++) {
      final reduced = _clean(-matrix.last[index]);
      reducedCosts[program.variables[index].name] = reduced;
      if (!basisSet.contains(index) && reduced.abs() <= epsilon)
        multiple = true;
    }
    return FeasibleLinearProgramResult(
      status: multiple
          ? LinearProgramStatus.multipleOptimal
          : LinearProgramStatus.optimal,
      method: standard.method,
      iterationCount: totalPivots,
      iterations: iterations,
      standardizationSteps: standard.steps,
      objectiveValue: _clean(objective),
      variableValues: variableValues,
      constraintAnalysis: analyses,
      basicVariables: basis.map((column) => columns[column]).toList(),
      reducedCosts: reducedCosts,
      degenerate: degenerate,
    );
  }

  FailedLinearProgramResult _failed(
    LinearProgramStatus status,
    StandardForm standard,
    List<SimplexIteration> iterations,
    int pivots,
  ) => FailedLinearProgramResult(
    status: status,
    method: standard.method,
    iterationCount: pivots,
    iterations: iterations,
    standardizationSteps: standard.steps,
  );

  void _setObjective(
    List<List<double>> matrix,
    List<int> basis,
    List<double> costs,
  ) {
    final objective = matrix.last;
    for (var column = 0; column < costs.length; column++) {
      objective[column] = -costs[column];
    }
    objective.last = 0;
    for (var row = 0; row < basis.length; row++) {
      final coefficient = objective[basis[row]];
      if (coefficient.abs() <= epsilon) continue;
      for (var column = 0; column < objective.length; column++) {
        objective[column] -= coefficient * matrix[row][column];
      }
    }
    _cleanMatrix(matrix);
  }

  _RunResult _iterate(
    List<List<double>> matrix,
    List<String> columns,
    List<int> basis,
    SimplexPhase phase,
    List<SimplexIteration> history,
    int initialPivots,
  ) {
    var pivots = initialPivots;
    var degenerate = false;
    history.add(
      _snapshot(
        history.length,
        phase,
        matrix,
        columns,
        basis,
        'lpCanonicalTableau',
      ),
    );
    while (true) {
      int? entering;
      var mostNegative = -epsilon;
      for (var column = 0; column < columns.length; column++) {
        final value = matrix.last[column];
        if (value < mostNegative - epsilon ||
            ((value - mostNegative).abs() <= epsilon &&
                entering != null &&
                column < entering)) {
          mostNegative = value;
          entering = column;
        }
      }
      if (entering == null)
        return _RunResult(_RunStatus.optimal, pivots, degenerate);
      if (pivots >= maxIterations)
        return _RunResult(_RunStatus.limit, pivots, degenerate);
      final ratios = <double?>[];
      int? leaving;
      var bestRatio = double.infinity;
      for (var row = 0; row < basis.length; row++) {
        final coefficient = matrix[row][entering];
        final ratio = coefficient > epsilon
            ? matrix[row].last / coefficient
            : null;
        ratios.add(ratio);
        if (ratio != null &&
            ratio >= -epsilon &&
            (ratio < bestRatio - epsilon ||
                ((ratio - bestRatio).abs() <= epsilon &&
                    (leaving == null || basis[row] < basis[leaving])))) {
          bestRatio = ratio;
          leaving = row;
        }
      }
      if (leaving == null)
        return _RunResult(_RunStatus.unbounded, pivots, degenerate);
      if (bestRatio <= epsilon) degenerate = true;
      final pivotValue = matrix[leaving][entering];
      if (!pivotValue.isFinite || pivotValue.abs() <= epsilon) {
        return _RunResult(_RunStatus.numeric, pivots, degenerate);
      }
      final leavingName = columns[basis[leaving]];
      final enteringName = columns[entering];
      _pivot(matrix, basis, leaving, entering);
      pivots++;
      history.add(
        _snapshot(
          history.length,
          phase,
          matrix,
          columns,
          basis,
          'lpPivotExplanation|$enteringName|$leavingName',
          entering: entering,
          leaving: leaving,
          pivotValue: pivotValue,
          ratios: ratios,
          rowOperations: ['lpNormalizePivotRow', 'lpEliminatePivotColumn'],
        ),
      );
    }
  }

  void _pivot(
    List<List<double>> matrix,
    List<int> basis,
    int pivotRow,
    int pivotColumn,
  ) {
    final pivot = matrix[pivotRow][pivotColumn];
    for (var column = 0; column < matrix[pivotRow].length; column++) {
      matrix[pivotRow][column] /= pivot;
    }
    for (var row = 0; row < matrix.length; row++) {
      if (row == pivotRow) continue;
      final factor = matrix[row][pivotColumn];
      if (factor.abs() <= epsilon) continue;
      for (var column = 0; column < matrix[row].length; column++) {
        matrix[row][column] -= factor * matrix[pivotRow][column];
      }
    }
    basis[pivotRow] = pivotColumn;
    _cleanMatrix(matrix);
  }

  SimplexIteration _snapshot(
    int number,
    SimplexPhase phase,
    List<List<double>> matrix,
    List<String> columns,
    List<int> basis,
    String explanation, {
    int? entering,
    int? leaving,
    double? pivotValue,
    List<double?> ratios = const [],
    List<String> rowOperations = const [],
  }) => SimplexIteration(
    number: number,
    phase: phase,
    tableau: SimplexTableau(
      columnNames: columns.toList(),
      rows: matrix.map((row) => row.toList()).toList(),
      basis: basis.toList(),
    ),
    explanation: explanation,
    enteringColumn: entering,
    leavingRow: leaving,
    pivotValue: pivotValue,
    ratios: ratios.toList(),
    rowOperations: rowOperations.toList(),
  );

  void _cleanMatrix(List<List<double>> matrix) {
    for (final row in matrix) {
      for (var column = 0; column < row.length; column++) {
        if (!row[column].isFinite) continue;
        row[column] = _clean(row[column]);
      }
    }
  }

  double _clean(double value) {
    if (value.abs() <= epsilon) return 0;
    final nearest = value.roundToDouble();
    if ((value - nearest).abs() <= epsilon * math.max(1, value.abs()))
      return nearest;
    return value;
  }
}

enum _RunStatus { optimal, unbounded, limit, numeric }

class _RunResult {
  const _RunResult(this.status, this.pivots, this.degenerate);
  final _RunStatus status;
  final int pivots;
  final bool degenerate;
}

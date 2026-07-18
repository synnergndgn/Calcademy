import 'package:calcademy/features/matrix/domain/linear_system_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_constants.dart';
import 'package:calcademy/features/matrix/domain/matrix_error.dart';
import 'package:calcademy/features/matrix/domain/matrix_value.dart';
import 'package:calcademy/features/matrix/domain/row_operation.dart';

class MatrixEngine {
  const MatrixEngine();

  MatrixValue add(MatrixValue a, MatrixValue b) {
    _requireSameDimensions(a, b);
    return MatrixValue([
      for (var row = 0; row < a.rows; row++)
        [
          for (var column = 0; column < a.columns; column++)
            _clean(a.at(row, column) + b.at(row, column)),
        ],
    ]);
  }

  MatrixValue subtract(MatrixValue a, MatrixValue b) {
    _requireSameDimensions(a, b);
    return MatrixValue([
      for (var row = 0; row < a.rows; row++)
        [
          for (var column = 0; column < a.columns; column++)
            _clean(a.at(row, column) - b.at(row, column)),
        ],
    ]);
  }

  MatrixValue scalarMultiply(MatrixValue a, double scalar) {
    if (!scalar.isFinite) {
      throw const MatrixException(MatrixErrorCode.invalidNumber);
    }
    return MatrixValue([
      for (final row in a.values)
        [for (final value in row) _clean(value * scalar)],
    ]);
  }

  MatrixValue multiply(MatrixValue a, MatrixValue b) {
    if (a.columns != b.rows) {
      throw const MatrixException(MatrixErrorCode.incompatibleDimensions);
    }
    return MatrixValue([
      for (var row = 0; row < a.rows; row++)
        [
          for (var column = 0; column < b.columns; column++)
            _clean(
              Iterable.generate(
                a.columns,
                (index) => a.at(row, index) * b.at(index, column),
              ).fold<double>(0, (sum, value) => sum + value),
            ),
        ],
    ]);
  }

  MatrixValue transpose(MatrixValue a) => MatrixValue([
    for (var column = 0; column < a.columns; column++)
      [for (var row = 0; row < a.rows; row++) a.at(row, column)],
  ]);

  double trace(MatrixValue a) {
    _requireSquare(a);
    return _clean(
      Iterable.generate(
        a.rows,
        (index) => a.at(index, index),
      ).fold<double>(0, (sum, value) => sum + value),
    );
  }

  double determinant(MatrixValue a) => determinantWithSteps(a).value;

  DeterminantResult determinantWithSteps(MatrixValue a) {
    _requireSquare(a);
    if (a.rows == 1) {
      return DeterminantResult(
        value: a.at(0, 0),
        reduction: RowReductionResult(
          initial: a,
          result: a,
          operations: const [],
        ),
      );
    }
    if (a.rows == 2) {
      return DeterminantResult(
        value: _clean(a.at(0, 0) * a.at(1, 1) - a.at(0, 1) * a.at(1, 0)),
        reduction: RowReductionResult(
          initial: a,
          result: a,
          operations: const [],
        ),
      );
    }
    var current = a;
    var sign = 1.0;
    final operations = <RowOperation>[];
    for (var pivot = 0; pivot < a.rows; pivot++) {
      final pivotRow = _bestPivot(current, pivot, pivot);
      if (pivotRow == null) {
        return DeterminantResult(
          value: 0,
          reduction: RowReductionResult(
            initial: a,
            result: current,
            operations: operations,
          ),
        );
      }
      if (pivotRow != pivot) {
        final operation = SwapRows(pivot, pivotRow);
        current = operation.apply(current);
        operations.add(operation);
        sign = -sign;
      }
      final pivotValue = current.at(pivot, pivot);
      for (var row = pivot + 1; row < a.rows; row++) {
        final factor = -current.at(row, pivot) / pivotValue;
        if (factor.abs() < matrixEpsilon) continue;
        final operation = AddRowMultiple(pivot, row, factor);
        current = operation.apply(current);
        operations.add(operation);
      }
    }
    var value = sign;
    for (var index = 0; index < a.rows; index++) {
      value *= current.at(index, index);
    }
    return DeterminantResult(
      value: _clean(value),
      reduction: RowReductionResult(
        initial: a,
        result: current,
        operations: operations,
      ),
    );
  }

  MatrixValue inverse(MatrixValue a) => inverseWithSteps(a).inverse;

  InverseResult inverseWithSteps(MatrixValue a) {
    _requireSquare(a);
    final augmented = MatrixValue([
      for (var row = 0; row < a.rows; row++)
        [
          ...a.values[row],
          for (var column = 0; column < a.columns; column++)
            row == column ? 1.0 : 0.0,
        ],
    ]);
    final reduction = reducedRowEchelon(augmented, pivotColumnLimit: a.columns);
    for (var row = 0; row < a.rows; row++) {
      for (var column = 0; column < a.columns; column++) {
        final expected = row == column ? 1.0 : 0.0;
        if ((reduction.result.at(row, column) - expected).abs() >=
            matrixEpsilon * 100) {
          throw const MatrixException(MatrixErrorCode.singular);
        }
      }
    }
    final inverse = MatrixValue([
      for (var row = 0; row < a.rows; row++)
        [
          for (var column = a.columns; column < augmented.columns; column++)
            reduction.result.at(row, column),
        ],
    ]);
    return InverseResult(inverse: inverse, reduction: reduction);
  }

  int rank(MatrixValue a) {
    final result = rowEchelon(a).result;
    return result.values
        .where((row) => row.any((value) => value.abs() >= matrixEpsilon))
        .length;
  }

  MatrixValue swapRows(MatrixValue a, int first, int second) =>
      SwapRows(first, second).apply(a);

  MatrixValue scaleRow(MatrixValue a, int row, double factor) =>
      ScaleRow(row, factor).apply(a);

  MatrixValue addRowMultiple(
    MatrixValue a,
    int source,
    int target,
    double factor,
  ) => AddRowMultiple(source, target, factor).apply(a);

  RowReductionResult rowEchelon(MatrixValue a, {int? pivotColumnLimit}) {
    var current = a;
    final operations = <RowOperation>[];
    var pivotRow = 0;
    final limit = pivotColumnLimit ?? a.columns;
    for (var column = 0; column < limit && pivotRow < a.rows; column++) {
      final candidate = _bestPivot(current, pivotRow, column);
      if (candidate == null) continue;
      if (candidate != pivotRow) {
        final operation = SwapRows(candidate, pivotRow);
        current = operation.apply(current);
        operations.add(operation);
      }
      final pivot = current.at(pivotRow, column);
      if ((pivot - 1).abs() >= matrixEpsilon) {
        final operation = ScaleRow(pivotRow, 1 / pivot);
        current = operation.apply(current);
        operations.add(operation);
      }
      for (var row = pivotRow + 1; row < a.rows; row++) {
        final factor = -current.at(row, column);
        if (factor.abs() < matrixEpsilon) continue;
        final operation = AddRowMultiple(pivotRow, row, factor);
        current = operation.apply(current);
        operations.add(operation);
      }
      pivotRow++;
    }
    return RowReductionResult(
      initial: a,
      result: current,
      operations: operations,
    );
  }

  RowReductionResult reducedRowEchelon(MatrixValue a, {int? pivotColumnLimit}) {
    final forward = rowEchelon(a, pivotColumnLimit: pivotColumnLimit);
    var current = forward.result;
    final operations = [...forward.operations];
    final limit = pivotColumnLimit ?? a.columns;
    for (var row = current.rows - 1; row >= 0; row--) {
      int? pivotColumn;
      for (var column = 0; column < limit; column++) {
        if (current.at(row, column).abs() >= matrixEpsilon) {
          pivotColumn = column;
          break;
        }
      }
      if (pivotColumn == null) continue;
      for (var target = row - 1; target >= 0; target--) {
        final factor = -current.at(target, pivotColumn);
        if (factor.abs() < matrixEpsilon) continue;
        final operation = AddRowMultiple(row, target, factor);
        current = operation.apply(current);
        operations.add(operation);
      }
    }
    return RowReductionResult(
      initial: a,
      result: current,
      operations: operations,
    );
  }

  LinearSystemSolution solveLinearSystem(MatrixValue augmented) {
    if (augmented.columns < 2) {
      throw const MatrixException(MatrixErrorCode.invalidAugmentedMatrix);
    }
    final variables = augmented.columns - 1;
    final reduction = reducedRowEchelon(augmented, pivotColumnLimit: variables);
    final reduced = reduction.result;
    for (var row = 0; row < reduced.rows; row++) {
      final coefficientsAreZero = Iterable.generate(
        variables,
        (column) => reduced.at(row, column),
      ).every((value) => value.abs() < matrixEpsilon);
      if (coefficientsAreZero &&
          reduced.at(row, variables).abs() >= matrixEpsilon) {
        return LinearSystemSolution(
          result: NoSolution(reduced),
          reduction: reduction,
        );
      }
    }
    final pivotColumns = <int>[];
    final pivotRows = <int>[];
    for (var row = 0; row < reduced.rows; row++) {
      for (var column = 0; column < variables; column++) {
        if (reduced.at(row, column).abs() >= matrixEpsilon) {
          pivotColumns.add(column);
          pivotRows.add(row);
          break;
        }
      }
    }
    if (pivotColumns.length == variables) {
      final values = List<double>.filled(variables, 0);
      for (var index = 0; index < pivotColumns.length; index++) {
        values[pivotColumns[index]] = _clean(
          reduced.at(pivotRows[index], variables),
        );
      }
      return LinearSystemSolution(
        result: UniqueSolution(values, reduced),
        reduction: reduction,
      );
    }
    final freeColumns = [
      for (var column = 0; column < variables; column++)
        if (!pivotColumns.contains(column)) column,
    ];
    return LinearSystemSolution(
      result: InfiniteSolutions(
        pivotColumns: pivotColumns,
        freeColumns: freeColumns,
        reducedMatrix: reduced,
      ),
      reduction: reduction,
    );
  }

  static int? _bestPivot(MatrixValue matrix, int startRow, int column) {
    int? best;
    var magnitude = matrixEpsilon;
    for (var row = startRow; row < matrix.rows; row++) {
      final candidate = matrix.at(row, column).abs();
      if (candidate > magnitude) {
        best = row;
        magnitude = candidate;
      }
    }
    return best;
  }

  static void _requireSameDimensions(MatrixValue a, MatrixValue b) {
    if (a.rows != b.rows || a.columns != b.columns) {
      throw const MatrixException(MatrixErrorCode.incompatibleDimensions);
    }
  }

  static void _requireSquare(MatrixValue matrix) {
    if (!matrix.isSquare) {
      throw const MatrixException(MatrixErrorCode.squareRequired);
    }
  }

  static double _clean(double value) => value.abs() < matrixEpsilon ? 0 : value;
}

class DeterminantResult {
  const DeterminantResult({required this.value, required this.reduction});

  final double value;
  final RowReductionResult reduction;
}

class InverseResult {
  const InverseResult({required this.inverse, required this.reduction});

  final MatrixValue inverse;
  final RowReductionResult reduction;
}

class LinearSystemSolution {
  const LinearSystemSolution({required this.result, required this.reduction});

  final LinearSystemResult result;
  final RowReductionResult reduction;
}

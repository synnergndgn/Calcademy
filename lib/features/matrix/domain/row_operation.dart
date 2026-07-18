import 'package:calcademy/features/matrix/domain/matrix_constants.dart';
import 'package:calcademy/features/matrix/domain/matrix_error.dart';
import 'package:calcademy/features/matrix/domain/matrix_value.dart';

sealed class RowOperation {
  const RowOperation();

  List<int> get changedRows;
  MatrixValue apply(MatrixValue matrix);

  Map<String, Object?> toJson();

  factory RowOperation.fromJson(Map<String, Object?> json) {
    return switch (json['type']) {
      'swap' => SwapRows(json['first']! as int, json['second']! as int),
      'scale' => ScaleRow(
        json['row']! as int,
        (json['factor']! as num).toDouble(),
      ),
      'add' => AddRowMultiple(
        json['source']! as int,
        json['target']! as int,
        (json['factor']! as num).toDouble(),
      ),
      _ => throw const MatrixException(MatrixErrorCode.invalidRowOperation),
    };
  }
}

final class SwapRows extends RowOperation {
  const SwapRows(this.first, this.second);

  final int first;
  final int second;

  @override
  List<int> get changedRows => [first, second];

  @override
  MatrixValue apply(MatrixValue matrix) {
    _checkRow(matrix, first);
    _checkRow(matrix, second);
    final values = matrix.toMutableList();
    final temporary = values[first];
    values[first] = values[second];
    values[second] = temporary;
    return MatrixValue(values);
  }

  @override
  Map<String, Object?> toJson() => {
    'type': 'swap',
    'first': first,
    'second': second,
  };
}

final class ScaleRow extends RowOperation {
  const ScaleRow(this.row, this.factor);

  final int row;
  final double factor;

  @override
  List<int> get changedRows => [row];

  @override
  MatrixValue apply(MatrixValue matrix) {
    _checkRow(matrix, row);
    if (!factor.isFinite || factor.abs() < matrixEpsilon) {
      throw const MatrixException(MatrixErrorCode.invalidRowOperation);
    }
    final values = matrix.toMutableList();
    for (var column = 0; column < matrix.columns; column++) {
      values[row][column] = _clean(values[row][column] * factor);
    }
    return MatrixValue(values);
  }

  @override
  Map<String, Object?> toJson() => {
    'type': 'scale',
    'row': row,
    'factor': factor,
  };
}

final class AddRowMultiple extends RowOperation {
  const AddRowMultiple(this.sourceRow, this.targetRow, this.factor);

  final int sourceRow;
  final int targetRow;
  final double factor;

  @override
  List<int> get changedRows => [targetRow];

  @override
  MatrixValue apply(MatrixValue matrix) {
    _checkRow(matrix, sourceRow);
    _checkRow(matrix, targetRow);
    if (!factor.isFinite) {
      throw const MatrixException(MatrixErrorCode.invalidRowOperation);
    }
    final values = matrix.toMutableList();
    for (var column = 0; column < matrix.columns; column++) {
      values[targetRow][column] = _clean(
        values[targetRow][column] + factor * values[sourceRow][column],
      );
    }
    return MatrixValue(values);
  }

  @override
  Map<String, Object?> toJson() => {
    'type': 'add',
    'source': sourceRow,
    'target': targetRow,
    'factor': factor,
  };
}

class RowReductionResult {
  const RowReductionResult({
    required this.initial,
    required this.result,
    required this.operations,
  });

  final MatrixValue initial;
  final MatrixValue result;
  final List<RowOperation> operations;

  MatrixValue matrixAt(int completedOperations) {
    var current = initial;
    final count = completedOperations.clamp(0, operations.length);
    for (var index = 0; index < count; index++) {
      current = operations[index].apply(current);
    }
    return current;
  }

  MatrixValue replay() => matrixAt(operations.length);
}

void _checkRow(MatrixValue matrix, int row) {
  if (row < 0 || row >= matrix.rows) {
    throw const MatrixException(MatrixErrorCode.invalidRowOperation);
  }
}

double _clean(double value) => value.abs() < matrixEpsilon ? 0 : value;

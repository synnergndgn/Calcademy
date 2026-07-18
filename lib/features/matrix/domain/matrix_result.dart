import 'package:calcademy/features/matrix/domain/linear_system_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_operation.dart';
import 'package:calcademy/features/matrix/domain/matrix_value.dart';
import 'package:calcademy/features/matrix/domain/row_operation.dart';

sealed class MatrixResult {
  const MatrixResult();

  Map<String, Object?> toJson();

  factory MatrixResult.fromJson(Map<String, Object?> json) {
    return switch (json['type']) {
      'matrix' => MatrixResultValue(
        MatrixValue.fromJson(Map<String, Object?>.from(json['value']! as Map)),
      ),
      'scalar' => ScalarMatrixResult((json['value']! as num).toDouble()),
      'linear' => LinearSystemMatrixResult(
        LinearSystemResult.fromJson(
          Map<String, Object?>.from(json['value']! as Map),
        ),
      ),
      _ => throw StateError('Unknown matrix result type.'),
    };
  }
}

final class MatrixResultValue extends MatrixResult {
  const MatrixResultValue(this.value);

  final MatrixValue value;

  @override
  Map<String, Object?> toJson() => {'type': 'matrix', 'value': value.toJson()};
}

final class ScalarMatrixResult extends MatrixResult {
  const ScalarMatrixResult(this.value);

  final double value;

  @override
  Map<String, Object?> toJson() => {'type': 'scalar', 'value': value};
}

final class LinearSystemMatrixResult extends MatrixResult {
  const LinearSystemMatrixResult(this.value);

  final LinearSystemResult value;

  @override
  Map<String, Object?> toJson() => {'type': 'linear', 'value': value.toJson()};
}

class MatrixExecution {
  const MatrixExecution({
    required this.operation,
    required this.inputs,
    required this.result,
    this.parameters = const {},
    this.steps,
  });

  final MatrixOperationType operation;
  final List<MatrixValue> inputs;
  final MatrixResult result;
  final Map<String, double> parameters;
  final RowReductionResult? steps;

  MultiplicationCellDetail multiplicationDetail(int row, int column) {
    if (operation != MatrixOperationType.multiply || inputs.length != 2) {
      throw StateError('This is not a matrix multiplication result.');
    }
    final left = inputs[0];
    final right = inputs[1];
    final terms = [
      for (var index = 0; index < left.columns; index++)
        MultiplicationTerm(left.at(row, index), right.at(index, column)),
    ];
    return MultiplicationCellDetail(row: row, column: column, terms: terms);
  }
}

class MultiplicationCellDetail {
  const MultiplicationCellDetail({
    required this.row,
    required this.column,
    required this.terms,
  });

  final int row;
  final int column;
  final List<MultiplicationTerm> terms;

  double get result => terms.fold(0, (sum, term) => sum + term.product);
}

class MultiplicationTerm {
  const MultiplicationTerm(this.left, this.right);

  final double left;
  final double right;

  double get product => left * right;
}

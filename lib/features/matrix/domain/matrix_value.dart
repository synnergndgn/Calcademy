import 'package:calcademy/features/matrix/domain/matrix_constants.dart';
import 'package:calcademy/features/matrix/domain/matrix_error.dart';

class MatrixValue {
  MatrixValue(List<List<double>> source)
    : values = _validateAndCopy(source),
      rows = source.length,
      columns = source.isEmpty ? 0 : source.first.length;

  factory MatrixValue.zero(int rows, int columns) {
    _validateSize(rows, columns);
    return MatrixValue(
      List.generate(rows, (_) => List<double>.filled(columns, 0)),
    );
  }

  factory MatrixValue.identity(int size) {
    _validateSize(size, size);
    return MatrixValue([
      for (var row = 0; row < size; row++)
        [for (var column = 0; column < size; column++) row == column ? 1 : 0],
    ]);
  }

  factory MatrixValue.fromJson(Map<String, Object?> json) {
    final raw = json['values'];
    if (raw is! List<Object?>) {
      throw const MatrixException(MatrixErrorCode.invalidDimensions);
    }
    return MatrixValue([
      for (final row in raw)
        if (row is List<Object?>)
          [for (final value in row) (value as num).toDouble()],
    ]);
  }

  final int rows;
  final int columns;
  final List<List<double>> values;

  bool get isSquare => rows == columns;

  double at(int row, int column) => values[row][column];

  MatrixValue withCell(int row, int column, double value) {
    if (!value.isFinite) {
      throw const MatrixException(MatrixErrorCode.invalidNumber);
    }
    final copy = toMutableList();
    copy[row][column] = _clean(value);
    return MatrixValue(copy);
  }

  MatrixValue resized(int newRows, int newColumns) {
    _validateSize(newRows, newColumns, maxColumns: matrixMaxAugmentedColumns);
    return MatrixValue([
      for (var row = 0; row < newRows; row++)
        [
          for (var column = 0; column < newColumns; column++)
            row < rows && column < columns ? at(row, column) : 0,
        ],
    ]);
  }

  List<List<double>> toMutableList() => [
    for (final row in values) List<double>.from(row),
  ];

  Map<String, Object?> toJson() => {
    'rows': rows,
    'columns': columns,
    'values': [for (final row in values) List<double>.from(row)],
  };

  static List<List<double>> _validateAndCopy(List<List<double>> source) {
    if (source.isEmpty || source.first.isEmpty) {
      throw const MatrixException(MatrixErrorCode.invalidDimensions);
    }
    final columns = source.first.length;
    _validateSize(source.length, columns, maxColumns: matrixMaxInternalColumns);
    if (source.any((row) => row.length != columns)) {
      throw const MatrixException(MatrixErrorCode.invalidDimensions);
    }
    if (source.expand((row) => row).any((value) => !value.isFinite)) {
      throw const MatrixException(MatrixErrorCode.invalidNumber);
    }
    return List<List<double>>.unmodifiable([
      for (final row in source)
        List<double>.unmodifiable([for (final value in row) _clean(value)]),
    ]);
  }

  static void _validateSize(
    int rows,
    int columns, {
    int maxColumns = matrixMaxColumns,
  }) {
    if (rows < matrixMinSize ||
        columns < matrixMinSize ||
        rows > matrixMaxRows ||
        columns > maxColumns) {
      throw const MatrixException(MatrixErrorCode.invalidDimensions);
    }
  }

  static double _clean(double value) => value.abs() < matrixEpsilon ? 0 : value;

  @override
  bool operator ==(Object other) {
    if (other is! MatrixValue ||
        rows != other.rows ||
        columns != other.columns) {
      return false;
    }
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        if ((at(row, column) - other.at(row, column)).abs() >= matrixEpsilon) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    rows,
    columns,
    Object.hashAll(
      values.expand((row) => row).map((value) => value.toStringAsPrecision(12)),
    ),
  );
}

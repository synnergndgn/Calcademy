import 'package:calcademy/features/matrix/domain/matrix_constants.dart';
import 'package:calcademy/features/matrix/domain/matrix_error.dart';
import 'package:calcademy/features/matrix/domain/matrix_value.dart';

double parseMatrixNumber(String source) {
  final text = source.trim();
  if (text.isEmpty) return 0;
  final slash = text.indexOf('/');
  double value;
  if (slash >= 0 && slash == text.lastIndexOf('/')) {
    final numerator = double.tryParse(text.substring(0, slash).trim());
    final denominator = double.tryParse(text.substring(slash + 1).trim());
    if (numerator == null ||
        denominator == null ||
        denominator.abs() < matrixEpsilon) {
      throw const MatrixException(MatrixErrorCode.invalidNumber);
    }
    value = numerator / denominator;
  } else {
    value = double.tryParse(text) ?? double.nan;
  }
  if (!value.isFinite) {
    throw const MatrixException(MatrixErrorCode.invalidNumber);
  }
  return value.abs() < matrixEpsilon ? 0 : value;
}

String formatMatrixNumber(double value, {int precision = 6}) {
  if (value.abs() < matrixEpsilon) return '0';
  final absolute = value.abs();
  if (absolute >= 1e9 || absolute < 1e-6) {
    return value
        .toStringAsExponential(precision - 1)
        .replaceFirst(RegExp(r'\.0+e'), 'e');
  }
  final fixed = value.toStringAsFixed(precision);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

String matrixToPlainText(MatrixValue matrix, {int precision = 6}) => matrix
    .values
    .map(
      (row) => row
          .map((value) => formatMatrixNumber(value, precision: precision))
          .join('  '),
    )
    .join('\n');

String matrixToBracketText(MatrixValue matrix, {int precision = 6}) =>
    '[${matrix.values.map((row) => '[${row.map((value) => formatMatrixNumber(value, precision: precision)).join(', ')}]').join(', ')}]';

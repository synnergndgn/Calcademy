import 'dart:math' as math;

import 'package:calcademy/features/calculator/domain/calculator_error.dart';

class ResultFormatter {
  const ResultFormatter();

  String format(
    double value, {
    int precision = 10,
    bool scientificNotation = true,
  }) {
    if (value.isNaN) {
      throw const CalculatorException(CalculatorErrorType.undefined);
    }
    if (value.isInfinite) {
      throw const CalculatorException(CalculatorErrorType.overflow);
    }
    if (value == 0 || value.abs() < math.pow(10, -precision - 2)) return '0';

    final absolute = value.abs();
    final useScientific =
        scientificNotation &&
        (absolute >= math.pow(10, precision) || absolute < math.pow(10, -6));
    if (useScientific) {
      return _trimScientific(value.toStringAsExponential(precision - 1));
    }
    final fixed = value.toStringAsFixed(precision);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String _trimScientific(String value) {
    final parts = value.split('e');
    final coefficient = parts.first.replaceFirst(RegExp(r'\.?0+$'), '');
    final exponent = int.parse(parts.last);
    return '${coefficient}e${exponent >= 0 ? '+' : ''}$exponent';
  }
}

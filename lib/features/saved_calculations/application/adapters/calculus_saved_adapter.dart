import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';

enum CalculusRestoreMode { differentiation, integration, analysis }

/// Editable inputs rebuilt from a saved calculus record.
class CalculusRestore {
  const CalculusRestore.differentiation({
    required String this.function,
    required double this.point,
    required String this.method,
    required double this.stepSize,
  }) : mode = CalculusRestoreMode.differentiation,
       lowerBound = null,
       upperBound = null,
       subintervals = null,
       rangeMin = null,
       rangeMax = null;

  const CalculusRestore.integration({
    required String this.function,
    required double this.lowerBound,
    required double this.upperBound,
    required String this.method,
    required int this.subintervals,
  }) : mode = CalculusRestoreMode.integration,
       point = null,
       stepSize = null,
       rangeMin = null,
       rangeMax = null;

  const CalculusRestore.analysis({
    required String this.function,
    required double this.rangeMin,
    required double this.rangeMax,
  }) : mode = CalculusRestoreMode.analysis,
       point = null,
       method = null,
       stepSize = null,
       lowerBound = null,
       upperBound = null,
       subintervals = null;

  final CalculusRestoreMode mode;
  final String? function;
  final double? point;
  final String? method;
  final double? stepSize;
  final double? lowerBound;
  final double? upperBound;
  final int? subintervals;
  final double? rangeMin;
  final double? rangeMax;
}

/// Restore parsing for calculus records. The save-side draft (built in the
/// calculus result card) has stored the full input payload since the
/// module shipped, so both new and legacy records restore - anything
/// malformed simply returns null and stays result-only.
abstract final class CalculusSavedAdapter {
  static CalculusRestore? tryRestore(SavedCalculation item) {
    if (item.module != SavedCalculationModule.calculus) return null;
    final payload = item.fullInputJson;
    final function = payload['function'];
    if (function is! String || function.trim().isEmpty) return null;
    switch (item.calculationType) {
      case 'differentiation':
        final point = _finiteOrNull(payload['point']);
        final stepSize = _finiteOrNull(payload['stepSize']);
        final method = payload['method'];
        if (point == null ||
            stepSize == null ||
            stepSize <= 0 ||
            method is! String ||
            !const {'forward', 'backward', 'central'}.contains(method)) {
          return null;
        }
        return CalculusRestore.differentiation(
          function: function.trim(),
          point: point,
          method: method,
          stepSize: stepSize,
        );
      case 'integration':
        final lower = _finiteOrNull(payload['lowerBound']);
        final upper = _finiteOrNull(payload['upperBound']);
        final method = payload['method'];
        final subintervals = payload['subintervals'];
        if (lower == null ||
            upper == null ||
            lower >= upper ||
            method is! String ||
            !const {'trapezoidal', 'simpson13'}.contains(method) ||
            subintervals is! int ||
            subintervals < 2) {
          return null;
        }
        return CalculusRestore.integration(
          function: function.trim(),
          lowerBound: lower,
          upperBound: upper,
          method: method,
          subintervals: subintervals,
        );
      case 'analysis':
        final rangeMin = _finiteOrNull(payload['rangeMin']);
        final rangeMax = _finiteOrNull(payload['rangeMax']);
        if (rangeMin == null || rangeMax == null || rangeMin >= rangeMax) {
          return null;
        }
        return CalculusRestore.analysis(
          function: function.trim(),
          rangeMin: rangeMin,
          rangeMax: rangeMax,
        );
      default:
        return null;
    }
  }

  static double? _finiteOrNull(Object? value) =>
      value is num && value.isFinite ? value.toDouble() : null;
}

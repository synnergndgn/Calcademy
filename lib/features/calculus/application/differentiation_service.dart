import 'package:calcademy/features/calculus/domain/calculus_limits.dart';
import 'package:calcademy/features/calculus/domain/calculus_result.dart';
import 'package:calcademy/features/equation_solver/domain/equation_parser.dart';

/// Numerical differentiation with the three classic finite-difference
/// formulas. The expression is compiled exactly once per solve and the
/// compiled evaluator is reused for every sample. The error estimate is
/// the Richardson comparison of the requested step with half the step,
/// scaled by the method's order (central is O(h²), forward/backward are
/// O(h)) - an estimate, reported as such.
class DifferentiationService {
  const DifferentiationService();

  CalculusResult differentiate({
    required String function,
    required double point,
    required DifferentiationMethod method,
    double stepSize = CalculusLimits.defaultStepSize,
  }) {
    final ParsedEquation parsed;
    try {
      parsed = ParsedEquation.parse(function);
    } on EquationParseException catch (exception) {
      return CalculusFailureResult(
        failure: calculusFailureFromParse(exception.failure),
      );
    }
    if (!point.isFinite) {
      return CalculusFailureResult(failure: CalculusFailure.invalidNumber);
    }
    if (!stepSize.isFinite ||
        stepSize < CalculusLimits.minStepSize ||
        stepSize > CalculusLimits.maxStepSize) {
      return CalculusFailureResult(failure: CalculusFailure.invalidStepSize);
    }

    final f = parsed.evaluate;
    final full = _difference(f, point, stepSize, method);
    final half = _difference(f, point, stepSize / 2, method);
    if (full == null || half == null) {
      return CalculusFailureResult(
        failure: CalculusFailure.evaluationUndefined,
      );
    }
    final order = method == DifferentiationMethod.central ? 2 : 1;
    final errorEstimate = (full - half).abs() / ((1 << order) - 1);
    return DifferentiationSuccess(
      // The half-step evaluation is the more accurate of the two; report
      // it so the shown value matches the error estimate's target.
      value: half,
      method: method,
      point: point,
      stepSize: stepSize,
      errorEstimate: errorEstimate,
    );
  }

  double? _difference(
    double Function(double) f,
    double x,
    double h,
    DifferentiationMethod method,
  ) {
    final value = switch (method) {
      DifferentiationMethod.forward => (f(x + h) - f(x)) / h,
      DifferentiationMethod.backward => (f(x) - f(x - h)) / h,
      DifferentiationMethod.central => (f(x + h) - f(x - h)) / (2 * h),
    };
    return value.isFinite ? value : null;
  }
}

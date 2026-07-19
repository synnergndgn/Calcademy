import 'package:calcademy/features/calculus/domain/calculus_limits.dart';
import 'package:calcademy/features/calculus/domain/calculus_result.dart';
import 'package:calcademy/features/equation_solver/domain/equation_parser.dart';

/// Numerical integration with the trapezoidal and Simpson 1/3 rules.
/// Simpson requires an even subinterval count and an odd input is a
/// validation error, never a silent correction. The error estimate is the
/// Richardson comparison against a doubled subdivision, scaled by each
/// method's order (trapezoid O(h²) → /3, Simpson O(h⁴) → /15).
class IntegrationService {
  const IntegrationService();

  CalculusResult integrate({
    required String function,
    required double lowerBound,
    required double upperBound,
    required IntegrationMethod method,
    int subintervals = CalculusLimits.defaultSubintervals,
  }) {
    final ParsedEquation parsed;
    try {
      parsed = ParsedEquation.parse(function);
    } on EquationParseException catch (exception) {
      return CalculusFailureResult(
        failure: calculusFailureFromParse(exception.failure),
      );
    }
    if (!lowerBound.isFinite ||
        !upperBound.isFinite ||
        lowerBound >= upperBound) {
      return CalculusFailureResult(failure: CalculusFailure.invalidBounds);
    }
    if (subintervals < CalculusLimits.minSubintervals ||
        subintervals > CalculusLimits.maxSubintervals) {
      return CalculusFailureResult(
        failure: CalculusFailure.invalidSubintervalCount,
      );
    }
    if (method == IntegrationMethod.simpson13 && subintervals.isOdd) {
      return CalculusFailureResult(
        failure: CalculusFailure.oddSimpsonSubintervals,
      );
    }

    final f = parsed.evaluate;
    final coarse = _integrate(f, lowerBound, upperBound, subintervals, method);
    final fine = _integrate(
      f,
      lowerBound,
      upperBound,
      subintervals * 2,
      method,
    );
    if (coarse == null || fine == null) {
      return CalculusFailureResult(
        failure: CalculusFailure.evaluationUndefined,
      );
    }
    final divisor = method == IntegrationMethod.simpson13 ? 15 : 3;
    return IntegrationSuccess(
      value: coarse,
      method: method,
      lowerBound: lowerBound,
      upperBound: upperBound,
      subintervals: subintervals,
      errorEstimate: (fine - coarse).abs() / divisor,
    );
  }

  double? _integrate(
    double Function(double) f,
    double a,
    double b,
    int n,
    IntegrationMethod method,
  ) {
    final h = (b - a) / n;
    var sum = 0.0;
    switch (method) {
      case IntegrationMethod.trapezoidal:
        final fa = f(a);
        final fb = f(b);
        if (!fa.isFinite || !fb.isFinite) return null;
        sum = (fa + fb) / 2;
        for (var i = 1; i < n; i++) {
          final y = f(a + h * i);
          if (!y.isFinite) return null;
          sum += y;
        }
        return sum * h;
      case IntegrationMethod.simpson13:
        final fa = f(a);
        final fb = f(b);
        if (!fa.isFinite || !fb.isFinite) return null;
        sum = fa + fb;
        for (var i = 1; i < n; i++) {
          final y = f(a + h * i);
          if (!y.isFinite) return null;
          sum += y * (i.isOdd ? 4 : 2);
        }
        return sum * h / 3;
    }
  }
}

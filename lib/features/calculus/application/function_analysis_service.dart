import 'dart:math' as math;

import 'package:calcademy/features/calculus/domain/calculus_limits.dart';
import 'package:calcademy/features/calculus/domain/calculus_result.dart';
import 'package:calcademy/features/equation_solver/domain/equation_parser.dart';
import 'package:calcademy/features/equation_solver/domain/root_finding.dart';
import 'package:calcademy/features/equation_solver/domain/root_scanner.dart';

/// Numerical function analysis over a user-adjustable interval: roots,
/// extrema, inflection points, monotonic stretches and observed min/max.
///
/// Everything here is sampling-based and every result is presented as
/// *approximate within the sampled interval* - the service never claims
/// symbolic certainty. Root detection reuses the equation solver's
/// [scanForRoots] (sign-change bracketing + bisection + residual checks);
/// extremum and inflection detection run the same scan on numerical first
/// and second derivatives.
class FunctionAnalysisService {
  const FunctionAnalysisService();

  CalculusResult analyze({
    required String function,
    double rangeMin = CalculusLimits.defaultAnalysisMin,
    double rangeMax = CalculusLimits.defaultAnalysisMax,
  }) {
    final ParsedEquation parsed;
    try {
      parsed = ParsedEquation.parse(function);
    } on EquationParseException catch (exception) {
      return CalculusFailureResult(
        failure: calculusFailureFromParse(exception.failure),
      );
    }
    if (!rangeMin.isFinite || !rangeMax.isFinite || rangeMin >= rangeMax) {
      return CalculusFailureResult(
        failure: CalculusFailure.invalidAnalysisRange,
      );
    }

    final f = parsed.evaluate;
    final span = rangeMax - rangeMin;
    final h = math.max(1e-7, span * 1e-6);
    double derivative(double x) {
      final value = (f(x + h) - f(x - h)) / (2 * h);
      return value.isFinite ? value : double.nan;
    }

    double secondDerivative(double x) {
      final value = (f(x + h) - 2 * f(x) + f(x - h)) / (h * h);
      return value.isFinite ? value : double.nan;
    }

    const samples = CalculusLimits.analysisSampleCount;
    final warnings = <String>{};
    var undefinedSamples = 0;
    ObservedValue? observedMin;
    ObservedValue? observedMax;
    for (var i = 0; i <= samples; i++) {
      final x = rangeMin + span * i / samples;
      final y = f(x);
      if (!y.isFinite) {
        undefinedSamples++;
        continue;
      }
      if (observedMin == null || y < observedMin.y) {
        observedMin = ObservedValue(x: x, y: y);
      }
      if (observedMax == null || y > observedMax.y) {
        observedMax = ObservedValue(x: x, y: y);
      }
    }
    if (undefinedSamples > 0) {
      warnings.add('calcWarningUndefinedRegion');
    }
    if (undefinedSamples > samples) {
      return CalculusFailureResult(
        failure: CalculusFailure.evaluationUndefined,
      );
    }

    final rootScan = scanForRoots(f, min: rangeMin, max: rangeMax);
    warnings.addAll(rootScan.warnings);

    // Critical points: zeros of the numerical first derivative, classified
    // by the sign of the numerical second derivative.
    final criticalScan = scanForRoots(derivative, min: rangeMin, max: rangeMax);
    final extrema = <ExtremumPoint>[];
    for (final critical in criticalScan.roots) {
      final x = critical.value;
      final y = f(x);
      if (!y.isFinite) continue;
      final curvature = secondDerivative(x);
      if (!curvature.isFinite ||
          curvature.abs() < CalculusLimits.derivativeFlatTolerance) {
        warnings.add('calcWarningFlatCritical');
        continue;
      }
      extrema.add(ExtremumPoint(x: x, y: y, isMinimum: curvature > 0));
    }

    final inflectionScan = scanForRoots(
      secondDerivative,
      min: rangeMin,
      max: rangeMax,
    );
    final inflections = [for (final root in inflectionScan.roots) root.value];

    // Monotonic stretches: partition the range at critical points and
    // sample the derivative at each midpoint.
    final extremaXs = extrema.map((e) => e.x).toList()..sort();
    final cuts = [rangeMin, ...extremaXs, rangeMax];
    final intervals = <MonotonicInterval>[];
    for (var i = 0; i < cuts.length - 1; i++) {
      final from = cuts[i];
      final to = cuts[i + 1];
      if (to - from < span * 1e-6) continue;
      final slope = derivative((from + to) / 2);
      if (!slope.isFinite ||
          slope.abs() < CalculusLimits.derivativeFlatTolerance) {
        continue;
      }
      intervals.add(
        MonotonicInterval(from: from, to: to, increasing: slope > 0),
      );
    }

    return FunctionAnalysisSuccess(
      roots: rootScan.roots,
      extrema: extrema,
      inflectionPoints: inflections,
      monotonicIntervals: intervals,
      observedMin: observedMin,
      observedMax: observedMax,
      rangeMin: rangeMin,
      rangeMax: rangeMax,
      sampleCount: samples,
      warnings: warnings.toList(),
    );
  }
}

/// Kept for reuse by the graph view: a guarded numerical derivative for
/// tangent-line construction, identical to the analysis service's.
double numericalDerivativeAt(RealFunction f, double x) {
  final h = 1e-6 * (x.abs() + 1);
  final value = (f(x + h) - f(x - h)) / (2 * h);
  return value.isFinite ? value : double.nan;
}

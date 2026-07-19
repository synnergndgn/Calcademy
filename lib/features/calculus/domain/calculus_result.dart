import 'dart:collection';

import 'package:calcademy/features/equation_solver/domain/equation_solver_result.dart'
    show EquationFailure, EquationRoot;

enum DifferentiationMethod { forward, backward, central }

enum IntegrationMethod { trapezoidal, simpson13 }

/// Typed failure reasons for the calculus module. Parse errors from the
/// shared expression compiler are mapped in via [calculusFailureFromParse]
/// so the UI has a single localized-message table.
enum CalculusFailure {
  emptyInput,
  invalidSyntax,
  unbalancedParentheses,
  unknownVariable,
  unknownFunction,
  invalidNumber,
  invalidStepSize,
  invalidBounds,
  invalidSubintervalCount,
  oddSimpsonSubintervals,
  evaluationUndefined,
  invalidAnalysisRange,
}

CalculusFailure calculusFailureFromParse(EquationFailure failure) =>
    switch (failure) {
      EquationFailure.emptyInput => CalculusFailure.emptyInput,
      EquationFailure.unbalancedParentheses =>
        CalculusFailure.unbalancedParentheses,
      EquationFailure.unknownVariable => CalculusFailure.unknownVariable,
      EquationFailure.unknownFunction => CalculusFailure.unknownFunction,
      _ => CalculusFailure.invalidSyntax,
    };

/// One approximate extremum located by the analysis service.
class ExtremumPoint {
  const ExtremumPoint({
    required this.x,
    required this.y,
    required this.isMinimum,
  });

  final double x;
  final double y;
  final bool isMinimum;
}

/// One monotonic stretch between consecutive critical points.
class MonotonicInterval {
  const MonotonicInterval({
    required this.from,
    required this.to,
    required this.increasing,
  });

  final double from;
  final double to;
  final bool increasing;
}

/// The smallest/largest *sampled* value - an observation over the grid,
/// deliberately not called a global extremum.
class ObservedValue {
  const ObservedValue({required this.x, required this.y});

  final double x;
  final double y;
}

sealed class CalculusResult {
  CalculusResult({List<String> warnings = const []})
    : warnings = UnmodifiableListView(warnings);

  /// Localization keys, e.g. `calcWarningUndefinedRegion`.
  final List<String> warnings;
}

class DifferentiationSuccess extends CalculusResult {
  DifferentiationSuccess({
    required this.value,
    required this.method,
    required this.point,
    required this.stepSize,
    required this.errorEstimate,
    super.warnings,
  });

  final double value;
  final DifferentiationMethod method;
  final double point;
  final double stepSize;

  /// Richardson-style estimate from comparing the step with half the step;
  /// an *estimate*, surfaced as such in the UI.
  final double errorEstimate;
}

class IntegrationSuccess extends CalculusResult {
  IntegrationSuccess({
    required this.value,
    required this.method,
    required this.lowerBound,
    required this.upperBound,
    required this.subintervals,
    required this.errorEstimate,
    super.warnings,
  });

  final double value;
  final IntegrationMethod method;
  final double lowerBound;
  final double upperBound;
  final int subintervals;
  final double errorEstimate;
}

class FunctionAnalysisSuccess extends CalculusResult {
  FunctionAnalysisSuccess({
    required List<EquationRoot> roots,
    required List<ExtremumPoint> extrema,
    required List<double> inflectionPoints,
    required List<MonotonicInterval> monotonicIntervals,
    required this.observedMin,
    required this.observedMax,
    required this.rangeMin,
    required this.rangeMax,
    required this.sampleCount,
    super.warnings,
  }) : roots = UnmodifiableListView(roots),
       extrema = UnmodifiableListView(extrema),
       inflectionPoints = UnmodifiableListView(inflectionPoints),
       monotonicIntervals = UnmodifiableListView(monotonicIntervals);

  final List<EquationRoot> roots;
  final List<ExtremumPoint> extrema;
  final List<double> inflectionPoints;
  final List<MonotonicInterval> monotonicIntervals;
  final ObservedValue? observedMin;
  final ObservedValue? observedMax;
  final double rangeMin;
  final double rangeMax;
  final int sampleCount;
}

class CalculusFailureResult extends CalculusResult {
  CalculusFailureResult({required this.failure, super.warnings});

  final CalculusFailure failure;
}

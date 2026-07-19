import 'dart:math' as math;

import 'package:calcademy/features/equation_solver/domain/equation_parser.dart';
import 'package:calcademy/features/equation_solver/domain/equation_solver_limits.dart';
import 'package:calcademy/features/equation_solver/domain/equation_solver_result.dart';
import 'package:calcademy/features/equation_solver/domain/polynomial_detector.dart';
import 'package:calcademy/features/equation_solver/domain/root_scanner.dart';

/// Solves a single-variable equation end to end: parse, try the exact
/// analytic paths (linear/quadratic, detected by verified numeric fit),
/// and otherwise fall back to a sign-change scan over a user-adjustable
/// interval. Analytic roots are additionally residual-checked against the
/// *real* parsed function, so a false polynomial detection can never ship
/// a wrong "exact" answer - it silently falls back to the scan instead.
class SingleEquationService {
  const SingleEquationService();

  SingleEquationResult solve(
    String input, {
    double scanMin = EquationSolverLimits.defaultScanMin,
    double scanMax = EquationSolverLimits.defaultScanMax,
  }) {
    final ParsedEquation equation;
    try {
      equation = ParsedEquation.parse(input);
    } on EquationParseException catch (exception) {
      return EquationSolveFailure(
        method: EquationSolveMethod.scanAndBisect,
        failure: exception.failure,
      );
    }
    final f = equation.evaluate;

    final quadratic = detectQuadratic(f);
    if (quadratic != null) {
      final analytic = _solveDetectedQuadratic(quadratic, f);
      if (analytic != null) return analytic;
    }

    if (!scanMin.isFinite || !scanMax.isFinite || scanMin >= scanMax) {
      return EquationSolveFailure(
        method: EquationSolveMethod.scanAndBisect,
        failure: EquationFailure.invalidInterval,
      );
    }
    final scan = scanForRoots(f, min: scanMin, max: scanMax);
    if (scan.roots.isEmpty) {
      return EquationNoRealRoots(
        method: EquationSolveMethod.scanAndBisect,
        provenNone: false,
        scanMin: scanMin,
        scanMax: scanMax,
        warnings: scan.warnings,
      );
    }
    return EquationRootsFound(
      method: EquationSolveMethod.scanAndBisect,
      roots: scan.roots,
      scanMin: scanMin,
      scanMax: scanMax,
      warnings: scan.warnings,
    );
  }

  /// Returns null when the analytic result fails its residual check
  /// against the real function (a false polynomial detection); the caller
  /// then falls back to the numeric scan.
  SingleEquationResult? _solveDetectedQuadratic(
    QuadraticShape shape,
    double Function(double) f,
  ) {
    final a = shape.a;
    final b = shape.b;
    final c = shape.c;
    final scale = [
      a.abs(),
      b.abs(),
      c.abs(),
      1.0,
    ].reduce((p, q) => p > q ? p : q);
    const eps = 1e-12;

    if (a.abs() < eps * scale && b.abs() < eps * scale) {
      return c.abs() < eps * scale
          ? EquationIdentity(method: EquationSolveMethod.analyticLinear)
          : EquationContradiction(method: EquationSolveMethod.analyticLinear);
    }

    if (a.abs() < eps * scale) {
      final root = -c / b;
      return _verifiedRoots(EquationSolveMethod.analyticLinear, [root], f);
    }

    final discriminant = b * b - 4 * a * c;
    final discriminantTolerance = 1e-12 * scale * scale;
    if (discriminant < -discriminantTolerance) {
      return EquationNoRealRoots(
        method: EquationSolveMethod.analyticQuadratic,
        provenNone: true,
        complexRootsPossible: true,
      );
    }
    if (discriminant.abs() <= discriminantTolerance) {
      return _verifiedRoots(
        EquationSolveMethod.analyticQuadratic,
        [-b / (2 * a)],
        f,
        warnings: const ['eqWarningRepeatedRoot'],
      );
    }
    // Numerically stable form: computing the smaller-magnitude root from
    // q avoids catastrophic cancellation when b² >> 4ac.
    final sqrtDisc = math.sqrt(discriminant);
    final q = -(b + b.sign * sqrtDisc) / 2;
    final firstRoot = q / a;
    final secondRoot = q.abs() < eps ? -b / a : c / q;
    final roots = [firstRoot, secondRoot]..sort();
    return _verifiedRoots(EquationSolveMethod.analyticQuadratic, roots, f);
  }

  SingleEquationResult? _verifiedRoots(
    EquationSolveMethod method,
    List<double> values,
    double Function(double) f, {
    List<String> warnings = const [],
  }) {
    final roots = <EquationRoot>[];
    for (final value in values) {
      final residual = f(value).abs();
      if (!residual.isFinite ||
          residual > EquationSolverLimits.residualAcceptance) {
        return null;
      }
      roots.add(EquationRoot(value: value, residual: residual, exact: true));
    }
    return EquationRootsFound(method: method, roots: roots, warnings: warnings);
  }
}

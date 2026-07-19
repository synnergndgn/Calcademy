import 'package:calcademy/features/equation_solver/domain/equation_solver_limits.dart';
import 'package:calcademy/features/equation_solver/domain/equation_solver_result.dart';
import 'package:calcademy/features/equation_solver/domain/root_finding.dart';

/// Finds every sign-change root of f in [min, max] by sampling, bracketing
/// and bisection refinement, with the safety measures a general nonlinear
/// scan needs:
///
/// * every candidate is residual-checked, so a discontinuity that flips
///   sign without crossing zero (1/x at 0) is rejected, not reported;
/// * near-tangent (even-multiplicity) roots that never flip sign are
///   probed via |f| minima and Newton refinement, and flagged with a
///   warning when found;
/// * NaN/undefined regions simply break brackets instead of crashing;
/// * duplicates within tolerance are merged.
///
/// This deliberately claims only "roots found in the scanned interval" -
/// never "all roots of the equation".
class RootScanResult {
  const RootScanResult({required this.roots, required this.warnings});

  final List<EquationRoot> roots;
  final List<String> warnings;
}

RootScanResult scanForRoots(
  RealFunction f, {
  required double min,
  required double max,
  int samples = EquationSolverLimits.scanSampleCount,
}) {
  final warnings = <String>[];
  final candidates = <double>[];
  final step = (max - min) / samples;

  double? previousX;
  double? previousY;
  final sampleValues = List<double?>.filled(samples + 1, null);
  for (var index = 0; index <= samples; index++) {
    final x = min + step * index;
    final y = f(x);
    sampleValues[index] = y.isFinite ? y : null;
    if (!y.isFinite) {
      previousX = null;
      previousY = null;
      continue;
    }
    if (y == 0) {
      candidates.add(x);
      previousX = x;
      previousY = y;
      continue;
    }
    if (previousX != null && previousY != null && previousY.sign != y.sign) {
      final refined = RootFinding.bisection(
        f,
        lower: previousX,
        upper: x,
        tolerance: 1e-12,
        maxIterations: 200,
      );
      if (refined.converged && refined.root != null) {
        candidates.add(refined.root!);
      }
    }
    previousX = x;
    previousY = y;
  }

  // Even-multiplicity roots touch zero without a sign change; probe local
  // minima of |f| and let Newton decide whether they actually reach zero.
  for (var index = 1; index < samples; index++) {
    final left = sampleValues[index - 1];
    final middle = sampleValues[index];
    final right = sampleValues[index + 1];
    if (left == null || middle == null || right == null) continue;
    final isAbsMinimum =
        middle.abs() < left.abs() && middle.abs() <= right.abs();
    if (!isAbsMinimum || middle.abs() > step) continue;
    final x = min + step * index;
    final refined = RootFinding.newtonRaphson(
      f,
      initialGuess: x,
      tolerance: 1e-12,
      maxIterations: 60,
    );
    if (refined.converged && refined.root != null) {
      final root = refined.root!;
      if (root >= min - step && root <= max + step) {
        candidates.add(root);
        warnings.add('eqWarningPossibleDoubleRoot');
      }
    }
  }

  // Merge duplicates and residual-check every survivor.
  candidates.sort();
  final mergeTolerance =
      EquationSolverLimits.rootMergeTolerance * (1 + (max - min).abs());
  final roots = <EquationRoot>[];
  for (final candidate in candidates) {
    if (roots.isNotEmpty &&
        (candidate - roots.last.value).abs() <= mergeTolerance) {
      continue;
    }
    final residual = f(candidate).abs();
    if (!residual.isFinite ||
        residual > EquationSolverLimits.residualAcceptance) {
      continue;
    }
    roots.add(EquationRoot(value: candidate, residual: residual, exact: false));
  }
  return RootScanResult(roots: roots, warnings: warnings.toSet().toList());
}

import 'package:calcademy/features/equation_solver/domain/equation_solver_limits.dart';
import 'package:calcademy/features/equation_solver/domain/equation_solver_result.dart';

typedef RealFunction = double Function(double x);

/// The three classic bracketing/open root-finding primitives. Each returns
/// a [NumericalMethodResult] carrying convergence state, iteration count
/// and residual - never a bare number - so the UI can report honestly.
abstract final class RootFinding {
  /// Clamps user tolerance/iteration input into the supported range.
  static double clampTolerance(double tolerance) =>
      tolerance < EquationSolverLimits.toleranceFloor
      ? EquationSolverLimits.toleranceFloor
      : tolerance;

  static int clampIterations(int iterations) =>
      iterations.clamp(1, EquationSolverLimits.maxIterationsCeiling);

  static NumericalMethodResult bisection(
    RealFunction f, {
    required double lower,
    required double upper,
    double tolerance = EquationSolverLimits.defaultTolerance,
    int maxIterations = EquationSolverLimits.defaultMaxIterations,
  }) {
    tolerance = clampTolerance(tolerance);
    maxIterations = clampIterations(maxIterations);
    if (!lower.isFinite || !upper.isFinite || lower >= upper) {
      return const NumericalMethodResult(
        method: EquationSolveMethod.bisection,
        converged: false,
        iterations: 0,
        failure: EquationFailure.invalidInterval,
      );
    }
    var a = lower;
    var b = upper;
    var fa = f(a);
    var fb = f(b);
    if (!fa.isFinite || !fb.isFinite) {
      return const NumericalMethodResult(
        method: EquationSolveMethod.bisection,
        converged: false,
        iterations: 0,
        failure: EquationFailure.nonFiniteEvaluation,
      );
    }
    if (fa == 0) return _converged(EquationSolveMethod.bisection, a, 0, 0);
    if (fb == 0) return _converged(EquationSolveMethod.bisection, b, 0, 0);
    if (fa.sign == fb.sign) {
      return const NumericalMethodResult(
        method: EquationSolveMethod.bisection,
        converged: false,
        iterations: 0,
        failure: EquationFailure.invalidBracket,
      );
    }
    var iterations = 0;
    var mid = a;
    while (iterations < maxIterations) {
      iterations++;
      mid = a + (b - a) / 2;
      final fm = f(mid);
      if (!fm.isFinite) {
        return NumericalMethodResult(
          method: EquationSolveMethod.bisection,
          converged: false,
          iterations: iterations,
          failure: EquationFailure.nonFiniteEvaluation,
          lastEstimate: mid,
        );
      }
      if (fm == 0 || (b - a) / 2 < tolerance) {
        return _converged(
          EquationSolveMethod.bisection,
          mid,
          fm.abs(),
          iterations,
        );
      }
      if (fm.sign == fa.sign) {
        a = mid;
        fa = fm;
      } else {
        b = mid;
      }
    }
    return NumericalMethodResult(
      method: EquationSolveMethod.bisection,
      converged: false,
      iterations: iterations,
      failure: EquationFailure.maxIterationsReached,
      lastEstimate: mid,
    );
  }

  static NumericalMethodResult newtonRaphson(
    RealFunction f, {
    required double initialGuess,
    double tolerance = EquationSolverLimits.defaultTolerance,
    int maxIterations = EquationSolverLimits.defaultMaxIterations,
  }) {
    tolerance = clampTolerance(tolerance);
    maxIterations = clampIterations(maxIterations);
    if (!initialGuess.isFinite) {
      return const NumericalMethodResult(
        method: EquationSolveMethod.newtonRaphson,
        converged: false,
        iterations: 0,
        failure: EquationFailure.invalidNumber,
      );
    }
    var x = initialGuess;
    var iterations = 0;
    while (iterations < maxIterations) {
      iterations++;
      final fx = f(x);
      if (!fx.isFinite) {
        return NumericalMethodResult(
          method: EquationSolveMethod.newtonRaphson,
          converged: false,
          iterations: iterations,
          failure: EquationFailure.nonFiniteEvaluation,
          lastEstimate: x,
        );
      }
      if (fx.abs() <= tolerance) {
        return _converged(
          EquationSolveMethod.newtonRaphson,
          x,
          fx.abs(),
          iterations,
        );
      }
      final derivative = _numericalDerivative(f, x);
      if (!derivative.isFinite || derivative.abs() < 1e-12) {
        return NumericalMethodResult(
          method: EquationSolveMethod.newtonRaphson,
          converged: false,
          iterations: iterations,
          failure: EquationFailure.derivativeNearZero,
          lastEstimate: x,
        );
      }
      final next = x - fx / derivative;
      if (!next.isFinite) {
        return NumericalMethodResult(
          method: EquationSolveMethod.newtonRaphson,
          converged: false,
          iterations: iterations,
          failure: EquationFailure.nonFiniteEvaluation,
          lastEstimate: x,
        );
      }
      if ((next - x).abs() <= tolerance && f(next).abs() <= tolerance) {
        return _converged(
          EquationSolveMethod.newtonRaphson,
          next,
          f(next).abs(),
          iterations,
        );
      }
      x = next;
    }
    return NumericalMethodResult(
      method: EquationSolveMethod.newtonRaphson,
      converged: false,
      iterations: iterations,
      failure: EquationFailure.maxIterationsReached,
      lastEstimate: x,
    );
  }

  static NumericalMethodResult secant(
    RealFunction f, {
    required double firstGuess,
    required double secondGuess,
    double tolerance = EquationSolverLimits.defaultTolerance,
    int maxIterations = EquationSolverLimits.defaultMaxIterations,
  }) {
    tolerance = clampTolerance(tolerance);
    maxIterations = clampIterations(maxIterations);
    if (!firstGuess.isFinite ||
        !secondGuess.isFinite ||
        firstGuess == secondGuess) {
      return const NumericalMethodResult(
        method: EquationSolveMethod.secant,
        converged: false,
        iterations: 0,
        failure: EquationFailure.invalidNumber,
      );
    }
    var previous = firstGuess;
    var current = secondGuess;
    var fPrevious = f(previous);
    var iterations = 0;
    while (iterations < maxIterations) {
      iterations++;
      final fCurrent = f(current);
      if (!fCurrent.isFinite || !fPrevious.isFinite) {
        return NumericalMethodResult(
          method: EquationSolveMethod.secant,
          converged: false,
          iterations: iterations,
          failure: EquationFailure.nonFiniteEvaluation,
          lastEstimate: current,
        );
      }
      if (fCurrent.abs() <= tolerance) {
        return _converged(
          EquationSolveMethod.secant,
          current,
          fCurrent.abs(),
          iterations,
        );
      }
      final denominator = fCurrent - fPrevious;
      if (denominator.abs() < 1e-300) {
        return NumericalMethodResult(
          method: EquationSolveMethod.secant,
          converged: false,
          iterations: iterations,
          failure: EquationFailure.derivativeNearZero,
          lastEstimate: current,
        );
      }
      final next = current - fCurrent * (current - previous) / denominator;
      if (!next.isFinite) {
        return NumericalMethodResult(
          method: EquationSolveMethod.secant,
          converged: false,
          iterations: iterations,
          failure: EquationFailure.nonFiniteEvaluation,
          lastEstimate: current,
        );
      }
      previous = current;
      fPrevious = fCurrent;
      current = next;
    }
    return NumericalMethodResult(
      method: EquationSolveMethod.secant,
      converged: false,
      iterations: iterations,
      failure: EquationFailure.maxIterationsReached,
      lastEstimate: current,
    );
  }

  /// Symmetric-difference derivative with a scale-aware step; used when no
  /// analytic derivative is available (always, in this release).
  static double _numericalDerivative(RealFunction f, double x) {
    final h = 1e-6 * (x.abs() + 1);
    return (f(x + h) - f(x - h)) / (2 * h);
  }

  static NumericalMethodResult _converged(
    EquationSolveMethod method,
    double root,
    double residual,
    int iterations,
  ) => NumericalMethodResult(
    method: method,
    converged: true,
    iterations: iterations,
    root: root,
    residual: residual,
  );
}

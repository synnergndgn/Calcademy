import 'dart:math' as math;

import 'package:calcademy/features/equation_solver/domain/equation_solver_result.dart';
import 'package:calcademy/features/equation_solver/domain/root_finding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bisection', () {
    test('converges on x^2 - 2 over [0, 2] to sqrt(2)', () {
      final result = RootFinding.bisection(
        (x) => x * x - 2,
        lower: 0,
        upper: 2,
      );
      expect(result.converged, isTrue);
      expect(result.root, closeTo(math.sqrt2, 1e-8));
      expect(result.residual, lessThan(1e-6));
      expect(result.iterations, greaterThan(0));
    });

    test('rejects a bracket without a sign change', () {
      final result = RootFinding.bisection(
        (x) => x * x + 1,
        lower: -1,
        upper: 1,
      );
      expect(result.converged, isFalse);
      expect(result.failure, EquationFailure.invalidBracket);
    });

    test('rejects an inverted interval', () {
      final result = RootFinding.bisection((x) => x, lower: 2, upper: 1);
      expect(result.failure, EquationFailure.invalidInterval);
    });

    test('reports max-iteration failure honestly', () {
      final result = RootFinding.bisection(
        (x) => x - 0.1234567,
        lower: 0,
        upper: 1,
        tolerance: 1e-14,
        maxIterations: 3,
      );
      expect(result.converged, isFalse);
      expect(result.failure, EquationFailure.maxIterationsReached);
      expect(result.iterations, 3);
      expect(result.lastEstimate, isNotNull);
    });
  });

  group('newtonRaphson', () {
    test('converges on cos(x) - x from 1.0', () {
      final result = RootFinding.newtonRaphson(
        (x) => math.cos(x) - x,
        initialGuess: 1,
      );
      expect(result.converged, isTrue);
      expect(result.root, closeTo(0.7390851332, 1e-8));
    });

    test('fails cleanly when the derivative is near zero', () {
      // f(x) = x^2 + 1 at x = 0: f'(0) = 0 and no real root exists.
      final result = RootFinding.newtonRaphson(
        (x) => x * x + 1,
        initialGuess: 0,
      );
      expect(result.converged, isFalse);
      expect(result.failure, EquationFailure.derivativeNearZero);
    });

    test('reports max iterations on a cycling function', () {
      // x^(1/3)-style cycling: newton on cbrt oscillates and diverges.
      double cbrt(double x) => x.sign * math.pow(x.abs(), 1 / 3).toDouble();
      final result = RootFinding.newtonRaphson(
        cbrt,
        initialGuess: 1,
        maxIterations: 10,
      );
      expect(result.converged, isFalse);
      expect(result.failure, isNotNull);
    });
  });

  group('secant', () {
    test('converges on e^x - 5', () {
      final result = RootFinding.secant(
        (x) => math.exp(x) - 5,
        firstGuess: 1,
        secondGuess: 2,
      );
      expect(result.converged, isTrue);
      expect(result.root, closeTo(math.log(5), 1e-8));
      expect(result.iterations, greaterThan(0));
    });

    test('rejects identical guesses', () {
      final result = RootFinding.secant(
        (x) => x,
        firstGuess: 1,
        secondGuess: 1,
      );
      expect(result.failure, EquationFailure.invalidNumber);
    });

    test('reports max-iteration failure', () {
      final result = RootFinding.secant(
        (x) => math.exp(x) - 5,
        firstGuess: 100,
        secondGuess: 101,
        maxIterations: 2,
      );
      expect(result.converged, isFalse);
      expect(result.failure, EquationFailure.maxIterationsReached);
    });
  });

  test('tolerance and iteration clamps enforce the documented limits', () {
    expect(RootFinding.clampTolerance(0), 1e-14);
    expect(RootFinding.clampTolerance(1e-3), 1e-3);
    expect(RootFinding.clampIterations(0), 1);
    expect(RootFinding.clampIterations(10000), 500);
  });
}

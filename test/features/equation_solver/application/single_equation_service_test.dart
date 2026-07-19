import 'dart:math' as math;

import 'package:calcademy/features/equation_solver/application/single_equation_service.dart';
import 'package:calcademy/features/equation_solver/domain/equation_solver_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = SingleEquationService();

  group('analytic linear', () {
    test('2x + 5 = 17 gives the exact root 6', () {
      final result = service.solve('2x + 5 = 17') as EquationRootsFound;
      expect(result.method, EquationSolveMethod.analyticLinear);
      expect(result.roots.single.value, closeTo(6, 1e-12));
      expect(result.roots.single.exact, isTrue);
    });

    test('an identity (2x = 2x) is every real number', () {
      expect(service.solve('2x = 2x'), isA<EquationIdentity>());
    });

    test('a contradiction (5 = 7) has no solution', () {
      expect(service.solve('5 = 7'), isA<EquationContradiction>());
    });
  });

  group('analytic quadratic', () {
    test('x^2 - 5x + 6 = 0 gives roots 2 and 3', () {
      final result = service.solve('x^2 - 5x + 6 = 0') as EquationRootsFound;
      expect(result.method, EquationSolveMethod.analyticQuadratic);
      expect(result.roots, hasLength(2));
      expect(result.roots[0].value, closeTo(2, 1e-9));
      expect(result.roots[1].value, closeTo(3, 1e-9));
      expect(result.exact, isTrue);
    });

    test('x^2 - 4x + 4 = 0 reports the repeated root 2 with a warning', () {
      final result = service.solve('x^2 - 4x + 4 = 0') as EquationRootsFound;
      expect(result.roots.single.value, closeTo(2, 1e-9));
      expect(result.warnings, contains('eqWarningRepeatedRoot'));
    });

    test('x^2 + 1 = 0 proves no real root and flags complex roots', () {
      final result = service.solve('x^2 + 1 = 0') as EquationNoRealRoots;
      expect(result.provenNone, isTrue);
      expect(result.complexRootsPossible, isTrue);
    });
  });

  group('numeric scan', () {
    test('x^3 - x - 2 = 0 finds the known real root ~1.5213797', () {
      final result = service.solve('x^3 - x - 2 = 0') as EquationRootsFound;
      expect(result.method, EquationSolveMethod.scanAndBisect);
      expect(result.roots.single.value, closeTo(1.5213797068, 1e-6));
      expect(result.roots.single.residual, lessThan(1e-6));
    });

    test('sin(x) = 0.5 lists every root in [0, 7]', () {
      final result =
          service.solve('sin(x) = 0.5', scanMin: 0, scanMax: 7)
              as EquationRootsFound;
      // pi/6, 5pi/6, pi/6 + 2pi ≈ 0.5236, 2.6180, 6.8068.
      expect(result.roots, hasLength(3));
      expect(result.roots[0].value, closeTo(math.pi / 6, 1e-6));
      expect(result.roots[1].value, closeTo(5 * math.pi / 6, 1e-6));
      expect(result.roots[2].value, closeTo(math.pi / 6 + 2 * math.pi, 1e-6));
      expect(result.scanMin, 0);
      expect(result.scanMax, 7);
    });

    test('e^x = 5 finds ln 5', () {
      final result = service.solve('e^x = 5') as EquationRootsFound;
      expect(result.roots.single.value, closeTo(math.log(5), 1e-6));
    });

    test(
      'no root in the scanned interval is reported as such, not as proof',
      () {
        final result =
            service.solve('e^x = 0', scanMin: -5, scanMax: 5)
                as EquationNoRealRoots;
        expect(result.provenNone, isFalse);
        expect(result.scanMin, -5);
      },
    );

    test('a discontinuity (1/x = 0) is not reported as a root', () {
      final result = service.solve('1/x = 0');
      expect(result, isA<EquationNoRealRoots>());
    });

    test('an even-multiplicity root is still found, with a warning', () {
      // (x-1)^2 touches zero without a sign change... but is detected as a
      // quadratic analytically. Use a quartic to force the scan path.
      final result = service.solve('(x-1)^4 = 0') as EquationRootsFound;
      expect(result.roots.single.value, closeTo(1, 1e-3));
      expect(result.warnings, contains('eqWarningPossibleDoubleRoot'));
    });

    test('an invalid interval fails with a typed error', () {
      final result =
          service.solve('x^3 = 2', scanMin: 5, scanMax: -5)
              as EquationSolveFailure;
      expect(result.failure, EquationFailure.invalidInterval);
    });
  });

  group('parse failures', () {
    test('empty input', () {
      final result = service.solve('   ') as EquationSolveFailure;
      expect(result.failure, EquationFailure.emptyInput);
    });

    test('unbalanced parentheses', () {
      final result = service.solve('2*(x+1 = 4') as EquationSolveFailure;
      expect(result.failure, EquationFailure.unbalancedParentheses);
    });

    test('unknown variable', () {
      final result = service.solve('2y + 1 = 3') as EquationSolveFailure;
      expect(result.failure, EquationFailure.unknownVariable);
    });

    test('unknown function', () {
      final result = service.solve('foo(x) = 1') as EquationSolveFailure;
      expect(result.failure, EquationFailure.unknownFunction);
    });

    test('double equals sign', () {
      final result = service.solve('x = 1 = 2') as EquationSolveFailure;
      expect(result.failure, EquationFailure.invalidSyntax);
    });
  });

  test('implicit multiplication (3(x+1) = 9) parses and solves', () {
    final result = service.solve('3(x+1) = 9') as EquationRootsFound;
    expect(result.roots.single.value, closeTo(2, 1e-9));
  });
}

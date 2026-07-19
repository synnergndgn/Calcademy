import 'dart:math' as math;

import 'package:calcademy/features/calculus/application/differentiation_service.dart';
import 'package:calcademy/features/calculus/application/function_analysis_service.dart';
import 'package:calcademy/features/calculus/application/integration_service.dart';
import 'package:calcademy/features/calculus/domain/calculus_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const diff = DifferentiationService();
  const integ = IntegrationService();
  const analysis = FunctionAnalysisService();

  group('differentiation', () {
    test('forward difference approximates cos(1) for sin(x)', () {
      final result =
          diff.differentiate(
                function: 'sin(x)',
                point: 1,
                method: DifferentiationMethod.forward,
              )
              as DifferentiationSuccess;
      expect(result.value, closeTo(math.cos(1), 1e-4));
      expect(result.method, DifferentiationMethod.forward);
    });

    test('backward difference approximates cos(1) for sin(x)', () {
      final result =
          diff.differentiate(
                function: 'sin(x)',
                point: 1,
                method: DifferentiationMethod.backward,
              )
              as DifferentiationSuccess;
      expect(result.value, closeTo(math.cos(1), 1e-4));
    });

    test('central difference approximates cos(1) tightly', () {
      final result =
          diff.differentiate(
                function: 'sin(x)',
                point: 1,
                method: DifferentiationMethod.central,
              )
              as DifferentiationSuccess;
      expect(result.value, closeTo(math.cos(1), 1e-9));
      expect(result.errorEstimate, lessThan(1e-8));
    });

    test('central difference beats forward difference on sin(x)', () {
      const h = 1e-3;
      final central =
          diff.differentiate(
                function: 'sin(x)',
                point: 1,
                method: DifferentiationMethod.central,
                stepSize: h,
              )
              as DifferentiationSuccess;
      final forward =
          diff.differentiate(
                function: 'sin(x)',
                point: 1,
                method: DifferentiationMethod.forward,
                stepSize: h,
              )
              as DifferentiationSuccess;
      final exact = math.cos(1);
      expect(
        (central.value - exact).abs(),
        lessThan((forward.value - exact).abs()),
        reason: 'O(h²) central must out-perform O(h) forward at equal h',
      );
    });

    test('polynomial derivative: d/dx (x^2 + 5x) at 3 is 11', () {
      final result =
          diff.differentiate(
                function: 'x^2 + 5x',
                point: 3,
                method: DifferentiationMethod.central,
              )
              as DifferentiationSuccess;
      expect(result.value, closeTo(11, 1e-6));
    });

    test('invalid step size is a typed failure', () {
      final result = diff.differentiate(
        function: 'x',
        point: 0,
        method: DifferentiationMethod.central,
        stepSize: 0,
      );
      expect(
        (result as CalculusFailureResult).failure,
        CalculusFailure.invalidStepSize,
      );
    });

    test('undefined evaluation region fails cleanly (ln at -5)', () {
      final result = diff.differentiate(
        function: 'ln(x)',
        point: -5,
        method: DifferentiationMethod.central,
      );
      expect(
        (result as CalculusFailureResult).failure,
        CalculusFailure.evaluationUndefined,
      );
    });

    test('parse errors map into calculus failures', () {
      final result = diff.differentiate(
        function: '2y + 1',
        point: 0,
        method: DifferentiationMethod.central,
      );
      expect(
        (result as CalculusFailureResult).failure,
        CalculusFailure.unknownVariable,
      );
    });
  });

  group('integration', () {
    test('trapezoidal: integral of x^2 over [0,1] approaches 1/3', () {
      final result =
          integ.integrate(
                function: 'x^2',
                lowerBound: 0,
                upperBound: 1,
                method: IntegrationMethod.trapezoidal,
                subintervals: 200,
              )
              as IntegrationSuccess;
      expect(result.value, closeTo(1 / 3, 1e-4));
      expect(result.errorEstimate, greaterThan(0));
    });

    test('Simpson 1/3: integral of x^3 over [0,2] is exactly 4', () {
      final result =
          integ.integrate(
                function: 'x^3',
                lowerBound: 0,
                upperBound: 2,
                method: IntegrationMethod.simpson13,
                subintervals: 4,
              )
              as IntegrationSuccess;
      // Simpson is exact for cubics up to floating-point noise.
      expect(result.value, closeTo(4, 1e-12));
    });

    test('Simpson beats trapezoidal on sin(x) over [0, pi]', () {
      const n = 16;
      final simpson =
          integ.integrate(
                function: 'sin(x)',
                lowerBound: 0,
                upperBound: math.pi,
                method: IntegrationMethod.simpson13,
                subintervals: n,
              )
              as IntegrationSuccess;
      final trapezoid =
          integ.integrate(
                function: 'sin(x)',
                lowerBound: 0,
                upperBound: math.pi,
                method: IntegrationMethod.trapezoidal,
                subintervals: n,
              )
              as IntegrationSuccess;
      expect(
        (simpson.value - 2).abs(),
        lessThan((trapezoid.value - 2).abs()),
        reason: 'O(h⁴) Simpson must out-perform O(h²) trapezoid at equal n',
      );
    });

    test(
      'odd subinterval count for Simpson is a validation error, not fixed silently',
      () {
        final result = integ.integrate(
          function: 'x',
          lowerBound: 0,
          upperBound: 1,
          method: IntegrationMethod.simpson13,
          subintervals: 5,
        );
        expect(
          (result as CalculusFailureResult).failure,
          CalculusFailure.oddSimpsonSubintervals,
        );
      },
    );

    test('inverted bounds fail with a typed error', () {
      final result = integ.integrate(
        function: 'x',
        lowerBound: 2,
        upperBound: 1,
        method: IntegrationMethod.trapezoidal,
      );
      expect(
        (result as CalculusFailureResult).failure,
        CalculusFailure.invalidBounds,
      );
    });

    test('subinterval count outside limits fails', () {
      final result = integ.integrate(
        function: 'x',
        lowerBound: 0,
        upperBound: 1,
        method: IntegrationMethod.trapezoidal,
        subintervals: 0,
      );
      expect(
        (result as CalculusFailureResult).failure,
        CalculusFailure.invalidSubintervalCount,
      );
    });

    test(
      'an undefined region inside the bounds fails cleanly (ln over [-1,1])',
      () {
        final result = integ.integrate(
          function: 'ln(x)',
          lowerBound: -1,
          upperBound: 1,
          method: IntegrationMethod.trapezoidal,
        );
        expect(
          (result as CalculusFailureResult).failure,
          CalculusFailure.evaluationUndefined,
        );
      },
    );
  });

  group('function analysis', () {
    test('sin(x) over [-4, 4]: roots at -pi, 0, pi; extrema at ±pi/2', () {
      final result =
          analysis.analyze(function: 'sin(x)', rangeMin: -4, rangeMax: 4)
              as FunctionAnalysisSuccess;
      expect(result.roots, hasLength(3));
      expect(result.roots[0].value, closeTo(-math.pi, 1e-6));
      expect(result.roots[1].value, closeTo(0, 1e-6));
      expect(result.roots[2].value, closeTo(math.pi, 1e-6));

      expect(result.extrema, hasLength(2));
      final maxima = result.extrema.where((e) => !e.isMinimum).toList();
      final minima = result.extrema.where((e) => e.isMinimum).toList();
      expect(maxima.single.x, closeTo(math.pi / 2, 1e-4));
      expect(minima.single.x, closeTo(-math.pi / 2, 1e-4));
    });

    test('x^2 has a minimum at 0 and increasing/decreasing split there', () {
      final result =
          analysis.analyze(function: 'x^2', rangeMin: -5, rangeMax: 5)
              as FunctionAnalysisSuccess;
      expect(result.extrema.single.isMinimum, isTrue);
      expect(result.extrema.single.x, closeTo(0, 1e-4));
      expect(result.monotonicIntervals, hasLength(2));
      expect(result.monotonicIntervals[0].increasing, isFalse);
      expect(result.monotonicIntervals[1].increasing, isTrue);
      expect(result.observedMin!.y, closeTo(0, 1e-6));
    });

    test('x^3 has an inflection near 0', () {
      final result =
          analysis.analyze(function: 'x^3', rangeMin: -3, rangeMax: 3)
              as FunctionAnalysisSuccess;
      expect(
        result.inflectionPoints.any((x) => x.abs() < 1e-2),
        isTrue,
        reason: 'expected an inflection point near x = 0',
      );
    });

    test('a partially undefined function carries a warning, not a crash', () {
      final result =
          analysis.analyze(function: 'sqrt(x)', rangeMin: -2, rangeMax: 4)
              as FunctionAnalysisSuccess;
      expect(result.warnings, contains('calcWarningUndefinedRegion'));
    });

    test('an inverted range is a typed failure', () {
      final result = analysis.analyze(function: 'x', rangeMin: 5, rangeMax: -5);
      expect(
        (result as CalculusFailureResult).failure,
        CalculusFailure.invalidAnalysisRange,
      );
    });
  });
}

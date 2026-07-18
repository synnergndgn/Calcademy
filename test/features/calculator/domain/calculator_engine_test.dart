import 'dart:math' as math;

import 'package:calcademy/features/calculator/domain/calculator_engine.dart';
import 'package:calcademy/features/calculator/domain/calculator_error.dart';
import 'package:calcademy/features/calculator/domain/result_formatter.dart';
import 'package:calcademy/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = CalculatorEngine();

  group('CalculatorEngine', () {
    test('evaluates the four basic operations', () {
      expect(engine.evaluate('12 + 8 × 3'), 36);
      expect(engine.evaluate('20 ÷ 4 - 2'), 3);
    });

    test('honors precedence and parentheses', () {
      expect(engine.evaluate('2 + 3 × 4'), 14);
      expect(engine.evaluate('(2 + 3) × 4'), 20);
    });

    test('evaluates powers and roots', () {
      expect(engine.evaluate('2^8'), 256);
      expect(engine.evaluate('sqrt(144)'), 12);
    });

    test('evaluates factorial, percentage and mod', () {
      expect(engine.evaluate('5!'), 120);
      expect(engine.evaluate('25 mod 7'), 4);
      expect(engine.evaluate('50%'), 0.5);
    });

    test('evaluates trigonometry in degrees', () {
      expect(
        engine.evaluate('sin(30)', angleMode: AngleMode.degrees),
        closeTo(0.5, 1e-12),
      );
      expect(
        engine.evaluate('asin(0.5)', angleMode: AngleMode.degrees),
        closeTo(30, 1e-12),
      );
    });

    test('evaluates trigonometry in radians', () {
      expect(
        engine.evaluate('sin(pi/2)', angleMode: AngleMode.radians),
        closeTo(1, 1e-12),
      );
    });

    test('enforces inverse trigonometric real-number domains', () {
      for (final expression in [
        'asin(-1)',
        'asin(0)',
        'asin(1)',
        'acos(-1)',
        'acos(0)',
        'acos(1)',
        'atan(-100)',
        'atan(0)',
        'atan(100)',
      ]) {
        expect(
          engine.evaluate(expression).isFinite,
          isTrue,
          reason: expression,
        );
      }
      for (final expression in [
        'asin(1.0001)',
        'asin(-1.0001)',
        'acos(2)',
        'acos(-5)',
      ]) {
        expect(
          () => engine.evaluate(expression),
          throwsA(
            predicate<CalculatorException>(
              (error) => error.type == CalculatorErrorType.domain,
            ),
          ),
          reason: expression,
        );
      }
    });

    test('evaluates logarithms', () {
      expect(engine.evaluate('log(1000)'), closeTo(3, 1e-12));
      expect(engine.evaluate('ln(e)'), closeTo(1, 1e-12));
    });

    test('supports pi, e and Ans', () {
      expect(engine.evaluate('pi'), closeTo(math.pi, 1e-12));
      expect(engine.evaluate('e'), closeTo(math.e, 1e-12));
      expect(engine.evaluate('Ans × 2', answer: 7), 14);
    });

    test('supports implicit multiplication and decimal comma', () {
      expect(engine.evaluate('2π'), closeTo(2 * math.pi, 1e-12));
      expect(engine.evaluate('2(3+4)'), 14);
      expect(engine.evaluate('(2+3)(4+5)'), 45);
      expect(engine.evaluate('1,5 + 2,5'), 4);
    });

    test('rejects malformed expressions without crashing', () {
      expect(
        () => engine.evaluate('5 ++ 2'),
        throwsA(isA<CalculatorException>()),
      );
      expect(
        () => engine.evaluate('3.4.5'),
        throwsA(isA<CalculatorException>()),
      );
      expect(
        () => engine.evaluate('((3 + 2)'),
        throwsA(isA<CalculatorException>()),
      );
    });

    test('reports division by zero', () {
      expect(
        () => engine.evaluate('1 / 0'),
        throwsA(
          predicate<CalculatorException>(
            (error) => error.type == CalculatorErrorType.divisionByZero,
          ),
        ),
      );
    });

    test('reports domain and undefined results', () {
      expect(
        () => engine.evaluate('sqrt(-1)'),
        throwsA(
          predicate<CalculatorException>(
            (error) => error.type == CalculatorErrorType.domain,
          ),
        ),
      );
      expect(
        () => engine.evaluate('tan(90)', angleMode: AngleMode.degrees),
        throwsA(
          predicate<CalculatorException>(
            (error) => error.type == CalculatorErrorType.undefined,
          ),
        ),
      );
    });
  });

  group('ResultFormatter', () {
    const formatter = ResultFormatter();

    test('removes unnecessary zeros and negative zero', () {
      expect(formatter.format(5), '5');
      expect(formatter.format(-0.0), '0');
    });

    test('uses scientific notation for extreme values', () {
      expect(formatter.format(1200000000000), contains('e+'));
      expect(formatter.format(0.00000001), contains('e-'));
    });

    test('honors decimal precision', () {
      expect(formatter.format(1 / 3, precision: 4), '0.3333');
    });
  });
}

import 'package:calcademy/features/quiz/domain/math_answer_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String normalize(String value) => MathAnswerNormalizer.normalize(value);

  void expectSame(String a, String b) => expect(
    normalize(a),
    normalize(b),
    reason: '"$a" and "$b" should normalize alike',
  );

  group('whitespace and case', () {
    test('collapses spacing and casing', () {
      expectSame('  Cos X ', 'cosx');
      expectSame('2X + 1', '2x+1');
      expectSame('SEC X TAN X', 'sec x tan x');
    });

    test('empty and whitespace-only input normalize to empty', () {
      expect(normalize(''), '');
      expect(normalize('   '), '');
    });
  });

  group('minus signs', () {
    test('folds unicode dashes onto the ascii minus', () {
      expectSame('−sin x', '-sin x');
      expectSame('–cos x', '-cos x');
      expectSame('—2x', '-2x');
      expectSame('x−1', 'x-1');
    });

    test('keeps sign differences that matter', () {
      expect(normalize('-sin x') == normalize('sin x'), isFalse);
    });
  });

  group('function parentheses', () {
    test('sinx and sin(x) agree', () => expectSame('sinx', 'sin(x)'));
    test('cosx and cos(x) agree', () => expectSame('cosx', 'cos(x)'));
    test('handles multi-token arguments', () {
      expectSame('3cos(3x)', '3cos3x');
      expectSame('sin(2x)', 'sin 2x');
    });

    test('keeps parentheses when the argument has structure', () {
      expect(normalize('sin(x+1)'), 'sin(x+1)');
      expect(normalize('ln(x^2)'), 'ln(x^2)');
    });

    test('strips parentheses inside a group it must keep', () {
      expect(normalize('ln(sin(x) + 1)'), 'ln(sinx+1)');
    });

    test('does not mistake arcsin for arc plus sin', () {
      expect(normalize('arcsin(x)'), 'arcsinx');
    });

    test('an exponent on the function keeps its argument foldable', () {
      expectSame('sec^2 x', 'sec^2(x)');
      expect(normalize('sec(x)^2') == normalize('sec^2 x'), isFalse);
    });

    test('folds adjacent calls independently', () {
      expectSame('sin(x)cos(x)', 'sinxcosx');
    });
  });

  group('the exponential function', () {
    test('exp(u) and e^u are the same answer', () {
      expectSame('exp(x)', 'e^x');
      expectSame('exp(2x)', 'e^(2x)');
      expectSame('exp (x)', 'e^x');
      expectSame('-2exp(-2x)', '-2e^(-2x)');
      expectSame('exp(x) + 1/x', 'e^x + 1/x');
    });

    test('does not fold an unrelated name that merely starts with e', () {
      expect(normalize('exp(x)') == normalize('e'), isFalse);
      expect(normalize('exp(x)') == normalize('e^2x'), isFalse);
    });
  });

  group('multiplication symbols', () {
    test('treats explicit multiplication as optional', () {
      expectSame('3*x', '3x');
      expectSame('3·x', '3x');
      expectSame('3×x', '3x');
      expectSame('2 * sin x * cos x', '2 sin x cos x');
    });

    test('reads ** as exponentiation, not multiplication', () {
      expectSame('x**2', 'x^2');
    });
  });

  group('exponents', () {
    test('folds superscript digits', () {
      expectSame('3x²', '3x^2');
      expectSame('x⁵', 'x^5');
    });

    test('folds superscript signs', () {
      expectSame('-2x⁻³', '-2x^-3');
    });

    test('drops parentheses around a simple exponent', () {
      expectSame('e^(2x)', 'e^2x');
      expectSame('x^(-1/3)', 'x^-1/3');
    });
  });

  group('other conventions', () {
    test('folds the root and division glyphs', () {
      expectSame('1/(2√x)', '1/(2sqrt(x))');
      expectSame('1÷x', '1/x');
    });

    test('drops a leading assignment', () {
      expectSame('y = 2x', '2x');
      expectSame("f'(x) = 2x", '2x');
      expectSame('dy/dx=2x', '2x');
    });

    test('drops redundant outer parentheses and a leading plus', () {
      expectSame('(3x^2)', '3x^2');
      expectSame('+3x', '3x');
    });

    test('keeps parentheses that are not redundant', () {
      expect(normalize('(x+1)(x-1)'), '(x+1)(x-1)');
    });
  });
}

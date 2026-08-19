import 'package:calcademy/features/quiz/data/quiz_question_repository.dart';
import 'package:calcademy/features/quiz/domain/math_answer_normalizer.dart';
import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/presentation/math_display.dart';
import 'package:flutter_test/flutter_test.dart';

/// Display polish is only safe if it cannot reach grading. The round-trip
/// group is the load-bearing part of this file: whatever the helper does to a
/// string, both spellings have to normalize to the same thing.
void main() {
  group('raising exponents', () {
    test('lifts digits, letters, and signs', () {
      expect(MathDisplay.format('x^2'), 'x²');
      expect(MathDisplay.format('x^3'), 'x³');
      expect(MathDisplay.format('x^10'), 'x¹⁰');
      expect(MathDisplay.format('e^x'), 'eˣ');
      expect(MathDisplay.format('x^n'), 'xⁿ');
      expect(MathDisplay.format('a^x ln a'), 'aˣ ln a');
      expect(MathDisplay.format('-x^-2'), '-x⁻²');
    });

    test('lifts a parenthesized exponent as a whole', () {
      expect(MathDisplay.format('n x^(n-1)'), 'n xⁿ⁻¹');
      expect(MathDisplay.format('x^(n+1)/(n+1) + C'), 'xⁿ⁺¹/(n+1) + C');
      expect(MathDisplay.format('e^(kx)/k + C'), 'eᵏˣ/k + C');
    });

    test('closes the gap after a raised function power', () {
      expect(MathDisplay.format('sec^2 x'), 'sec²x');
      expect(MathDisplay.format('-csc^2 x'), '-csc²x');
      // The space between two factors is not the same space and stays put.
      expect(MathDisplay.format('∫ x^2 dx'), '∫ x² dx');
    });

    test('writes roots and logarithm bases with their own glyphs', () {
      expect(MathDisplay.format('sqrt(x)'), '√x');
      expect(MathDisplay.format('1/(2sqrt(x))'), '1/(2√x)');
      expect(MathDisplay.format('d/dx (log_a x)'), 'd/dx (logₐ x)');
    });

    test('leaves what it cannot represent in caret form', () {
      // A fraction in the exponent has no glyph, so the source spelling is
      // kept whole rather than half-converted.
      expect(MathDisplay.format('(1/2)x^(-1/2)'), '(1/2)x^(-1/2)');
      expect(MathDisplay.format(''), '');
      expect(MathDisplay.format('cos x'), 'cos x');
    });
  });

  group('the normalizer reads back what the display writes', () {
    test('a superscript typed by the learner grades as caret notation', () {
      for (final pair in const [
        ['x²', 'x^2'],
        ['xⁿ⁻¹', 'x^(n-1)'],
        ['eˣ', 'e^x'],
        ['sec²x', 'sec^2 x'],
        ['√x', 'sqrt(x)'],
        ['logₐx', 'log_a x'],
      ]) {
        expect(
          MathAnswerNormalizer.normalize(pair[0]),
          MathAnswerNormalizer.normalize(pair[1]),
          reason: '"${pair[0]}" does not read as "${pair[1]}"',
        );
      }
    });

    test('every string the bank displays normalizes to what it stores', () {
      for (final question in QuizQuestionBank.all) {
        final strings = <String>[
          question.expression,
          question.correctAnswer,
          ...question.acceptedAnswers,
          for (final option in question.options) option.text,
        ];
        for (final source in strings) {
          expect(
            MathAnswerNormalizer.normalize(MathDisplay.format(source)),
            MathAnswerNormalizer.normalize(source),
            reason: '${question.id}: "$source" changes meaning when displayed',
          );
        }
      }
    });

    test('a polished multiple-choice option still grades as its own', () {
      for (final question in QuizQuestionBank.all.where(
        (question) => question.type == QuestionType.multipleChoice,
      )) {
        final target = MathAnswerNormalizer.normalize(question.correctAnswer);
        final matches = question.options
            .where(
              (option) =>
                  MathAnswerNormalizer.normalize(
                    MathDisplay.format(option.text),
                  ) ==
                  target,
            )
            .length;
        expect(matches, 1, reason: question.id);
      }
    });
  });

  group('what the learner sees', () {
    test('no visible expression or answer is left in caret notation', () {
      for (final question in QuizQuestionBank.all) {
        final visible = <String>[
          question.expression,
          question.correctAnswer,
          for (final option in question.options) option.text,
        ];
        for (final source in visible) {
          final displayed = MathDisplay.format(source);
          expect(
            displayed,
            isNot(contains('^')),
            reason: '${question.id} shows raw caret notation: "$displayed"',
          );
          expect(
            displayed,
            isNot(contains('sqrt')),
            reason: '${question.id} shows "sqrt" rather than √',
          );
        }
      }
    });
  });
}

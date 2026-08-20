import 'package:calcademy/features/quiz/domain/math_answer_normalizer.dart';
import 'package:calcademy/features/quiz/presentation/widgets/math_token_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The row is optional help, so the bar it has to clear is that it never makes
/// the field worse: it types where the cursor is, and everything it types is
/// something the normalizer already accepts.
void main() {
  group('inserting at the cursor', () {
    test('writes where the cursor is, not at the end', () {
      final controller = TextEditingController(text: 'xC')
        ..selection = const TextSelection.collapsed(offset: 1);

      insertMathInputToken(controller, '^2');

      expect(controller.text, 'x^2C');
      expect(controller.selection.baseOffset, 3);
    });

    test('replaces a selection', () {
      final controller = TextEditingController(text: 'sin x')
        ..selection = const TextSelection(baseOffset: 0, extentOffset: 3);

      insertMathInputToken(controller, 'cos');

      expect(controller.text, 'cos x');
      expect(controller.selection.baseOffset, 3);
    });

    test('appends when the field has never been focused', () {
      // An untouched controller reports offset -1 rather than 0, which would
      // otherwise put every first tap in front of the answer.
      final controller = TextEditingController(text: 'ln|x|');
      expect(controller.selection.isValid, isFalse);

      insertMathInputToken(controller, ' + C');

      expect(controller.text, 'ln|x| + C');
      expect(controller.selection.baseOffset, 9);
    });

    test('parks the cursor inside a bracket pair', () {
      final controller = TextEditingController(text: 'e^')
        ..selection = const TextSelection.collapsed(offset: 2);

      insertMathInputToken(controller, '()', caretBack: 1);

      expect(controller.text, 'e^()');
      expect(controller.selection.baseOffset, 3);
    });
  });

  group('the row itself', () {
    testWidgets('a tap types the token into the field', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(tester, controller);

      await tester.tap(find.byKey(const Key('quiz-math-token-e^x')));
      await tester.tap(find.byKey(const Key('quiz-math-token-+ C')));
      await tester.pump();

      expect(controller.text, 'e^x + C');
    });

    testWidgets('typing between two taps keeps the cursor honest', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(tester, controller);

      await tester.enterText(find.byType(TextField), 'x');
      await tester.tap(find.byKey(const Key('quiz-math-token-^')));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '${controller.text}2');
      await tester.tap(find.byKey(const Key('quiz-math-token-+ C')));
      await tester.pump();

      expect(controller.text, 'x^2 + C');
    });

    testWidgets('every token types something the normalizer accepts', (
      tester,
    ) async {
      for (final token in MathTokenRow.tokens) {
        expect(
          () => MathAnswerNormalizer.normalize(token.insert),
          returnsNormally,
          reason: '"${token.insert}" broke normalization',
        );
      }
      // The two shortcuts that stand in for whole answers have to grade as the
      // spellings a learner would otherwise type by hand.
      expect(
        MathAnswerNormalizer.normalize('e^x'),
        MathAnswerNormalizer.normalize('exp(x)'),
      );
      expect(
        MathAnswerNormalizer.normalize('√x'),
        MathAnswerNormalizer.normalize('sqrt(x)'),
      );
    });

    testWidgets('goes quiet once the question is answered', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(tester, controller, enabled: false);

      final button = tester.widget<OutlinedButton>(
        find.byKey(const Key('quiz-math-token-x')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('fits the narrowest supported phone', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pump(tester, controller);

      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pump(
  WidgetTester tester,
  TextEditingController controller, {
  bool enabled = true,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          MathTokenRow(controller: controller, enabled: enabled),
          TextField(controller: controller),
        ],
      ),
    ),
  ),
);

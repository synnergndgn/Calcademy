import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/domain/quiz_subject.dart';
import 'package:calcademy/features/quiz/domain/quiz_topic.dart';
import 'package:calcademy/features/quiz/presentation/math_display.dart';
import 'package:calcademy/features/quiz/presentation/widgets/math_formula.dart';
import 'package:calcademy/features/quiz/presentation/widgets/quiz_feedback_panel.dart';
import 'package:calcademy/features/quiz/presentation/widgets/quiz_option_tile.dart';
import 'package:calcademy/features/quiz/presentation/widgets/quiz_question_card.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// The widget is the surface the learner actually reads, so these assert what
/// it draws rather than what a string helper returns: an exponent has to
/// become its own run, off the baseline, in every place a formula appears.
void main() {
  group('drawing an expression', () {
    testWidgets('lifts a multi-character exponent as one run', (tester) async {
      await _pump(tester, const MathFormula('x^(n+1)'));

      expect(_runs(tester), [_Run('n+1', raised: true)]);
      expect(_baseline(tester, 'n+1'), lessThan(0));
    });

    testWidgets('lifts every exponent shape the bank uses', (tester) async {
      for (final pair in const [
        ('x^2', '2'),
        ('x^(n-1)', 'n-1'),
        ('e^x', 'x'),
        ('e^(kx)', 'kx'),
        ('sec^2 x', '2'),
        ('a^x', 'x'),
      ]) {
        await _pump(tester, MathFormula(pair.$1));
        expect(_runs(tester), [
          _Run(pair.$2, raised: true),
        ], reason: '"${pair.$1}" did not lift "${pair.$2}"');
      }
    });

    testWidgets('lowers a logarithm base', (tester) async {
      await _pump(tester, const MathFormula('log_a x'));

      expect(_runs(tester), [_Run('a', raised: false)]);
      expect(_baseline(tester, 'a'), greaterThan(0));
    });

    testWidgets('lifts an exponent Unicode cannot spell', (tester) async {
      // The one case the plain-text spelling gives up on. Nothing here can:
      // a raised run is ordinary text drawn smaller, so a fraction in the
      // exponent is no harder than a digit.
      await _pump(
        tester,
        const MathFormula('sqrt(x) is x^(1/2), so it is (1/2)x^(-1/2).'),
      );

      expect(_runs(tester), [
        _Run('1/2', raised: true),
        _Run('-1/2', raised: true),
      ]);
      expect(_plainRuns(tester).join(), startsWith('√x is x'));
    });

    testWidgets('draws a raised run smaller than the line it sits on', (
      tester,
    ) async {
      await _pump(
        tester,
        const MathFormula('x^2', style: TextStyle(fontSize: 20)),
      );

      final raised = tester.widget<Text>(
        find.descendant(of: find.byType(Transform), matching: find.text('2')),
      );
      expect(raised.style!.fontSize, lessThan(20));
    });

    testWidgets('announces the plain-text spelling to a screen reader', (
      tester,
    ) async {
      await _pump(tester, const MathFormula('x^(n+1)/(n+1) + C'));

      final text = tester.widget<Text>(
        find
            .descendant(
              of: find.byType(MathFormula),
              matching: find.byType(Text),
            )
            .first,
      );
      expect(text.semanticsLabel, MathDisplay.format('x^(n+1)/(n+1) + C'));
    });

    testWidgets('renders a selectable expression without throwing', (
      tester,
    ) async {
      await _pump(
        tester,
        const MathFormula('d/dx (log_a x)', selectable: true),
      );

      expect(tester.takeException(), isNull);
      expect(_runs(tester), [_Run('a', raised: false)]);
      // A selectable formula announces itself whole too, rather than as the
      // fragments the raised runs split it into.
      final semantics = tester.getSemantics(find.byType(MathFormula));
      expect(semantics.label, MathDisplay.format('d/dx (log_a x)'));
    });
  });

  group('the same formula everywhere', () {
    /// A learner sees one expression on the question card, in an option, and
    /// again in the feedback panel. Any difference between those readings is
    /// the half-conversion this widget exists to prevent.
    const source = 'x^(n+1)/(n+1) + C';

    testWidgets('the question card and an option agree', (tester) async {
      await _pump(tester, const QuizQuestionCard(question: _question));
      final onCard = _runs(tester);

      await _pump(
        tester,
        const QuizOptionTile(
          option: QuizOption(id: 'a', text: source),
          label: 'A',
          state: QuizOptionState.idle,
        ),
      );
      expect(_runs(tester), onCard);
    });

    testWidgets('the feedback panel agrees with both', (tester) async {
      await _pump(
        tester,
        const QuizFeedbackPanel(
          isCorrect: false,
          correctAnswer: source,
          submittedAnswer: 'x^n',
          explanation: 'Raise the exponent, then divide by it: x^(n+1)/(n+1).',
        ),
      );

      // Correct answer, submitted answer, and the formula quoted in the
      // explanation are all lifted the same way.
      expect(_runs(tester), [
        _Run('n', raised: true),
        _Run('n+1', raised: true),
        _Run('n+1', raised: true),
      ]);
    });

    testWidgets('an option and the correct answer that matches it agree', (
      tester,
    ) async {
      await _pump(
        tester,
        const QuizOptionTile(
          option: QuizOption(id: 'a', text: 'sec^2 x'),
          label: 'A',
          state: QuizOptionState.correct,
        ),
      );
      final asOption = _runs(tester);

      await _pump(
        tester,
        const QuizFeedbackPanel(
          isCorrect: true,
          correctAnswer: 'sec^2 x',
          explanation: 'The quotient rule collapses to it.',
        ),
      );
      expect(_runs(tester), asOption);
    });
  });
}

/// The question card needs a whole row, and only its expression matters here.
const _question = QuizQuestion(
  id: 'test-01',
  subject: QuizSubject.calculus,
  topicId: 'calculus-basic-integrals',
  subtopic: QuizSubtopic.powerRuleIntegral,
  difficulty: QuizDifficulty.easy,
  type: QuestionType.written,
  prompt: QuizPrompt.integral,
  expression: 'x^(n+1)/(n+1) + C',
  correctAnswer: 'x^(n+1)/(n+1) + C',
  explanationEn: 'Raise, then divide.',
  explanationTr: 'Artır, sonra böl.',
);

/// One run drawn off the baseline: what it says, and which way it went.
class _Run {
  const _Run(this.text, {required this.raised});

  final String text;
  final bool raised;

  @override
  bool operator ==(Object other) =>
      other is _Run && other.text == text && other.raised == raised;

  @override
  int get hashCode => Object.hash(text, raised);

  @override
  String toString() => raised ? '^$text' : '_$text';
}

/// Every off-baseline run currently on screen, in reading order.
///
/// Read from the widget tree rather than from the span list, so the assertion
/// covers what a placeholder actually resolved to.
List<_Run> _runs(WidgetTester tester) => tester
    .widgetList<Transform>(find.byType(Transform))
    .where((transform) => transform.child is Text)
    .map(
      (transform) => _Run(
        (transform.child! as Text).data!,
        raised: transform.transform.storage[13] < 0,
      ),
    )
    .toList();

/// How far a run was moved off the baseline: negative is up.
double _baseline(WidgetTester tester, String text) => tester
    .widgetList<Transform>(find.byType(Transform))
    .firstWhere(
      (transform) =>
          transform.child is Text && (transform.child! as Text).data == text,
    )
    .transform
    .storage[13];

/// The on-baseline pieces, which is where a leaked caret would show up.
List<String> _plainRuns(WidgetTester tester) {
  final root = tester.widget<Text>(
    find
        .descendant(of: find.byType(MathFormula), matching: find.byType(Text))
        .first,
  );
  return [
    for (final span in (root.textSpan! as TextSpan).children!)
      if (span is TextSpan) span.text!,
  ];
}

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

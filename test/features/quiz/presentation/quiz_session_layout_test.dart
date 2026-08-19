import 'dart:math';

import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/quiz/application/quiz_session_controller.dart';
import 'package:calcademy/features/quiz/data/quiz_topic_registry.dart';
import 'package:calcademy/features/quiz/domain/quiz_answer_validator.dart';
import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/domain/quiz_session.dart';
import 'package:calcademy/features/quiz/domain/quiz_subject.dart';
import 'package:calcademy/features/quiz/presentation/quiz_result_page.dart';
import 'package:calcademy/features/quiz/presentation/quiz_review_page.dart';
import 'package:calcademy/features/quiz/presentation/quiz_session_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The three in-session screens cannot join the shared page matrix in
/// production_readiness_test.dart, because they render nothing without a live
/// session. They get the same shapes here instead.
const _pages = <String, Widget>{
  'Quiz Session': QuizSessionPage(),
  'Quiz Result': QuizResultPage(),
  'Quiz Review': QuizReviewPage(),
};

/// The narrowest phone the app supports, at the largest system text size
/// Android offers. Everything in the session flow has to survive this, so it
/// is asserted rather than left to a spot check.
const _smallestSupported = Size(320, 640);
const _largestTextScale = 2.0;

void main() {
  for (final questionType in QuestionType.values) {
    group('every in-session page renders (${questionType.name})', () {
      _pages.forEach((name, page) {
        testWidgets('$name on a modern phone', (tester) async {
          await _pump(tester, page, questionType: questionType);
          expect(tester.takeException(), isNull, reason: '$name threw');
        });

        testWidgets('$name on a small screen at 1.3 text scale', (
          tester,
        ) async {
          await _pump(
            tester,
            page,
            questionType: questionType,
            size: const Size(360, 640),
            textScale: 1.3,
          );
          expect(tester.takeException(), isNull, reason: '$name overflowed');
        });

        testWidgets('$name in Turkish', (tester) async {
          await _pump(
            tester,
            page,
            questionType: questionType,
            size: const Size(360, 640),
            locale: 'tr',
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$name overflowed in TR',
          );
        });

        testWidgets('$name in dark mode', (tester) async {
          await _pump(tester, page, questionType: questionType, dark: true);
          expect(tester.takeException(), isNull, reason: '$name threw in dark');
        });

        testWidgets('$name at tablet width', (tester) async {
          await _pump(
            tester,
            page,
            questionType: questionType,
            size: const Size(1024, 1366),
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$name threw on tablet',
          );
        });
      });
    });

    group('320px at 200% text scale (${questionType.name})', () {
      for (final locale in ['en', 'tr']) {
        _pages.forEach((name, page) {
          testWidgets('$name holds at 320px / 200% in $locale', (tester) async {
            await _pump(
              tester,
              page,
              questionType: questionType,
              size: _smallestSupported,
              textScale: _largestTextScale,
              locale: locale,
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '$name overflowed at 320px / 200% in $locale',
            );
          });
        });

        testWidgets(
          'the feedback panel stays laid out at 320px / 200% in $locale',
          (tester) async {
            await _pump(
              tester,
              const QuizSessionPage(),
              questionType: questionType,
              size: _smallestSupported,
              textScale: _largestTextScale,
              locale: locale,
            );

            // The seeded session ends on an answered question, so the panel
            // is really in the list; at this size it just sits below the fold.
            await _scrollTo(
              tester,
              listKey: const Key('quiz-session-scroll'),
              target: const Key('quiz-feedback-panel'),
            );
            expect(
              find.byKey(const Key('quiz-feedback-panel')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    });
  }

  group('the missing-constant note', () {
    testWidgets('renders inside the feedback panel at 320px / 200%', (
      tester,
    ) async {
      final container = await _pump(
        tester,
        const QuizSessionPage(),
        questionType: QuestionType.written,
        size: _smallestSupported,
        textScale: _largestTextScale,
        answerFor: _answerWithoutConstant,
      );

      expect(container.read(quizResultProvider)!.noteKeys, isNotEmpty);
      await _scrollTo(
        tester,
        listKey: const Key('quiz-session-scroll'),
        target: const Key('quiz-feedback-note'),
      );
      expect(find.byKey(const Key('quiz-feedback-note')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders on the result page at 320px / 200% in Turkish', (
      tester,
    ) async {
      final container = await _pump(
        tester,
        const QuizResultPage(),
        questionType: QuestionType.written,
        size: _smallestSupported,
        textScale: _largestTextScale,
        locale: 'tr',
        answerFor: _answerWithoutConstant,
      );

      final result = container.read(quizResultProvider)!;
      // A noted answer scores, so it never reaches review; the result screen
      // is the only place it can be raised.
      expect(result.correctCount, result.totalQuestions);
      await _scrollTo(
        tester,
        listKey: const Key('quiz-result-scroll'),
        target: const Key('quiz-result-notes'),
      );
      expect(find.byKey(const Key('quiz-result-notes')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Scrolls a page's list until [target] is built and on screen.
///
/// At 320px and 200% text the feedback block sits well below the fold, and a
/// ListView never builds what it has not reached; without this the assertion
/// would measure the viewport rather than the layout.
Future<void> _scrollTo(
  WidgetTester tester, {
  required Key listKey,
  required Key target,
}) async {
  await tester.scrollUntilVisible(
    find.byKey(target),
    200,
    // A text field carries its own Scrollable, so the list's outermost one
    // has to be picked rather than matched loosely.
    scrollable: find
        .descendant(of: find.byKey(listKey), matching: find.byType(Scrollable))
        .first,
  );
  await tester.pumpAndSettle();
}

/// Seeds a session where the first answer is wrong and the rest are right, so
/// the result and review screens both have content to lay out.
Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget page, {
  required QuestionType questionType,
  Size size = const Size(390, 844),
  double textScale = 1,
  bool dark = false,
  String locale = 'en',
  String Function(QuizQuestion question, int index)? answerFor,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  SharedPreferences.setMockInitialValues({'settings.language': locale});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
  );
  addTearDown(container.dispose);

  final answer = answerFor ?? _firstWrongRestRight;
  final controller = container.read(quizSessionProvider.notifier)
    ..start(
      QuizSessionConfig(
        subject: QuizSubject.calculus,
        topicIds: const {CalculusTopicIds.basicIntegrals},
        questionType: questionType,
      ),
      random: Random(11),
    );
  for (var index = 0; index < 10; index++) {
    final question = container.read(quizSessionProvider)!.currentQuestion;
    controller
      ..submit(answer(question, index))
      ..next();
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

String _firstWrongRestRight(QuizQuestion question, int index) =>
    index == 0 ? _wrongAnswer(question) : _rightAnswer(question);

/// Every answer right except for the constant of integration, which is what
/// puts a note on each entry.
String _answerWithoutConstant(QuizQuestion question, int index) =>
    question.correctAnswer.replaceAll(RegExp(r'\s*\+\s*C$'), '');

String _rightAnswer(QuizQuestion question) =>
    question.type == QuestionType.written
    ? question.correctAnswer
    : QuizAnswerValidator.correctOption(question)!.id;

String _wrongAnswer(QuizQuestion question) =>
    question.type == QuestionType.written
    ? 'not the answer'
    : question.options
          .firstWhere(
            (option) =>
                option.id != QuizAnswerValidator.correctOption(question)!.id,
          )
          .id;

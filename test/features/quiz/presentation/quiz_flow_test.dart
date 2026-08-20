import 'package:calcademy/app/router.dart';
import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/home/presentation/home_page.dart';
import 'package:calcademy/features/quiz/application/quiz_session_controller.dart';
import 'package:calcademy/features/quiz/data/quiz_topic_registry.dart';
import 'package:calcademy/features/quiz/domain/quiz_answer_validator.dart';
import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/presentation/quiz_home_page.dart';
import 'package:calcademy/features/quiz/presentation/quiz_result_page.dart';
import 'package:calcademy/features/quiz/presentation/quiz_review_page.dart';
import 'package:calcademy/features/quiz/presentation/quiz_session_page.dart';
import 'package:calcademy/features/quiz/presentation/widgets/math_formula.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('subject list offers calculus and locks empty subjects', (
    tester,
  ) async {
    await _pumpPage(tester, const QuizHomePage());

    expect(find.byKey(const Key('quiz-subject-calculus')), findsOneWidget);
    expect(find.text('Basic derivatives'), findsNothing);
    expect(find.text('Question bank in progress'), findsWidgets);
  });

  testWidgets('walking the funnel starts a multiple-choice session', (
    tester,
  ) async {
    final container = await _pumpRouter(tester, '/quiz');

    await tester.tap(find.byKey(const Key('quiz-subject-calculus')));
    await tester.pumpAndSettle();
    expect(find.text('Choose a topic'), findsWidgets);

    await tester.tap(
      find.byKey(const Key('quiz-topic-${CalculusTopicIds.basicDerivatives}')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quiz-mode-multipleChoice')), findsOneWidget);
    expect(find.text('10 questions available'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quiz-mode-start')));
    await tester.pumpAndSettle();

    expect(find.byType(QuizSessionPage), findsOneWidget);
    expect(find.text('Question 1 / 10'), findsOneWidget);
    expect(find.byKey(const Key('quiz-options')), findsOneWidget);

    final session = container.read(quizSessionProvider)!;
    expect(session.questions.length, 10);
    expect(
      session.questions.every(
        (question) =>
            question.topicId == CalculusTopicIds.basicDerivatives &&
            question.type == QuestionType.multipleChoice,
      ),
      isTrue,
    );
  });

  testWidgets('immediate feedback reveals the verdict and the rule', (
    tester,
  ) async {
    final container = await _pumpRouter(tester, '/quiz');
    await _startSession(tester);

    final question = container.read(quizSessionProvider)!.currentQuestion;
    final wrong = question.options.firstWhere(
      (option) => option.id != QuizAnswerValidator.correctOption(question)!.id,
    );

    await tester.tap(find.byKey(Key('quiz-option-${wrong.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz-feedback-panel')), findsOneWidget);
    expect(find.text('Incorrect'), findsOneWidget);
    // Explanations reach the screen through the formula renderer, not as
    // printed source, so the assertion is on what was handed to it.
    expect(_formula(question.explanation('en')), findsOneWidget);
    expect(find.byKey(const Key('quiz-advance')), findsOneWidget);
  });

  testWidgets('a written answer is graded after normalization', (tester) async {
    final container = await _pumpRouter(tester, '/quiz');
    await _startSession(tester, written: true);

    expect(find.byKey(const Key('quiz-answer-field')), findsOneWidget);
    final question = container.read(quizSessionProvider)!.currentQuestion;

    await tester.enterText(
      find.byKey(const Key('quiz-answer-field')),
      '  ${question.correctAnswer.toUpperCase()}  ',
    );
    // The submit button tracks the field, so it needs a frame to re-enable.
    await tester.pump();
    await tester.tap(find.byKey(const Key('quiz-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Correct'), findsOneWidget);
    expect(container.read(quizSessionProvider)!.correctCount, 1);
  });

  testWidgets('a blank written answer cannot be submitted', (tester) async {
    final container = await _pumpRouter(tester, '/quiz');
    await _startSession(tester, written: true);

    // A submission is final, so an empty field must not be spendable.
    expect(
      tester
          .widget<ButtonStyleButton>(find.byKey(const Key('quiz-submit')))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byKey(const Key('quiz-answer-field')), '   ');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ButtonStyleButton>(find.byKey(const Key('quiz-submit')))
          .onPressed,
      isNull,
    );
    expect(container.read(quizSessionProvider)!.currentAnswer, isNull);

    await tester.enterText(find.byKey(const Key('quiz-answer-field')), '0');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ButtonStyleButton>(find.byKey(const Key('quiz-submit')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('end-of-session mode withholds the verdict until the result', (
    tester,
  ) async {
    final container = await _pumpRouter(tester, '/quiz');
    await _startSession(tester, endOfSession: true);

    final question = container.read(quizSessionProvider)!.currentQuestion;
    await tester.tap(
      find.byKey(
        Key('quiz-option-${QuizAnswerValidator.correctOption(question)!.id}'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Answer recorded'), findsOneWidget);
    expect(find.text('Correct'), findsNothing);
    expect(find.byKey(const Key('quiz-feedback-correct-answer')), findsNothing);
  });

  testWidgets('finishing the session shows a score and a review of misses', (
    tester,
  ) async {
    final container = await _pumpRouter(tester, '/quiz');
    await _startSession(tester);

    // Answer the first question wrong and the remaining nine correctly.
    for (var index = 0; index < 10; index++) {
      final question = container.read(quizSessionProvider)!.currentQuestion;
      final correct = QuizAnswerValidator.correctOption(question)!;
      final target = index == 0
          ? question.options.firstWhere((option) => option.id != correct.id)
          : correct;
      await tester.tap(find.byKey(Key('quiz-option-${target.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quiz-advance')));
      await tester.pumpAndSettle();
    }

    expect(find.byType(QuizResultPage), findsOneWidget);
    expect(find.text('9 / 10'), findsOneWidget);
    expect(find.textContaining('90%'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quiz-result-review')));
    await tester.pumpAndSettle();

    expect(find.byType(QuizReviewPage), findsOneWidget);
    final missed = container
        .read(quizResultProvider)!
        .incorrectEntries
        .single
        .question;
    expect(find.byKey(Key('quiz-review-${missed.id}')), findsOneWidget);
    // The review screen typesets its entries the same way the session does:
    // the expression, the correct answer, and the rule behind it.
    expect(_formula(missed.expression), findsOneWidget);
    expect(_formula(missed.correctAnswer), findsOneWidget);
    expect(_formula(missed.explanation('en')), findsOneWidget);
  });

  testWidgets('a perfect run offers nothing to review', (tester) async {
    final container = await _pumpRouter(tester, '/quiz');
    await _startSession(tester);

    for (var index = 0; index < 10; index++) {
      final question = container.read(quizSessionProvider)!.currentQuestion;
      await tester.tap(
        find.byKey(
          Key('quiz-option-${QuizAnswerValidator.correctOption(question)!.id}'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quiz-advance')));
      await tester.pumpAndSettle();
    }

    expect(find.text('10 / 10'), findsOneWidget);
    expect(find.byKey(const Key('quiz-result-all-correct')), findsOneWidget);
    expect(find.byKey(const Key('quiz-result-review')), findsNothing);
  });

  testWidgets('leaving mid-session asks first, then clears the session', (
    tester,
  ) async {
    final container = await _pumpRouter(tester, '/quiz');
    await _startSession(tester);

    await tester.tap(find.byKey(const Key('quiz-session-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quiz-exit-dialog')), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(container.read(quizSessionProvider), isNotNull);

    await tester.tap(find.byKey(const Key('quiz-session-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quiz-exit-confirm')));
    await tester.pumpAndSettle();

    expect(container.read(quizSessionProvider), isNull);
    expect(find.byType(QuizHomePage), findsOneWidget);
  });

  group('leaving the quiz keeps a way back', () {
    testWidgets('exiting a session lands on Quiz with Home still under it', (
      tester,
    ) async {
      final container = await _pumpRouter(tester, '/home', push: '/quiz');
      await _startSession(tester);

      await tester.tap(find.byKey(const Key('quiz-session-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quiz-exit-confirm')));
      await tester.pumpAndSettle();

      expect(container.read(quizSessionProvider), isNull);
      expect(find.byType(QuizHomePage), findsOneWidget);
      // The page the learner pushed from is still underneath, so the app bar
      // has its own back button rather than the fallback one.
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byKey(const Key('quiz-home-back')), findsNothing);

      await _systemBack(tester);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('the system back gesture never leaves the app from Quiz', (
      tester,
    ) async {
      // A deep link into /quiz has nothing to pop: without a fallback the
      // gesture would quit the app from a page the learner navigated into.
      await _pumpRouter(tester, '/quiz');
      expect(find.byKey(const Key('quiz-home-back')), findsOneWidget);

      await _systemBack(tester);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('the fallback back button goes Home', (tester) async {
      await _pumpRouter(tester, '/quiz');

      await tester.tap(find.byKey(const Key('quiz-home-back')));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('back to topics from the result unwinds rather than resets', (
      tester,
    ) async {
      final container = await _pumpRouter(tester, '/home', push: '/quiz');
      await _startSession(tester);
      for (var index = 0; index < 10; index++) {
        final question = container.read(quizSessionProvider)!.currentQuestion;
        await tester.tap(
          find.byKey(
            Key(
              'quiz-option-${QuizAnswerValidator.correctOption(question)!.id}',
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('quiz-advance')));
        await tester.pumpAndSettle();
      }
      expect(find.byType(QuizResultPage), findsOneWidget);

      await tester.tap(find.byKey(const Key('quiz-result-topics')));
      await tester.pumpAndSettle();
      expect(find.text('Choose a topic'), findsWidgets);

      // Topic list -> subject list -> Home, with nothing lost on the way.
      await _systemBack(tester);
      expect(find.byType(QuizHomePage), findsOneWidget);
      await _systemBack(tester);
      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  testWidgets('the result page deep-linked without a session stays graceful', (
    tester,
  ) async {
    await _pumpRouter(tester, '/quiz/result');
    expect(find.byKey(const Key('quiz-result-empty')), findsOneWidget);
  });

  testWidgets('the session page deep-linked without a session stays graceful', (
    tester,
  ) async {
    await _pumpRouter(tester, '/quiz/session');
    expect(find.byKey(const Key('quiz-session-empty')), findsOneWidget);
  });
}

/// Walks subject -> topic -> mode and starts the quiz.
Future<void> _startSession(
  WidgetTester tester, {
  bool written = false,
  bool endOfSession = false,
}) async {
  await tester.tap(find.byKey(const Key('quiz-subject-calculus')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const Key('quiz-topic-${CalculusTopicIds.basicDerivatives}')),
  );
  await tester.pumpAndSettle();
  if (written) {
    await tester.tap(find.byKey(const Key('quiz-mode-written')));
    await tester.pumpAndSettle();
  }
  if (endOfSession) {
    await tester.tap(find.byKey(const Key('quiz-feedback-endOfSession')));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(const Key('quiz-mode-start')));
  await tester.pumpAndSettle();
}

/// Pumps the real router at [location], optionally with [push] stacked on
/// top of it -- which is how the app itself reaches the quiz from Home, and
/// therefore what the back behaviour has to be tested against.
Future<ProviderContainer> _pumpRouter(
  WidgetTester tester,
  String location, {
  String? push,
}) async {
  tester.view.physicalSize = const Size(420, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
  );
  addTearDown(container.dispose);

  appRouter.go(location);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: appRouter,
        theme: AppTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Pushed after the router is attached: a push issued before the first frame
  // is applied to an empty configuration and silently loses the page below.
  if (push != null) {
    appRouter.push(push);
    await tester.pumpAndSettle();
  }
  return container;
}

Future<void> _pumpPage(WidgetTester tester, Widget page) async {
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
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
}

/// The Android system back gesture, delivered the way the platform delivers
/// it, so PopScope and the router both see what they would see on a device.
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await tester.pumpAndSettle();
}

/// A formula on screen, matched by the source it was given rather than by the
/// text it drew: an exponent is its own widget, so it is not part of any one
/// string a text finder could match.
Finder _formula(String source) => find.byWidgetPredicate(
  (widget) => widget is MathFormula && widget.source == source,
);

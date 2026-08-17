import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/core/widgets/result_auto_scroll.dart';
import 'package:calcademy/features/calculus/presentation/calculus_page.dart';
import 'package:calcademy/features/equation_solver/presentation/equation_solver_page.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_calculator_page.dart';
import 'package:calcademy/features/matrix/presentation/matrix_home_page.dart';
import 'package:calcademy/features/statistics/presentation/statistics_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auto-scroll consistency across the calculation tools.
///
/// Linear and Integer Programming already revealed their result after a solve;
/// the other five tools left it below the fold, so pressing Calculate looked
/// like nothing happened. These tests pin the behaviour in both directions -
/// a success scrolls, a validation error does not - because the failing case
/// is the one that would quietly regress: yanking the viewport away from the
/// field the user is trying to fix is worse than not scrolling at all.
Future<void> _pump(WidgetTester tester, Widget page) async {
  // Short enough that every tool's result sits below the fold.
  tester.view.physicalSize = const Size(390, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({'settings.language': 'en'});
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

double _positionOffset(WidgetTester tester, Finder scrollView) => tester
    .state<ScrollableState>(
      find.descendant(of: scrollView, matching: find.byType(Scrollable)).first,
    )
    .position
    .pixels;

void main() {
  group('the shared helper', () {
    testWidgets('does not scroll when the key never mounted', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 2000),
                Container(key: key),
              ],
            ),
          ),
        ),
      );
      final scrollable = find.byType(Scrollable);
      final before = tester.state<ScrollableState>(scrollable).position.pixels;

      // A key that belongs to no tree at all is the disposed-page case.
      scheduleResultAutoScroll(GlobalKey());
      await tester.pumpAndSettle();

      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        before,
        reason: 'a key with no context must not move the viewport',
      );
    });

    testWidgets('reveals a mounted target', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 2000),
                SizedBox(key: key, height: 100),
              ],
            ),
          ),
        ),
      );
      final scrollable = find.byType(Scrollable);
      expect(tester.state<ScrollableState>(scrollable).position.pixels, 0);

      scheduleResultAutoScroll(key);
      await tester.pumpAndSettle();

      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(0),
      );
    });

    test('shares one timing with the optimization pages it came from', () {
      expect(resultAutoScrollDuration, const Duration(milliseconds: 320));
      expect(resultAutoScrollAlignment, 0.08);
    });
  });

  group('Statistics', () {
    testWidgets('scrolls to the result after a valid calculation', (
      tester,
    ) async {
      await _pump(tester, const StatisticsPage());
      final scrollView = find.byKey(const Key('statistics-scroll-view'));
      expect(_positionOffset(tester, scrollView), 0);

      await tester.enterText(
        find.byType(TextField).first,
        '4, 8, 15, 16, 23, 42',
      );
      await tester.tap(find.byKey(const Key('stats-descriptive-calculate')));
      await tester.pumpAndSettle();

      expect(
        _positionOffset(tester, scrollView),
        greaterThan(0),
        reason: 'a successful calculation should reveal its result',
      );
    });

    testWidgets('stays put when the input is invalid', (tester) async {
      await _pump(tester, const StatisticsPage());
      final scrollView = find.byKey(const Key('statistics-scroll-view'));

      // The controller converts this into a StatisticsFailureResult rather
      // than throwing, which is exactly the trap: no exception is not success.
      await tester.enterText(find.byType(TextField).first, 'not a dataset');
      await tester.tap(find.byKey(const Key('stats-descriptive-calculate')));
      await tester.pumpAndSettle();

      expect(
        _positionOffset(tester, scrollView),
        0,
        reason: 'a validation failure must not move the viewport',
      );
    });
  });

  group('Matrix', () {
    testWidgets('scrolls to the result after a valid calculation', (
      tester,
    ) async {
      await _pump(tester, const MatrixHomePage());
      final scrollView = find.byKey(const Key('matrix-scroll-view'));
      final button = find.byKey(const ValueKey('matrix-calculate'));
      // The page hosts several horizontal scrollers, so the outer list has to
      // be named rather than inferred.
      await tester.scrollUntilVisible(
        button,
        200,
        scrollable: find
            .descendant(of: scrollView, matching: find.byType(Scrollable))
            .first,
      );
      await tester.pumpAndSettle();
      final before = _positionOffset(tester, scrollView);

      await tester.tap(button);
      await tester.pumpAndSettle();

      // Also proves the result panel is inside the lazy list's build window:
      // an unbuilt target has no context, and the helper would do nothing.
      expect(_positionOffset(tester, scrollView), greaterThan(before));
    });
  });

  group('every tool with a result panel still renders after the change', () {
    // The five pages that gained a GlobalKey. A duplicate-key mistake throws
    // during build, so rendering is the assertion.
    const pages = <String, Widget>{
      'Matrix': MatrixHomePage(),
      'Statistics': StatisticsPage(),
      'Calculus': CalculusPage(),
      'Equation Solver': EquationSolverPage(),
      'Financial Calculator': FinancialCalculatorPage(),
    };
    pages.forEach((name, page) {
      testWidgets(name, (tester) async {
        await _pump(tester, page);
        expect(tester.takeException(), isNull, reason: '$name threw');
      });
    });
  });
}

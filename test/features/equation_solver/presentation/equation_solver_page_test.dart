import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/features/equation_solver/presentation/equation_solver_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  ThemeData? theme,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: theme ?? AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const EquationSolverPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _setViewport(WidgetTester tester, Size size, {double scale = 1.0}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  testWidgets('page opens with the three solver modes', (tester) async {
    await _pump(tester);
    expect(find.text('Equation Solver'), findsWidgets);
    expect(find.text('Single Equation'), findsOneWidget);
    expect(find.text('Linear System'), findsOneWidget);
    expect(find.text('Numerical Methods'), findsOneWidget);
    expect(find.byKey(const Key('eq-single-input')), findsOneWidget);
  });

  testWidgets('mode switching swaps the workflow and clears results', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Linear System'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('eq-cell-0-0')), findsOneWidget);
    await tester.tap(find.text('Numerical Methods'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('eq-method-function')), findsOneWidget);
    expect(find.text('Bisection'), findsOneWidget);
  });

  testWidgets('solving 2x + 5 = 17 shows the exact root with metadata', (
    tester,
  ) async {
    await _pump(tester);
    await tester.enterText(find.byKey(const Key('eq-single-input')), '2x+5=17');
    await tester.tap(find.byKey(const Key('eq-single-solve')));
    await tester.pumpAndSettle();
    final resultCard = find.byKey(const Key('eq-result-card'));
    await tester.ensureVisible(resultCard);
    await tester.pumpAndSettle();
    expect(find.text('x = 6'), findsOneWidget);
    expect(find.text('Exact'), findsOneWidget);
    expect(find.textContaining('Analytic (linear)'), findsOneWidget);
  });

  testWidgets('an invalid equation shows a friendly localized error', (
    tester,
  ) async {
    await _pump(tester);
    await tester.enterText(
      find.byKey(const Key('eq-single-input')),
      '2y + 1 = 3',
    );
    await tester.tap(find.byKey(const Key('eq-single-solve')));
    await tester.pumpAndSettle();
    expect(find.text('Only the variable x is supported.'), findsOneWidget);
  });

  testWidgets('linear system tab solves a 2x2 system', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Linear System'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('eq-cell-0-0')), '2');
    await tester.enterText(find.byKey(const Key('eq-cell-0-1')), '3');
    await tester.enterText(find.byKey(const Key('eq-rhs-0')), '7');
    await tester.enterText(find.byKey(const Key('eq-cell-1-0')), '1');
    await tester.enterText(find.byKey(const Key('eq-cell-1-1')), '-1');
    await tester.enterText(find.byKey(const Key('eq-rhs-1')), '1');
    final solve = find.byKey(const Key('eq-system-solve'));
    await tester.ensureVisible(solve);
    await tester.pumpAndSettle();
    await tester.tap(solve);
    await tester.pumpAndSettle();
    final resultCard = find.byKey(const Key('eq-result-card'));
    await tester.ensureVisible(resultCard);
    await tester.pumpAndSettle();
    expect(find.text('Unique solution'), findsOneWidget);
    expect(find.text('x1 = 2'), findsOneWidget);
    expect(find.text('x2 = 1'), findsOneWidget);
  });

  testWidgets('numerical methods show method-specific fields only', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Numerical Methods'));
    await tester.pumpAndSettle();
    // Bisection: two bounds.
    expect(find.text('Lower bound'), findsOneWidget);
    expect(find.text('Upper bound'), findsOneWidget);
    // Newton: only the initial guess.
    await tester.tap(find.text('Newton-Raphson'));
    await tester.pumpAndSettle();
    expect(find.text('Initial guess'), findsOneWidget);
    expect(find.byKey(const Key('eq-method-second')), findsNothing);
    // Secant: two guesses.
    await tester.tap(find.text('Secant'));
    await tester.pumpAndSettle();
    expect(find.text('First guess'), findsOneWidget);
    expect(find.text('Second guess'), findsOneWidget);
  });

  testWidgets('bisection run converges and reports iterations', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Numerical Methods'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('eq-method-function')),
      'x^2 - 2',
    );
    await tester.enterText(find.byKey(const Key('eq-method-first')), '0');
    await tester.enterText(find.byKey(const Key('eq-method-second')), '2');
    final run = find.byKey(const Key('eq-method-run'));
    await tester.ensureVisible(run);
    await tester.pumpAndSettle();
    await tester.tap(run);
    await tester.pumpAndSettle();
    final resultCard = find.byKey(const Key('eq-result-card'));
    await tester.ensureVisible(resultCard);
    await tester.pumpAndSettle();
    expect(find.text('Converged to a root'), findsOneWidget);
    expect(find.textContaining('Iterations'), findsOneWidget);
  });

  testWidgets('renders at 320px without overflow in Turkish', (tester) async {
    _setViewport(tester, const Size(320, 690));
    await _pump(tester, locale: const Locale('tr'));
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 5; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('renders at 200% text scale without overflow', (tester) async {
    _setViewport(tester, const Size(360, 690), scale: 2.0);
    await _pump(tester);
    expect(tester.takeException(), isNull);
    // At 200% scale the mode selector may start below the fold of the
    // lazily built ListView; scroll until it exists before tapping.
    final systemMode = find.text('Linear System');
    for (var i = 0; i < 6 && systemMode.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(systemMode);
    await tester.pumpAndSettle();
    await tester.tap(systemMode);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 5; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('builds in dark mode across all three tabs', (tester) async {
    await _pump(tester, theme: AppTheme.dark());
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Linear System'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Numerical Methods'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('growing the system adds rows and keeps entered values', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Linear System'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('eq-cell-0-0')), '42');
    await tester.tap(find.byKey(const Key('eq-system-grow')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('eq-cell-2-2')), findsOneWidget);
    final firstCell = tester.widget<TextField>(
      find.byKey(const Key('eq-cell-0-0')),
    );
    expect(firstCell.controller!.text, '42');
  });
}

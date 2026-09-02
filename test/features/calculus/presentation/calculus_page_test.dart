import 'dart:convert';

import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/calculus/presentation/calculus_page.dart';
import 'package:calcademy/features/saved_calculations/application/saved_calculations_service.dart';
import 'package:calcademy/features/saved_calculations/data/saved_calculations_repository.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_limits.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(
  WidgetTester tester, {
  ThemeData? theme,
  Locale locale = const Locale('en'),
  String? savedCalculationId,
  SharedPreferences? preferences,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (preferences != null)
          sharedPreferencesProvider.overrideWithValue(preferences),
      ],
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
        home: CalculusPage(savedCalculationId: savedCalculationId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<SharedPreferences> _seedSaved(
  SavedCalculationDraft draft, {
  required String id,
}) async {
  final item = SavedCalculationsService().create(
    draft,
    id: id,
    now: DateTime.utc(2026, 7, 24),
  );
  SharedPreferences.setMockInitialValues({
    SharedPreferencesSavedCalculationsRepository.storageKey: jsonEncode({
      'schemaVersion': SavedCalculationsLimits.schemaVersion,
      'items': [item.toJson()],
    }),
  });
  return SharedPreferences.getInstance();
}

void _setViewport(WidgetTester tester, Size size, {double scale = 1.0}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

const _invalidNumberMessage = 'Enter a valid number.';

String? _errorOf(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(Key(key))).decoration?.errorText;

Future<void> _findByScrolling(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 8 && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

void main() {
  test('the per-field number error has English and Turkish parity', () {
    const english = AppLocalizations(Locale('en'));
    const turkish = AppLocalizations(Locale('tr'));
    const key = 'eqErrorFieldNumber';

    expect(english.t(key), isNot(key), reason: 'English missing $key');
    expect(turkish.t(key), isNot(key), reason: 'Turkish missing $key');
  });

  testWidgets('page opens with the three calculus modes', (tester) async {
    await _pump(tester);
    expect(find.text('Calculus'), findsWidgets);
    expect(find.text('Differentiation'), findsOneWidget);
    expect(find.text('Integration'), findsOneWidget);
    expect(find.text('Function Analysis'), findsOneWidget);
    expect(find.byKey(const Key('calc-diff-function')), findsOneWidget);
  });

  testWidgets('mode switching swaps the workflow', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Integration'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calc-int-function')), findsOneWidget);
    expect(find.text('Trapezoidal'), findsOneWidget);
    await tester.tap(find.text('Function Analysis'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calc-analysis-function')), findsOneWidget);
  });

  testWidgets('differentiation solve shows result, method and tangent graph', (
    tester,
  ) async {
    await _pump(tester);
    await tester.enterText(find.byKey(const Key('calc-diff-function')), 'x^2');
    await tester.enterText(find.byKey(const Key('calc-diff-point')), '3');
    await tester.tap(find.byKey(const Key('calc-diff-solve')));
    await tester.pumpAndSettle();
    await _findByScrolling(tester, find.byKey(const Key('calc-result-card')));
    expect(find.textContaining("f'(3)"), findsOneWidget);
    expect(find.text('Approximate'), findsOneWidget);
    expect(find.textContaining('Central'), findsWidgets);
    // The tangent graph renders through the shared fl_chart pipeline
    // with the tangent overlay bar present.
    await _findByScrolling(tester, find.byKey(const Key('calc-diff-graph')));
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final dashedBars = chart.data.lineBarsData
        .where((bar) => bar.dashArray != null)
        .toList();
    expect(dashedBars, hasLength(1), reason: 'tangent line bar expected');
    expect(dashedBars.single.spots, hasLength(2));
  });

  testWidgets('the tangent is clipped to the plot area', (tester) async {
    await _pump(tester);
    await tester.enterText(
      find.byKey(const Key('calc-diff-function')),
      'sin(x)',
    );
    await tester.enterText(find.byKey(const Key('calc-diff-point')), '1');
    await tester.tap(find.byKey(const Key('calc-diff-solve')));
    await tester.pumpAndSettle();
    await _findByScrolling(tester, find.byKey(const Key('calc-diff-graph')));

    final data = tester.widget<LineChart>(find.byType(LineChart)).data;
    // The tangent spans the visible domain, so with a non-zero slope its
    // endpoints leave the y-range; without clipping it kept painting over
    // the result text above the graph.
    final tangent = data.lineBarsData.firstWhere(
      (bar) => bar.dashArray != null,
    );
    expect(
      tangent.spots.where((spot) => spot.y < data.minY || spot.y > data.maxY),
      isNotEmpty,
      reason: 'the sample the defect was found with must leave the y-range',
    );
    expect([
      data.clipData.left,
      data.clipData.top,
      data.clipData.right,
      data.clipData.bottom,
    ], everyElement(isTrue));
  });

  testWidgets('the shaded integral area is clipped to the plot area', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Integration'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('calc-int-function')),
      'sin(x)',
    );
    await tester.enterText(find.byKey(const Key('calc-int-lower')), '0');
    await tester.enterText(find.byKey(const Key('calc-int-upper')), '3');
    await tester.tap(find.byKey(const Key('calc-int-solve')));
    await tester.pumpAndSettle();
    await _findByScrolling(tester, find.byKey(const Key('calc-int-graph')));

    final data = tester.widget<LineChart>(find.byType(LineChart)).data;
    expect(
      data.lineBarsData.where((bar) => bar.belowBarData.show),
      hasLength(1),
    );
    expect([
      data.clipData.left,
      data.clipData.top,
      data.clipData.right,
      data.clipData.bottom,
    ], everyElement(isTrue));
  });

  testWidgets('integration solve shows result and shaded area graph', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Integration'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('calc-int-function')), 'x^2');
    await tester.enterText(find.byKey(const Key('calc-int-lower')), '0');
    await tester.enterText(find.byKey(const Key('calc-int-upper')), '2');
    await tester.tap(find.byKey(const Key('calc-int-solve')));
    await tester.pumpAndSettle();
    await _findByScrolling(tester, find.byKey(const Key('calc-result-card')));
    expect(find.textContaining('∫'), findsOneWidget);
    expect(find.textContaining('Simpson'), findsWidgets);
    await _findByScrolling(tester, find.byKey(const Key('calc-int-graph')));
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final shadedBars = chart.data.lineBarsData
        .where((bar) => bar.belowBarData.show)
        .toList();
    expect(shadedBars, hasLength(1), reason: 'shaded integral area expected');
  });

  testWidgets('Simpson odd subinterval count shows a validation message', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Integration'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('calc-int-function')), 'x');
    await tester.enterText(find.byKey(const Key('calc-int-n')), '5');
    await tester.tap(find.byKey(const Key('calc-int-solve')));
    await tester.pumpAndSettle();
    await _findByScrolling(tester, find.byKey(const Key('calc-result-card')));
    expect(
      find.text('Simpson 1/3 requires an even subinterval count.'),
      findsOneWidget,
    );
  });

  testWidgets('an unparseable bound flags the bound, not the function', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Integration'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('calc-int-function')),
      'sin(x)',
    );
    await tester.enterText(find.byKey(const Key('calc-int-upper')), 'pi');
    await tester.tap(find.byKey(const Key('calc-int-solve')));
    await tester.pumpAndSettle();

    expect(_errorOf(tester, 'calc-int-upper'), _invalidNumberMessage);
    expect(_errorOf(tester, 'calc-int-function'), isNull);
    expect(_errorOf(tester, 'calc-int-lower'), isNull);
    expect(_errorOf(tester, 'calc-int-n'), isNull);

    await tester.enterText(find.byKey(const Key('calc-int-upper')), '3');
    await tester.tap(find.byKey(const Key('calc-int-solve')));
    await tester.pumpAndSettle();

    expect(_errorOf(tester, 'calc-int-upper'), isNull);
  });

  testWidgets('an unparseable step size flags the step size field', (
    tester,
  ) async {
    await _pump(tester);
    await tester.enterText(
      find.byKey(const Key('calc-diff-function')),
      'sin(x)',
    );
    await tester.enterText(find.byKey(const Key('calc-diff-step')), 'tiny');
    await tester.tap(find.byKey(const Key('calc-diff-solve')));
    await tester.pumpAndSettle();

    expect(_errorOf(tester, 'calc-diff-step'), _invalidNumberMessage);
    expect(_errorOf(tester, 'calc-diff-function'), isNull);
    expect(_errorOf(tester, 'calc-diff-point'), isNull);
  });

  testWidgets('an unparseable analysis range flags the range field', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Function Analysis'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('calc-analysis-function')),
      'x^3 - 3x',
    );
    await tester.enterText(find.byKey(const Key('calc-analysis-max')), 'pi');
    await tester.tap(find.byKey(const Key('calc-analysis-solve')));
    await tester.pumpAndSettle();

    expect(_errorOf(tester, 'calc-analysis-max'), _invalidNumberMessage);
    expect(_errorOf(tester, 'calc-analysis-function'), isNull);
    expect(_errorOf(tester, 'calc-analysis-min'), isNull);
  });

  testWidgets('function analysis lists roots and extrema', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Function Analysis'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('calc-analysis-function')),
      'x^2 - 4',
    );
    await tester.enterText(find.byKey(const Key('calc-analysis-min')), '-5');
    await tester.enterText(find.byKey(const Key('calc-analysis-max')), '5');
    await tester.tap(find.byKey(const Key('calc-analysis-solve')));
    await tester.pumpAndSettle();
    await _findByScrolling(tester, find.byKey(const Key('calc-result-card')));
    expect(find.textContaining('Approximate roots'), findsOneWidget);
    expect(find.textContaining('-2'), findsWidgets);
    expect(find.textContaining('Local minimum'), findsOneWidget);
  });

  testWidgets('an invalid function shows a friendly localized error', (
    tester,
  ) async {
    await _pump(tester);
    await tester.enterText(
      find.byKey(const Key('calc-diff-function')),
      '2y + 1',
    );
    await tester.tap(find.byKey(const Key('calc-diff-solve')));
    await tester.pumpAndSettle();
    await _findByScrolling(tester, find.byKey(const Key('calc-result-card')));
    expect(find.text('Only the variable x is supported.'), findsOneWidget);
  });

  testWidgets('renders at 320px without overflow in Turkish', (tester) async {
    _setViewport(tester, const Size(320, 690));
    await _pump(tester, locale: const Locale('tr'));
    await tester.enterText(find.byKey(const Key('calc-diff-function')), 'x^3');
    await tester.ensureVisible(find.byKey(const Key('calc-diff-solve')));
    await tester.tap(find.byKey(const Key('calc-diff-solve')));
    await tester.pumpAndSettle();
    await _findByScrolling(tester, find.byKey(const Key('calc-diff-graph')));
    expect(tester.takeException(), isNull);
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final yTitles = chart.data.titlesData.leftTitles.sideTitles;
    final xTitles = chart.data.titlesData.bottomTitles.sideTitles;
    expect(yTitles.interval, isNotNull);
    expect(yTitles.reservedSize, greaterThanOrEqualTo(46));
    expect(yTitles.minIncluded, isFalse);
    expect(yTitles.maxIncluded, isFalse);
    expect(xTitles.reservedSize, greaterThanOrEqualTo(30));
    expect(
      (chart.data.maxY - chart.data.minY) / yTitles.interval!,
      lessThan(7),
    );
    final scroll = tester.widget<ListView>(
      find.byKey(const Key('calculus-scroll-view')),
    );
    expect((scroll.padding! as EdgeInsets).bottom, greaterThan(16));
    for (var i = 0; i < 5; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('renders at 200% text scale without overflow', (tester) async {
    _setViewport(tester, const Size(360, 690), scale: 2.0);
    await _pump(tester);
    await _findByScrolling(tester, find.byKey(const Key('calc-diff-function')));
    await tester.enterText(find.byKey(const Key('calc-diff-function')), 'x^2');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('calc-diff-solve')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calc-diff-solve')));
    await tester.pumpAndSettle();
    await _findByScrolling(tester, find.byKey(const Key('calc-diff-graph')));
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('builds in dark mode across all three tabs', (tester) async {
    await _pump(tester, theme: AppTheme.dark());
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Integration'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Function Analysis'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Differentiation'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('calc-diff-function')),
      'sin(x)',
    );
    await tester.tap(find.byKey(const Key('calc-diff-solve')));
    await tester.pumpAndSettle();
    await _findByScrolling(tester, find.byKey(const Key('calc-diff-graph')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening a saved differentiation seeds inputs and re-solves', (
    tester,
  ) async {
    final preferences = await _seedSaved(
      const SavedCalculationDraft(
        title: 'Diff',
        module: SavedCalculationModule.calculus,
        calculationType: 'differentiation',
        inputSummary: 'input',
        resultSummary: 'result',
        fullInputJson: {
          'function': 'x^2',
          'point': 3.0,
          'method': 'central',
          'stepSize': 0.001,
        },
        resultJson: {},
      ),
      id: 'calc-restore',
    );
    await _pump(
      tester,
      savedCalculationId: 'calc-restore',
      preferences: preferences,
    );

    final function = tester.widget<TextField>(
      find.byKey(const Key('calc-diff-function')),
    );
    expect(function.controller!.text, 'x^2');
    await _findByScrolling(tester, find.byKey(const Key('calc-result-card')));
    expect(find.textContaining("f'(3)"), findsOneWidget);
  });

  testWidgets('an unknown saved id opens a fresh page without crashing', (
    tester,
  ) async {
    await _pump(tester, savedCalculationId: 'missing');
    expect(tester.takeException(), isNull);
    final function = tester.widget<TextField>(
      find.byKey(const Key('calc-diff-function')),
    );
    expect(function.controller!.text, isEmpty);
  });
}

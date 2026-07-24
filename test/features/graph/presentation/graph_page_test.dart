import 'dart:convert';

import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/graph/data/graph_repository.dart';
import 'package:calcademy/features/graph/domain/graph_expression.dart';
import 'package:calcademy/features/graph/presentation/graph_controller.dart';
import 'package:calcademy/features/graph/presentation/graph_page.dart';
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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('new graph and saved-feedback localization keys have TR/EN parity', () {
    const english = AppLocalizations(Locale('en'));
    const turkish = AppLocalizations(Locale('tr'));
    const keys = [
      'graphXRangeOrder',
      'graphXRangeBounds',
      'graphXRangeHint',
      'savedCalculationSaved',
    ];
    for (final key in keys) {
      expect(english.t(key), isNot(key), reason: 'English missing $key');
      expect(turkish.t(key), isNot(key), reason: 'Turkish missing $key');
    }
  });

  testWidgets('graph page adds, plots, rejects, and removes functions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpGraph(tester);

    expect(find.text('Graphing'), findsOneWidget);
    expect(find.text('No graph to display'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addGraphFunction')));
    await tester.pump();
    final expressionField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Function expression',
    );
    expect(expressionField, findsOneWidget);

    await tester.enterText(expressionField, 'x^2');
    await tester.pump(GraphController.debounceDuration);
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GraphPage)),
    );
    expect(container.read(graphProvider).series, isNotEmpty);
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.byKey(const Key('graph-save-calculation')), findsOneWidget);

    await tester.enterText(expressionField, 'mystery(x)');
    await tester.pump(GraphController.debounceDuration);
    await tester.pumpAndSettle();
    expect(find.text('This function name is not recognized.'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete function'));
    await tester.pump();
    expect(container.read(graphProvider).functions, isEmpty);
    expect(find.text('No graph to display'), findsOneWidget);
  });

  testWidgets('saved calculation route restores the archived graph config', (
    tester,
  ) async {
    final item = SavedCalculation(
      id: 'graph-archive',
      title: 'Archived parabola',
      module: SavedCalculationModule.graphPlotter,
      calculationType: 'graphConfiguration',
      createdAt: DateTime.utc(2026, 7, 24),
      updatedAt: DateTime.utc(2026, 7, 24),
      isFavorite: false,
      inputSummary: 'x^2',
      resultSummary: 'one function',
      fullInputJson: const {
        'expressions': ['x^2'],
        'xRange': {'min': -4.0, 'max': 6.0},
        'autoY': false,
        'yRange': {'min': -2.0, 'max': 20.0},
        'angleMode': 'degrees',
      },
      resultJson: const {'kind': 'configuration'},
      tags: const [],
    );
    SharedPreferences.setMockInitialValues({
      SharedPreferencesSavedCalculationsRepository.storageKey: jsonEncode({
        'schemaVersion': SavedCalculationsLimits.schemaVersion,
        'items': [item.toJson()],
      }),
    });

    await _pumpGraph(tester, savedCalculationId: item.id);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GraphPage)),
    );
    final state = container.read(graphProvider);
    expect(state.functions.single.expression, 'x^2');
    expect(state.range.min, -4);
    expect(state.range.max, 6);
    expect(state.autoY, isFalse);
    expect(state.manualYMin, -2);
    expect(state.manualYMax, 20);
    expect(state.angleMode, GraphAngleMode.degrees);
    expect(state.activeGraphId, isNull);
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('graph controls remain overflow-free with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpGraph(tester);

    await tester.tap(find.byKey(const Key('addGraphFunction')));
    await tester.pump();
    final expressionField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Function expression',
    );
    await tester.enterText(expressionField, 'x^2');
    await tester.pump(GraphController.debounceDuration);
    await tester.pumpAndSettle();
    expect(find.byType(LineChart), findsOneWidget);
    final legend = find.byKey(const Key('graph-legend-scroll'));
    expect(legend, findsOneWidget);
    expect(tester.getSize(legend).width, lessThan(200));
    final transformation = tester
        .widget<LineChart>(find.byType(LineChart))
        .transformationConfig
        .transformationController!;
    expect(transformation.value.getMaxScaleOnAxis(), 1);
    await tester.tap(find.byKey(const Key('graph-zoom-in')));
    await tester.pump();
    expect(transformation.value.getMaxScaleOnAxis(), closeTo(1.25, 0.001));
    await tester.tap(find.byKey(const Key('graph-zoom-out')));
    await tester.pump();
    expect(transformation.value.getMaxScaleOnAxis(), closeTo(1, 0.001));
    expect(find.text('Graphing'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.fling(find.byType(ListView), const Offset(0, -1500), 1000);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('graph-x-range-hint')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('X range feedback is specific and reset restores defaults', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpGraph(tester);
    final minField = find.byKey(const Key('graphXMin'));
    final maxField = find.byKey(const Key('graphXMax'));
    final apply = find.byKey(const Key('applyGraphRange'));
    await tester.ensureVisible(apply);
    await tester.pumpAndSettle();

    await tester.enterText(minField, '-10000');
    await tester.enterText(maxField, '10000');
    await tester.tap(apply);
    await tester.pump();
    expect(
      find.text('X range must stay between -1000 and 1000.'),
      findsOneWidget,
    );

    await tester.enterText(minField, '10');
    await tester.enterText(maxField, '-10');
    await tester.tap(apply);
    await tester.pump();
    expect(find.text('X minimum must be less than X maximum.'), findsOneWidget);

    await tester.enterText(minField, '-1000');
    await tester.enterText(maxField, '1000');
    await tester.tap(apply);
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GraphPage)),
    );
    expect(container.read(graphProvider).range.min, -1000);
    expect(container.read(graphProvider).range.max, 1000);
    expect(find.byKey(const Key('graph-range-error')), findsNothing);

    await tester.enterText(minField, '-10000');
    await tester.enterText(maxField, '10000');
    await tester.tap(apply);
    await tester.pump();
    await tester.tap(find.byKey(const Key('graph-reset-range')));
    await tester.pump();
    expect(tester.widget<TextField>(minField).controller!.text, '-10');
    expect(tester.widget<TextField>(maxField).controller!.text, '10');
  });

  test('controller validates, resets, and persists graph workspaces', () async {
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    final controller = container.read(graphProvider.notifier);

    controller.addFunction();
    final id = container.read(graphProvider).functions.single.id;
    controller.updateExpression(id, 'sin(x)');
    expect(controller.applyRange(xMin: '-100', xMax: '100'), isTrue);
    expect(controller.applyRange(xMin: '-1000', xMax: '1000'), isTrue);
    expect(controller.applyRange(xMin: '-10000', xMax: '10000'), isFalse);
    expect(container.read(graphProvider).rangeError, 'graphXRangeBounds');
    expect(controller.applyRange(xMin: '10', xMax: '-10'), isFalse);
    expect(container.read(graphProvider).rangeError, 'graphXRangeOrder');
    expect(controller.applyRange(xMin: '0', xMax: '0'), isFalse);
    expect(container.read(graphProvider).rangeError, 'graphXRangeOrder');
    expect(controller.applyRange(xMin: 'abc', xMax: '10'), isFalse);
    expect(container.read(graphProvider).rangeError, 'graphInvalidRange');
    expect(controller.applyRange(xMin: '-20', xMax: '30'), isTrue);
    expect(container.read(graphProvider).range.min, -20);
    expect(container.read(graphProvider).range.max, 30);

    controller.resetView();
    expect(container.read(graphProvider).range.min, -10);
    expect(container.read(graphProvider).range.max, 10);
    expect(await controller.saveCurrent('Trigonometry'), isTrue);
    expect(container.read(savedGraphsProvider).single.title, 'Trigonometry');
    expect(preferences.getString('graph.saved'), isNotNull);

    final restoredContainer = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(restoredContainer.dispose);
    expect(
      restoredContainer.read(savedGraphsProvider).single.title,
      'Trigonometry',
    );

    final savedId = restoredContainer.read(savedGraphsProvider).single.id;
    restoredContainer.read(graphProvider.notifier).loadSaved(savedId);
    expect(restoredContainer.read(graphProvider).activeGraphId, savedId);
    expect(
      restoredContainer.read(graphProvider).functions.single.expression,
      'sin(x)',
    );

    restoredContainer
        .read(graphProvider.notifier)
        .updateExpression(
          restoredContainer.read(graphProvider).functions.single.id,
          'cos(x)',
        );
    expect(
      await restoredContainer.read(graphProvider.notifier).saveChanges(),
      isTrue,
    );
    expect(restoredContainer.read(savedGraphsProvider), hasLength(1));
    expect(
      restoredContainer
          .read(savedGraphsProvider)
          .single
          .functions
          .single
          .expression,
      'cos(x)',
    );
  });

  test('controller discards an older queued sampling request', () async {
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    final controller = container.read(graphProvider.notifier);
    controller.addFunction();
    final id = container.read(graphProvider).functions.single.id;

    controller.updateExpression(id, 'x^2');
    await Future<void>.delayed(GraphController.debounceDuration);
    controller.updateExpression(id, 'cos(x)');
    await Future<void>.delayed(
      GraphController.debounceDuration + const Duration(milliseconds: 30),
    );

    final state = container.read(graphProvider);
    final points = state.series[id]!.segments.expand((item) => item.points);
    final nearestZero = points.reduce(
      (left, right) => left.x.abs() < right.x.abs() ? left : right,
    );
    expect(nearestZero.y, closeTo(1, 0.01));
    expect(state.isSampling, isFalse);
  });

  test(
    'controller samples the five-function stress set within hard limits',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);
      final controller = container.read(graphProvider.notifier);
      const expressions = ['sin(x)', 'cos(x)', 'tan(x)', 'x^2', '1/x'];

      for (final expression in expressions) {
        expect(controller.addFunction(), isTrue);
        final id = container.read(graphProvider).functions.last.id;
        controller.updateExpression(id, expression);
      }
      await Future<void>.delayed(
        GraphController.debounceDuration + const Duration(milliseconds: 50),
      );

      final state = container.read(graphProvider);
      expect(state.series, hasLength(5));
      expect(state.functionErrors, isEmpty);
      expect(
        state.series.values
            .map((item) => item.stats.generatedPointCount)
            .reduce((left, right) => left + right),
        lessThanOrEqualTo(5 * 3200),
      );
      expect(state.isSampling, isFalse);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'graph page builds in ${mode.name} theme with export boundary',
      (tester) async {
        await _pumpGraph(tester, themeMode: mode);
        await tester.tap(find.byKey(const Key('addGraphFunction')));
        await tester.pump();
        final expressionField = find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Function expression',
        );
        await tester.enterText(expressionField, 'x^2');
        await tester.pump(GraphController.debounceDuration);
        await tester.pumpAndSettle();

        expect(find.byType(RepaintBoundary), findsWidgets);
        expect(find.textContaining('f₁:'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _pumpGraph(
  WidgetTester tester, {
  ThemeMode themeMode = ThemeMode.light,
  String? savedCalculationId,
}) async {
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: GraphPage(savedCalculationId: savedCalculationId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

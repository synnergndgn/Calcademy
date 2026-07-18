import 'dart:convert';

import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/graph/data/graph_repository.dart';
import 'package:calcademy/features/graph/domain/graph_expression.dart';
import 'package:calcademy/features/graph/domain/graph_function.dart';
import 'package:calcademy/features/graph/domain/graph_range.dart';
import 'package:calcademy/features/graph/domain/saved_graph.dart';
import 'package:calcademy/features/graph/presentation/graph_controller.dart';
import 'package:calcademy/features/graph/presentation/graph_page.dart';
import 'package:calcademy/features/history/domain/saved_calculation.dart';
import 'package:calcademy/features/saved/presentation/saved_controller.dart';
import 'package:calcademy/features/saved/presentation/saved_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('saved page lists calculations and graphs without mixing them', (
    tester,
  ) async {
    final graph = _graph('graph-1', 'Parabola');
    final calculation = _calculation();
    await _pumpSaved(tester, graphs: [graph], calculations: [calculation]);

    expect(find.text('Calculations'), findsOneWidget);
    expect(find.text('Graphs'), findsOneWidget);
    expect(find.text('Useful result'), findsOneWidget);

    await tester.tap(find.text('Graphs'));
    await tester.pumpAndSettle();
    expect(find.text('Parabola'), findsOneWidget);
    expect(find.textContaining('x^2'), findsOneWidget);
  });

  testWidgets('opening a saved graph restores its complete workspace', (
    tester,
  ) async {
    final graph = _graph('graph-open', 'Open me');
    final scope = await _pumpSaved(tester, graphs: [graph]);
    await tester.tap(find.text('Graphs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open me'));
    await tester.pumpAndSettle();

    final state = scope.read(graphProvider);
    expect(state.activeGraphId, graph.id);
    expect(state.functions.single.expression, 'x^2');
    expect(state.range.min, -4);
    expect(state.range.max, 6);
    expect(state.angleMode, GraphAngleMode.radians);
  });

  testWidgets('deleting a graph preserves saved calculations', (tester) async {
    final graph = _graph('graph-delete', 'Delete me');
    final calculation = _calculation();
    final scope = await _pumpSaved(
      tester,
      graphs: [graph],
      calculations: [calculation],
    );
    await tester.tap(find.text('Graphs'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(scope.read(savedGraphsProvider), isEmpty);
    expect(scope.read(savedProvider), hasLength(1));
    expect(find.text('Delete me'), findsNothing);
  });

  testWidgets('five graph records fit a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpSaved(
      tester,
      graphs: [
        for (var index = 0; index < 5; index++)
          _graph('$index', 'Graph $index'),
      ],
    );
    await tester.drag(find.byType(TabBar), const Offset(-100, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Graphs'));
    await tester.pumpAndSettle();

    expect(find.text('Graph 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<ProviderContainer> _pumpSaved(
  WidgetTester tester, {
  List<SavedGraph> graphs = const [],
  List<SavedCalculation> calculations = const [],
}) async {
  SharedPreferences.setMockInitialValues({
    'graph.saved': jsonEncode(graphs.map((item) => item.toJson()).toList()),
    'calculator.saved': jsonEncode(
      calculations.map((item) => item.toJson()).toList(),
    ),
  });
  final preferences = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: '/saved',
    routes: [
      GoRoute(path: '/saved', builder: (_, _) => const SavedPage()),
      GoRoute(
        path: '/graph',
        builder: (_, state) =>
            GraphPage(savedGraphId: state.uri.queryParameters['graphId']),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(SavedPage)));
}

SavedGraph _graph(String id, String title) => SavedGraph(
  id: id,
  title: title,
  functions: const [
    GraphFunction(id: 'function-1', expression: 'x^2', visualIndex: 0),
  ],
  range: const GraphRange(min: -4, max: 6),
  autoY: true,
  angleMode: GraphAngleMode.radians,
  createdAt: DateTime(2026, 7, 17, 20, 35),
);

SavedCalculation _calculation() => SavedCalculation(
  id: 'calculation-1',
  title: 'Useful result',
  expression: '2+2',
  result: '4',
  createdAt: DateTime(2026, 7, 17),
);

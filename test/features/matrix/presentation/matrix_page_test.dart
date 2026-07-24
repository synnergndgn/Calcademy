import 'dart:convert';

import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/matrix/domain/matrix_operation.dart';
import 'package:calcademy/features/matrix/domain/matrix_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_value.dart';
import 'package:calcademy/features/matrix/domain/saved_matrix_operation.dart';
import 'package:calcademy/features/matrix/presentation/matrix_controller.dart';
import 'package:calcademy/features/matrix/presentation/matrix_home_page.dart';
import 'package:calcademy/features/matrix/presentation/matrix_steps_page.dart';
import 'package:calcademy/features/matrix/presentation/matrix_widgets.dart';
import 'package:calcademy/features/saved/presentation/saved_page.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/matrix_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/application/saved_calculations_service.dart';
import 'package:calcademy/features/saved_calculations/data/saved_calculations_repository.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_limits.dart';
import 'package:calcademy/features/saved_calculations/presentation/saved_calculations_controller.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('matrix home opens with operation and ready examples', (
    tester,
  ) async {
    await _pumpMatrix(tester);

    expect(find.text('Matrices & Linear Algebra'), findsWidgets);
    expect(find.byKey(const ValueKey('matrix-operation-selector')), findsOne);
    expect(find.text('Ready examples'), findsOne);
    expect(find.byType(EditableMatrixGrid), findsNWidgets(2));
  });

  testWidgets('operation selection only shows required matrix inputs', (
    tester,
  ) async {
    await _pumpMatrix(tester);
    await _selectOperation(tester, MatrixOperationType.determinant);

    expect(find.byType(EditableMatrixGrid), findsOneWidget);
    expect(find.text('Matrix B'), findsNothing);
  });

  testWidgets('matrix dimensions can be increased without overflow', (
    tester,
  ) async {
    await _pumpMatrix(tester);
    final firstEditor = find.byType(EditableMatrixGrid).first;
    final addButtons = find.descendant(
      of: firstEditor,
      matching: find.byTooltip('Add row or column'),
    );
    await tester.tap(addButtons.first);
    await tester.pump();

    expect(find.byKey(const ValueKey('Matrix A-2-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cell input stays local until calculate is pressed', (
    tester,
  ) async {
    final container = await _pumpMatrix(tester);
    await tester.enterText(find.byKey(const ValueKey('Matrix A-0-0')), '1/2');
    await tester.pump();

    expect(container.read(matrixWorkspaceProvider).execution, isNull);
    await _scrollToCalculate(tester);
    await tester.tap(find.byKey(const ValueKey('matrix-calculate')));
    await tester.pumpAndSettle();
    expect(container.read(matrixWorkspaceProvider).execution, isNotNull);
  });

  testWidgets('matrix multiplication shows result and cell explanation', (
    tester,
  ) async {
    final container = await _pumpMatrix(tester);
    await _scrollToCalculate(tester);
    await tester.tap(find.byKey(const ValueKey('matrix-calculate')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('matrix-result-panel')), findsOneWidget);
    expect(find.byKey(const Key('matrix-save-calculation')), findsOneWidget);
    expect(find.byKey(const Key('matrix-copy-result')), findsOneWidget);
    expect(find.text('Save calculation'), findsOneWidget);
    expect(find.text('Save operation'), findsNothing);
    await tester.tap(find.byKey(const Key('matrix-save-calculation')));
    await tester.pumpAndSettle();
    expect(container.read(savedCalculationsProvider).items, hasLength(1));
    expect(
      container.read(savedCalculationsProvider).items.single.module,
      SavedCalculationModule.matrix,
    );
    expect(find.text('Saved to Saved.'), findsOneWidget);
    MethodCall? clipboardCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') clipboardCall = call;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    tester
        .widget<TextButton>(find.byKey(const Key('matrix-copy-result')))
        .onPressed!();
    await tester.pump();
    expect(clipboardCall?.method, 'Clipboard.setData');
    expect(
      (clipboardCall?.arguments as Map<Object?, Object?>)['text'],
      isNotEmpty,
    );
    expect(
      find.text('Tap a result cell to inspect its row-by-column calculation.'),
      findsOneWidget,
    );
    final resultViews = find.descendant(
      of: find.byKey(const ValueKey('matrix-result-panel')),
      matching: find.byType(MatrixView),
    );
    await tester.tap(
      find
          .descendant(of: resultViews.first, matching: find.byType(InkWell))
          .first,
    );
    await tester.pump();
    expect(find.textContaining('C11 ='), findsWidgets);

    await tester.drag(find.byType(ListView).first, const Offset(0, 1800));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, 1800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inverse matrix').first);
    await tester.pumpAndSettle();
    await _scrollToCalculate(tester);
    await tester.tap(find.byKey(const ValueKey('matrix-calculate')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    final inverseResultView = tester.widget<MatrixView>(
      find
          .descendant(
            of: find.byKey(const ValueKey('matrix-result-panel')),
            matching: find.byType(MatrixView),
          )
          .first,
    );
    expect(inverseResultView.selectedCell, isNull);
  });

  testWidgets('incompatible dimensions show a friendly error', (tester) async {
    await _pumpMatrix(tester);
    final secondEditor = find.byType(EditableMatrixGrid).at(1);
    await tester.drag(find.byType(ListView).first, const Offset(0, -450));
    await tester.pumpAndSettle();
    final addRow = find
        .descendant(
          of: secondEditor,
          matching: find.byTooltip('Add row or column'),
        )
        .first;
    await tester.tap(addRow);
    await tester.pump();
    await _scrollToCalculate(tester);
    await tester.tap(find.byKey(const ValueKey('matrix-calculate')));
    await tester.pumpAndSettle();

    expect(
      find.text('The matrix dimensions are incompatible for this operation.'),
      findsOneWidget,
    );
  });

  testWidgets('step-by-step screen opens and navigates', (tester) async {
    await _pumpMatrix(tester);
    await tester.tap(find.text('Inverse matrix').first);
    await tester.pump();
    await _scrollToCalculate(tester);
    await tester.tap(find.byKey(const ValueKey('matrix-calculate')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Show steps'));
    await tester.tap(find.text('Show steps'));
    await tester.pumpAndSettle();

    expect(find.byType(MatrixStepsPage), findsOneWidget);
    expect(find.text('Initial matrix'), findsOneWidget);
    await tester.tap(find.byTooltip('Next step'));
    await tester.pump();
    expect(find.textContaining('Step 1'), findsOneWidget);
  });

  testWidgets('saved matrix appears in the main Saved page', (tester) async {
    final saved = _saved();
    SharedPreferences.setMockInitialValues({
      'matrix.saved': jsonEncode([saved.toJson()]),
    });
    await _pumpSaved(tester);
    await tester.tap(find.text('Matrices'));
    await tester.pumpAndSettle();

    expect(find.text('Important matrix'), findsOneWidget);
    expect(find.textContaining('2\u00d72'), findsOneWidget);
  });

  testWidgets('opening a saved matrix restores operation inputs and result', (
    tester,
  ) async {
    final saved = _saved();
    SharedPreferences.setMockInitialValues({
      'matrix.saved': jsonEncode([saved.toJson()]),
    });
    final container = await _pumpMatrix(tester, savedMatrixId: saved.id);

    final state = container.read(matrixWorkspaceProvider);
    expect(state.operation, MatrixOperationType.determinant);
    expect(state.activeSavedId, saved.id);
    expect(state.execution?.inputs.single, saved.inputs.single);
    expect(state.execution?.result, isA<ScalarMatrixResult>());
  });

  testWidgets('saved calculation payload restores a new matrix archive', (
    tester,
  ) async {
    final input = MatrixValue(const [
      [2, 1],
      [5, 3],
    ]);
    final draft = MatrixSavedAdapter.fromExecution(
      MatrixExecution(
        operation: MatrixOperationType.determinant,
        inputs: [input],
        result: const ScalarMatrixResult(1),
      ),
    );
    final item = SavedCalculationsService().create(
      draft,
      id: 'matrix-archive',
      now: DateTime.utc(2026, 7, 24),
    );
    SharedPreferences.setMockInitialValues({
      SharedPreferencesSavedCalculationsRepository.storageKey: jsonEncode({
        'schemaVersion': SavedCalculationsLimits.schemaVersion,
        'items': [item.toJson()],
      }),
    });

    final container = await _pumpMatrix(tester, savedCalculationId: item.id);

    final state = container.read(matrixWorkspaceProvider);
    expect(state.operation, MatrixOperationType.determinant);
    expect(state.activeSavedId, isNull);
    expect(state.execution?.inputs.single, input);
    expect(
      (state.execution?.result as ScalarMatrixResult).value,
      closeTo(1, 1e-10),
    );
    await tester.fling(
      find.byType(ListView).first,
      const Offset(0, -1800),
      1200,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('matrix-result-panel')), findsOneWidget);
  });

  testWidgets('result actions stay compact at 320px and 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpMatrix(tester);

    expect(find.text('Matrices'), findsOneWidget);
    expect(find.byType(Scrollable), findsWidgets);
    await _scrollToCalculate(tester);
    await tester.tap(find.byKey(const ValueKey('matrix-calculate')));
    await tester.pumpAndSettle();
    final resultPanel = find.byKey(const ValueKey('matrix-result-panel'));
    await tester.ensureVisible(resultPanel);
    await tester.pumpAndSettle();
    expect(tester.getSize(resultPanel).width, lessThanOrEqualTo(288));
    expect(find.byKey(const Key('matrix-save-calculation')), findsOneWidget);
    expect(find.byKey(const Key('matrix-copy-result')), findsOneWidget);
    expect(find.text('Save operation'), findsNothing);
    expect(find.byKey(const Key('matrix-new-operation')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('matrix page builds in dark theme', (tester) async {
    await _pumpMatrix(tester, dark: true);
    expect(find.byType(MatrixHomePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('100-cell editor keeps cell state locally', (tester) async {
    final handle = MatrixEditorHandle();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: EditableMatrixGrid(
            label: 'Matrix A',
            handle: handle,
            initialValue: MatrixValue.zero(10, 10),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(100));
    await tester.enterText(find.byKey(const ValueKey('Matrix A-9-9')), '-7/4');
    expect(handle.read().at(9, 9), -1.75);
    expect(tester.takeException(), isNull);
  });
}

Future<ProviderContainer> _pumpMatrix(
  WidgetTester tester, {
  bool dark = false,
  String? savedMatrixId,
  String? savedCalculationId,
}) async {
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MatrixHomePage(
          savedMatrixId: savedMatrixId,
          savedCalculationId: savedCalculationId,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MatrixHomePage)));
}

Future<void> _pumpSaved(WidgetTester tester) async {
  final preferences = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: '/saved',
    routes: [
      GoRoute(path: '/saved', builder: (_, _) => const SavedPage()),
      GoRoute(
        path: '/matrix',
        builder: (_, state) => MatrixHomePage(
          savedMatrixId: state.uri.queryParameters['savedId'],
          savedCalculationId: state.uri.queryParameters['savedCalculationId'],
        ),
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
}

Future<void> _selectOperation(
  WidgetTester tester,
  MatrixOperationType operation,
) async {
  await tester.tap(find.byType(DropdownButtonFormField<MatrixOperationType>));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining(operation.notation).last);
  await tester.pumpAndSettle();
}

Future<void> _scrollToCalculate(WidgetTester tester) async {
  for (var attempt = 0; attempt < 4; attempt++) {
    if (find.byKey(const ValueKey('matrix-calculate')).evaluate().isNotEmpty) {
      await tester.ensureVisible(
        find.byKey(const ValueKey('matrix-calculate')),
      );
      await tester.pumpAndSettle();
      return;
    }
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
  }
}

SavedMatrixOperation _saved() => SavedMatrixOperation(
  id: 'saved-matrix-1',
  title: 'Important matrix',
  type: MatrixOperationType.determinant,
  inputs: [
    MatrixValue(const [
      [1, 2],
      [3, 4],
    ]),
  ],
  result: const ScalarMatrixResult(-2),
  createdAt: DateTime(2026, 7, 17),
);

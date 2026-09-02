import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/matrix/domain/matrix_examples.dart';
import 'package:calcademy/features/matrix/domain/matrix_number_formatter.dart';
import 'package:calcademy/features/matrix/domain/matrix_value.dart';
import 'package:calcademy/features/matrix/presentation/matrix_home_page.dart';
import 'package:calcademy/features/matrix/presentation/matrix_widgets.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('every ready example fills every cell, zeros included', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final example in matrixExamples) {
      for (var index = 0; index < example.inputs.length; index++) {
        final input = example.inputs[index];
        final label = 'Matrix ${index == 0 ? 'A' : 'B'}';
        await _pumpGrid(
          tester,
          label: label,
          value: input,
          // A fresh editor per example: the grid seeds its controllers once,
          // the way the page does by rekeying the inputs.
          seed: '${example.titleKey}-$index',
        );

        for (var row = 0; row < input.rows; row++) {
          for (var column = 0; column < input.columns; column++) {
            final field = tester.widget<TextField>(
              find.byKey(ValueKey('$label-$row-$column')),
            );
            expect(
              field.controller?.text,
              formatMatrixNumber(input.at(row, column)),
              reason:
                  '${example.titleKey} $label ($row, $column) should be '
                  'seeded with its example value',
            );
          }
        }
      }
    }
  });

  testWidgets('a zero cell is written out rather than left blank', (
    tester,
  ) async {
    await _pumpGrid(tester, label: 'Matrix A', value: MatrixValue.zero(2, 2));

    for (var row = 0; row < 2; row++) {
      for (var column = 0; column < 2; column++) {
        final field = tester.widget<TextField>(
          find.byKey(ValueKey('Matrix A-$row-$column')),
        );
        expect(field.controller?.text, '0');
      }
    }
  });

  testWidgets('the multiplication example opens with B(1,2) showing 0', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpMatrixPage(tester);

    expect(_cellText(tester, 'Matrix B', 0, 1), '0');
  });

  testWidgets('re-tapping the active example chip refills an emptied cell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpMatrixPage(tester);

    await tester.enterText(find.byKey(const ValueKey('Matrix B-0-1')), '');
    await tester.pump();
    expect(_cellText(tester, 'Matrix B', 0, 1), '');

    await tester.tap(find.text('Matrix multiplication'));
    await tester.pumpAndSettle();

    expect(_cellText(tester, 'Matrix B', 0, 1), '0');
    expect(_cellText(tester, 'Matrix B', 0, 0), '2');
    expect(_cellText(tester, 'Matrix A', 1, 1), '4');
  });
}

String? _cellText(WidgetTester tester, String label, int row, int column) =>
    tester
        .widget<TextField>(find.byKey(ValueKey('$label-$row-$column')))
        .controller
        ?.text;

Future<void> _pumpGrid(
  WidgetTester tester, {
  required String label,
  required MatrixValue value,
  String seed = 'grid',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
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
          key: ValueKey(seed),
          label: label,
          handle: MatrixEditorHandle(),
          initialValue: value,
          maxColumns: value.columns,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpMatrixPage(WidgetTester tester) async {
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
        home: const MatrixHomePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

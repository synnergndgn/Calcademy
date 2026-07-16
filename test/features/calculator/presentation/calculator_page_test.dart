import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/calculator/presentation/calculator_page.dart';
import 'package:calcademy/features/history/presentation/history_page.dart';
import 'package:calcademy/features/settings/presentation/settings_controller.dart';
import 'package:calcademy/features/settings/presentation/settings_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('calculator opens, accepts keys, evaluates, and clears', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, const CalculatorPage());
    expect(find.text('Scientific Calculator'), findsOneWidget);

    await _tapKey(tester, '1');
    await _tapKey(tester, '+');
    await _tapKey(tester, '2');
    await _tapKey(tester, '=');
    await tester.pumpAndSettle();
    final result = tester.widget<SelectableText>(
      find.byKey(const Key('resultText')),
    );
    expect(result.data, '3');

    await _tapKey(tester, 'AC');
    await tester.pump();
    final field = tester.widget<TextField>(
      find.byKey(const Key('expressionField')),
    );
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('history shows its empty state', (tester) async {
    await _pump(tester, const HistoryPage());
    expect(find.text('No calculations yet'), findsOneWidget);
  });

  testWidgets('theme selection updates the application theme mode', (
    tester,
  ) async {
    await _pump(tester, const SettingsPage());
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });
}

Future<void> _tapKey(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          themeMode: ref.watch(settingsProvider).themeMode,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: child,
        ),
      ),
    ),
  );
  await tester.pump();
}

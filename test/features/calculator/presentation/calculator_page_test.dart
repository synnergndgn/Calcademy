import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/calculator/presentation/calculator_page.dart';
import 'package:calcademy/features/calculator/presentation/calculator_keypad.dart';
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
    expect(
      find.byKey(const Key('calculator-save-calculation')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.bookmark_add_outlined), findsNothing);

    await _tapKey(tester, 'AC');
    await tester.pump();
    final field = tester.widget<TextField>(
      find.byKey(const Key('expressionField')),
    );
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('expression changes do not rebuild the calculator keypad', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, const CalculatorPage());

    final keypadBefore = tester.widget<CalculatorKeypad>(
      find.byType(CalculatorKeypad),
    );
    await _tapKey(tester, '1');
    await tester.pump();
    final keypadAfter = tester.widget<CalculatorKeypad>(
      find.byType(CalculatorKeypad),
    );

    expect(identical(keypadAfter, keypadBefore), isTrue);
  });

  testWidgets('saved expression route input is restored into the editor', (
    tester,
  ) async {
    await _pump(tester, const CalculatorPage(initialExpression: 'sin(30) + 2'));

    final field = tester.widget<TextField>(
      find.byKey(const Key('expressionField')),
    );
    expect(field.controller!.text, 'sin(30) + 2');
  });

  testWidgets('expression field keeps its caret without a system keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, const CalculatorPage());

    final expressionFinder = find.byKey(const Key('expressionField'));
    final field = tester.widget<TextField>(expressionFinder);
    expect(field.readOnly, isTrue);
    expect(field.showCursor, isTrue);

    await tester.tap(expressionFinder);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);

    await _tapKey(tester, '1');
    await _tapKey(tester, '+');
    await _tapKey(tester, '2');
    expect(field.controller!.text, '1+2');

    await _tapKey(tester, '⌫');
    expect(field.controller!.text, '1+');
  });

  testWidgets('calculator stays usable at 320px, 200% text, and dark mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pump(tester, const CalculatorPage(), dark: true);

    final fieldFinder = find.byKey(const Key('expressionField'));
    expect(tester.widget<TextField>(fieldFinder).readOnly, isTrue);
    expect(find.byType(CalculatorKeypad), findsOneWidget);
    expect(tester.getRect(fieldFinder).width, lessThanOrEqualTo(288));
    await _tapKey(tester, '7');
    expect(tester.widget<TextField>(fieldFinder).controller!.text, '7');
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone layout keeps the display and result on screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // A 360x800 phone with a status bar and a three-button navigation bar --
    // the tightest portrait viewport the keypad has to fit into.
    await _pump(
      tester,
      const MediaQuery(
        data: MediaQueryData(
          size: Size(360, 800),
          devicePixelRatio: 2,
          padding: EdgeInsets.only(top: 30, bottom: 48),
        ),
        child: CalculatorPage(),
      ),
    );
    await tester.pumpAndSettle();

    final safeBottom = 800.0 - 48;
    final field = tester.getRect(find.byKey(const Key('expressionField')));
    final result = tester.getRect(find.byKey(const Key('resultPanel')));
    final equals = tester.getRect(find.text('='));

    // The keypad fits the space left over instead of scrolling the display
    // and the result off the top of the screen.
    final keypad = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(CalculatorKeypad),
        matching: find.byType(Scrollable),
      ),
    );
    expect(keypad.position.maxScrollExtent, 0);
    expect(result.bottom, lessThanOrEqualTo(safeBottom));
    expect(equals.bottom, lessThanOrEqualTo(safeBottom));
    expect(field.top, greaterThan(0));
    expect(result.top, greaterThan(field.bottom));
    expect(tester.takeException(), isNull);

    // The keypad still works after being resized to fit.
    await tester.tap(find.text('7'));
    await tester.pump();
    final controller = tester
        .widget<TextField>(find.byKey(const Key('expressionField')))
        .controller!;
    expect(controller.text, '7');
  });

  testWidgets('short viewports fall back to scrolling the whole workspace', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(tester, const CalculatorPage());
    await tester.pumpAndSettle();

    expect(find.byType(CalculatorKeypad), findsOneWidget);
    await _tapKey(tester, '7');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('expressionField')))
          .controller!
          .text,
      '7',
    );
    expect(tester.takeException(), isNull);
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

  testWidgets('settings reflows theme previews at 320px and 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pump(tester, const SettingsPage());
    await tester.scrollUntilVisible(
      find.text('System'),
      180,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tapKey(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
}) async {
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: dark
              ? ThemeMode.dark
              : ref.watch(settingsProvider).themeMode,
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

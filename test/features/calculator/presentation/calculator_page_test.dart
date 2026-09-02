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

  // Every phone viewport the keypad has to fit into. The heights are the
  // logical ones, which shrink when the user raises Android's display size --
  // 1080x2400 is 360x800 at the default density but 328x729 one step up -- so
  // a single "tightest phone" is not a thing that exists.
  for (final viewport in const [
    (
      name: '360x800, three-button navigation',
      size: Size(360, 800),
      padding: EdgeInsets.only(top: 30, bottom: 48),
      textScale: 1.0,
    ),
    (
      name: '360x800, gesture navigation',
      size: Size(360, 800),
      padding: EdgeInsets.only(top: 30, bottom: 24),
      textScale: 1.0,
    ),
    (
      name: '328x729, larger display size',
      size: Size(328, 729),
      padding: EdgeInsets.only(top: 38, bottom: 36),
      textScale: 1.0,
    ),
    (
      name: '320x711, largest display size',
      size: Size(320, 711),
      padding: EdgeInsets.only(top: 40, bottom: 36),
      textScale: 1.0,
    ),
    (
      name: '360x740, 1080x2220 panel',
      size: Size(360, 740),
      padding: EdgeInsets.only(top: 28, bottom: 48),
      textScale: 1.0,
    ),
    (
      name: '360x800 at 130% text',
      size: Size(360, 800),
      padding: EdgeInsets.only(top: 30, bottom: 48),
      textScale: 1.3,
    ),
    (
      name: '360x800 at 200% text',
      size: Size(360, 800),
      padding: EdgeInsets.only(top: 30, bottom: 48),
      textScale: 2.0,
    ),
    (
      name: '412x915, large phone',
      size: Size(412, 915),
      padding: EdgeInsets.only(top: 40, bottom: 24),
      textScale: 1.0,
    ),
  ]) {
    testWidgets('every key stays on screen at ${viewport.name}', (
      tester,
    ) async {
      tester.view.physicalSize = viewport.size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pump(
        tester,
        MediaQuery(
          data: MediaQueryData(
            size: viewport.size,
            devicePixelRatio: 3,
            padding: viewport.padding,
            viewPadding: viewport.padding,
            textScaler: TextScaler.linear(viewport.textScale),
          ),
          child: const CalculatorPage(),
        ),
      );
      await tester.pumpAndSettle();

      final safeBottom = viewport.size.height - viewport.padding.bottom;
      void expectEveryKeyReachable(String when) {
        final keypad = tester.getRect(find.byType(CalculatorKeypad));
        expect(
          keypad.bottom,
          lessThanOrEqualTo(safeBottom + 0.01),
          reason: 'keypad runs under the navigation bar $when',
        );
        expect(
          tester
              .state<ScrollableState>(
                find.descendant(
                  of: find.byType(CalculatorKeypad),
                  matching: find.byType(Scrollable),
                ),
              )
              .position
              .maxScrollExtent,
          0,
          reason: 'keys are hidden behind a scroll $when',
        );
        for (final key in CalculatorKeypad.keys) {
          final finder = find.descendant(
            of: find.byType(CalculatorKeypad),
            matching: find.text(key),
          );
          expect(finder, findsOneWidget, reason: '"$key" is not built $when');
          final rect = tester.getRect(finder);
          expect(
            rect.left >= keypad.left - 0.01 &&
                rect.right <= keypad.right + 0.01 &&
                rect.top >= keypad.top - 0.01 &&
                rect.bottom <= keypad.bottom + 0.01,
            isTrue,
            reason: '"$key" at $rect falls outside the keypad $keypad $when',
          );
        }
      }

      final field = tester.getRect(find.byKey(const Key('expressionField')));
      final result = tester.getRect(find.byKey(const Key('resultPanel')));
      expect(field.top, greaterThan(0));
      expect(result.top, greaterThan(field.bottom));
      expectEveryKeyReachable('before a calculation');

      await tester.tap(_key(tester, '1'));
      await tester.pump();
      await tester.tap(_key(tester, '+'));
      await tester.pump();
      await tester.tap(_key(tester, '2'));
      await tester.pump();
      await tester.tap(_key(tester, '='));
      await tester.pumpAndSettle();

      expect(
        tester.widget<SelectableText>(find.byKey(const Key('resultText'))).data,
        '3',
      );
      // The result panel carries its actions on the label row, so landing a
      // result does not grow it into the rows below it.
      expect(tester.getRect(find.byKey(const Key('resultPanel'))), result);
      expectEveryKeyReachable('after a calculation');

      // The controls a calculation ends on still work where they landed.
      await tester.tap(_key(tester, '⌫'));
      await tester.pump();
      await tester.tap(_key(tester, '0'));
      await tester.pump();
      await tester.tap(_key(tester, '.'));
      await tester.pump();
      await tester.tap(_key(tester, '5'));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('expressionField')))
            .controller!
            .text,
        '1+0.5',
      );
      await tester.tap(_key(tester, 'AC'));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('expressionField')))
            .controller!
            .text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a keypad with less room than it needs scrolls, and says so', (
    tester,
  ) async {
    // The page only pins the keypad when every key fits, but a result that
    // wraps can still eat into the space afterwards. The grid then scrolls --
    // with a thumb, rather than silently cutting the bottom rows off.
    var tapped = '';
    await _pump(
      tester,
      Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            height: 200,
            child: CalculatorKeypad(
              fillHeight: true,
              onKey: (key) => tapped = key,
              onBackspace: () {},
              onClear: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(CalculatorKeypad),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    expect(
      find.descendant(
        of: find.byType(CalculatorKeypad),
        matching: find.byType(Scrollbar),
      ),
      findsOneWidget,
    );

    // Every key is still reachable, and still works, once scrolled to.
    final grid = find.descendant(
      of: find.byType(CalculatorKeypad),
      matching: find.byType(Scrollable),
    );
    for (final key in ['0', '.', '=', '+']) {
      final finder = _key(tester, key);
      await tester.scrollUntilVisible(finder, 60, scrollable: grid);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pump();
      expect(tapped, key);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('extreme text scales scroll the page instead of overflowing', (
    tester,
  ) async {
    const size = Size(360, 800);
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(
      tester,
      const MediaQuery(
        data: MediaQueryData(
          size: size,
          devicePixelRatio: 3,
          padding: EdgeInsets.only(top: 30, bottom: 48),
          textScaler: TextScaler.linear(3),
        ),
        child: CalculatorPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await _tapKey(tester, '7');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('expressionField')))
          .controller!
          .text,
      '7',
    );
    await _tapKey(tester, '=');
    expect(tester.takeException(), isNull);
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

Finder _key(WidgetTester tester, String label) => find.descendant(
  of: find.byType(CalculatorKeypad),
  matching: find.text(label),
);

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

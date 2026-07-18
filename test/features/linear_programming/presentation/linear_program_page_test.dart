import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/linear_programming/presentation/linear_program_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows a complete non-empty model editor and examples', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Linear Programming'), findsWidgets);
    expect(find.text('New model'), findsWidgets);
    expect(find.text('Product mix'), findsWidgets);
    expect(find.byKey(const Key('lp-objective-0')), findsOneWidget);
    expect(find.byKey(const Key('lp-solve')), findsOneWidget);
  });

  testWidgets('adds variables and constraints only on explicit controls', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('Add variable'));
    await tester.pump();
    expect(find.byKey(const Key('lp-objective-2')), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add constraint'));
    await tester.pumpAndSettle();
    expect(find.text('2/20'), findsOneWidget);
  });

  testWidgets('loads product mix example and renders optimal result', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.widgetWithText(ActionChip, 'Product mix'));
    await tester.pump();
    await tester.drag(find.byType(ListView).first, const Offset(0, -1000));
    await tester.pumpAndSettle();
    final solve = tester.widget<FilledButton>(
      find.byKey(const Key('lp-solve')),
    );
    solve.onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Optimal solution'), findsOneWidget);
    expect(find.text('z = 10'), findsOneWidget);
    expect(find.text('x1 = 2'), findsOneWidget);
  });

  testWidgets('large text remains scrollable without an exception', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(WidgetTester tester) async {
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
        home: const LinearProgramPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

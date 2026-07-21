import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/home/presentation/home_page.dart';
import 'package:calcademy/features/statistics/presentation/statistics_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('groups active tools into the five professional categories', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.byKey(const Key('home-category-mathematics')), findsOneWidget);
    expect(find.byKey(const Key('home-category-optimization')), findsOneWidget);
    expect(find.byKey(const Key('home-category-data')), findsOneWidget);
    expect(find.byKey(const Key('home-category-finance')), findsOneWidget);
    expect(find.byKey(const Key('home-category-workspace')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('home-category-mathematics')),
        matching: find.text('Scientific Calculator'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('home-category-optimization')),
        matching: find.text('Operations Research'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('home-category-finance')),
        matching: find.text('Financial Calculator'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('home-category-workspace')),
        matching: find.text('Saved Calculations'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('search matches module metadata and hides empty categories', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.enterText(
      find.byKey(const Key('home-module-search')),
      'finance',
    );
    await tester.pump();

    expect(
      find.byKey(const Key('module-card-financial-calculator')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home-category-finance')), findsOneWidget);
    expect(find.byKey(const Key('home-category-mathematics')), findsNothing);
    expect(find.byKey(const Key('module-card-calculator')), findsNothing);
  });

  testWidgets('search exposes a localized no-result state', (tester) async {
    await _pumpHome(tester);

    await tester.enterText(
      find.byKey(const Key('home-module-search')),
      'not-a-calcademy-module',
    );
    await tester.pump();

    expect(find.byKey(const Key('home-search-empty')), findsOneWidget);
    expect(find.text('No matching tools'), findsOneWidget);
    expect(find.byKey(const Key('module-card-calculator')), findsNothing);
  });

  testWidgets('module card preserves route navigation', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomePage()),
        GoRoute(path: '/statistics', builder: (_, _) => const StatisticsPage()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: _app(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const Key('module-card-statistics'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card.hitTestable());
    await tester.pumpAndSettle();

    expect(find.byType(StatisticsPage), findsOneWidget);
  });

  testWidgets(
    '320px and 200 percent text scale remain scrollable and bounded',
    (tester) async {
      _setViewport(tester, const Size(320, 690), scale: 2);
      await _pumpHome(tester);

      expect(tester.takeException(), isNull);
      final searchRect = tester.getRect(
        find.byKey(const Key('home-module-search')),
      );
      expect(searchRect.left, greaterThanOrEqualTo(16));
      expect(searchRect.right, lessThanOrEqualTo(304));

      await tester.fling(
        find.byKey(const Key('home-scroll')),
        const Offset(0, -3000),
        1400,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('home builds in dark mode with readable scheme surfaces', (
    tester,
  ) async {
    await _pumpHome(tester, dark: true);

    final context = tester.element(find.byType(HomePage));
    final theme = Theme.of(context);
    expect(theme.brightness, Brightness.dark);
    expect(
      theme.colorScheme.onSurface.computeLuminance(),
      greaterThan(theme.colorScheme.surface.computeLuminance()),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHome(WidgetTester tester, {bool dark = false}) async {
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: _app(home: const HomePage(), dark: dark),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _app({
  Widget? home,
  RouterConfig<Object>? routerConfig,
  bool dark = false,
}) {
  const delegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  if (routerConfig != null) {
    return MaterialApp.router(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: delegates,
      routerConfig: routerConfig,
    );
  }
  return MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: delegates,
    home: home,
  );
}

void _setViewport(WidgetTester tester, Size size, {double scale = 1}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

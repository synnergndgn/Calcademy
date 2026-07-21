import 'package:calcademy/app/theme/app_colors.dart';
import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/core/widgets/calcademy_logo.dart';
import 'package:calcademy/core/widgets/empty_state.dart';
import 'package:calcademy/features/home/presentation/home_page.dart';
import 'package:calcademy/features/operations_research/presentation/operations_research_page.dart';
import 'package:calcademy/features/home/presentation/splash_page.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_calculator_page.dart';
import 'package:calcademy/features/saved_calculations/presentation/saved_calculations_page.dart';
import 'package:calcademy/features/settings/presentation/about_page.dart';
import 'package:calcademy/features/statistics/presentation/statistics_page.dart';
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

  test('official logo asset is bundled without brand color changes', () async {
    final svg = await rootBundle.loadString(CalcademyLogo.assetPath);

    expect(svg, contains('#8FAE9E'));
    expect(svg, contains('#63897A'));
    expect(svg, contains('#FBFAF5'));
    expect(svg, contains('#E7B77D'));
    expect(svg, contains('viewBox="0 0 200 200"'));
  });

  testWidgets('splash shows the Calcademy brand and localized tagline', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
        GoRoute(path: '/home', builder: (_, _) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_localizedApp(routerConfig: router));
    await tester.pump();

    expect(find.byKey(const Key('calcademyLogoMark')), findsOneWidget);
    expect(find.text('Calcademy'), findsOneWidget);
    expect(find.text('Calculate. Visualize. Optimize. Learn.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('home shows brand and professional module categories', (
    tester,
  ) async {
    await _pumpWithPreferences(tester, const HomePage());

    expect(find.byKey(const Key('calcademyLogoMark')), findsOneWidget);
    expect(find.text('Calcademy'), findsOneWidget);
    expect(find.text('Mathematics'), findsWidgets);
    expect(find.text('Optimization & Operations Research'), findsWidgets);
    expect(find.text('Data & Statistics'), findsWidgets);
    expect(find.text('Finance'), findsWidgets);
    expect(find.text('Workspace'), findsWidgets);
    expect(find.byKey(const Key('module-card-calculator')), findsOneWidget);
    expect(find.byIcon(Icons.schedule_rounded), findsWidgets);
  });

  testWidgets('home remains overflow-free on a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpWithPreferences(tester, const HomePage());
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const Key('home-module-search'))).width,
      lessThanOrEqualTo(288),
    );

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -2400),
      1200,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('home uses its responsive module layout on a tablet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpWithPreferences(tester, const HomePage());
    expect(find.text('Graphing'), findsOneWidget);
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -1200),
      1200,
    );
    await tester.pumpAndSettle();

    expect(find.text('Equation Solver'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Statistics card opens the Statistics workspace', (tester) async {
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
        child: _localizedApp(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    final statisticsCard = find.text('Statistics');
    for (
      var i = 0;
      i < 8 && statisticsCard.hitTestable().evaluate().isEmpty;
      i++
    ) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    await tester.tap(statisticsCard.hitTestable());
    await tester.pumpAndSettle();

    expect(find.byType(StatisticsPage), findsOneWidget);
    expect(find.byKey(const Key('stats-data-input')), findsOneWidget);
  });

  testWidgets('Financial Calculator card opens its workspace', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomePage()),
        GoRoute(
          path: '/financial-calculator',
          builder: (_, _) => const FinancialCalculatorPage(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: _localizedApp(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    final financialCard = find.text('Financial Calculator');
    for (
      var i = 0;
      i < 10 && financialCard.hitTestable().evaluate().isEmpty;
      i++
    ) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    await tester.tap(financialCard.hitTestable());
    await tester.pumpAndSettle();

    expect(find.byType(FinancialCalculatorPage), findsOneWidget);
    expect(find.byKey(const Key('fin-tvm-operation')), findsOneWidget);
  });

  testWidgets('Saved Calculations card opens its workspace', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomePage()),
        GoRoute(
          path: '/saved-calculations',
          builder: (_, _) => const SavedCalculationsPage(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: _localizedApp(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    final savedCard = find.text('Saved Calculations');
    for (var i = 0; i < 12 && savedCard.hitTestable().evaluate().isEmpty; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    await tester.tap(savedCard.hitTestable());
    await tester.pumpAndSettle();

    expect(find.byType(SavedCalculationsPage), findsOneWidget);
    expect(find.byKey(const Key('saved-search')), findsOneWidget);
  });

  testWidgets('Operations Research card opens its workspace', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomePage()),
        GoRoute(
          path: '/operations-research',
          builder: (_, _) => const OperationsResearchPage(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: _localizedApp(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    final card = find.text('Operations Research');
    for (var i = 0; i < 14 && card.hitTestable().evaluate().isEmpty; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    await tester.tap(card.hitTestable().first);
    await tester.pumpAndSettle();

    expect(find.byType(OperationsResearchPage), findsOneWidget);
    expect(find.byKey(const Key('or-transport-grid-scroll')), findsOneWidget);
  });

  testWidgets('about shows the official logo and brand information', (
    tester,
  ) async {
    await tester.pumpWidget(_localizedApp(home: const AboutPage()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calcademyLogoMark')), findsOneWidget);
    expect(find.text('Calcademy'), findsOneWidget);
    expect(find.text('Privacy & data handling'), findsOneWidget);
    expect(find.text('Version 1.0.0 (1)'), findsOneWidget);
  });

  testWidgets('light and dark brand themes build with distinct surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        home: const Scaffold(body: Text('theme')),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('theme'))).brightness,
      Brightness.light,
    );
    expect(
      Theme.of(tester.element(find.text('theme'))).colorScheme.surface,
      AppColors.warmWhite,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const Scaffold(body: Text('theme')),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('theme'))).brightness,
      Brightness.dark,
    );
    expect(
      Theme.of(tester.element(find.text('theme'))).colorScheme.surface,
      isNot(AppColors.warmWhite),
    );
  });

  testWidgets('empty state renders icon, copy, and optional action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(
        home: const Scaffold(
          body: EmptyState(
            icon: Icons.history_toggle_off_rounded,
            title: 'Nothing here',
            body: 'Try a calculation first.',
            action: FilledButton(onPressed: null, child: Text('Start')),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.history_toggle_off_rounded), findsOneWidget);
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Try a calculation first.'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });
}

Future<void> _pumpWithPreferences(WidgetTester tester, Widget child) async {
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: _localizedApp(home: child),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _localizedApp({Widget? home, RouterConfig<Object>? routerConfig}) {
  const delegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  if (routerConfig != null) {
    return MaterialApp.router(
      theme: AppTheme.light(),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: delegates,
      routerConfig: routerConfig,
    );
  }
  return MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: delegates,
    home: home,
  );
}

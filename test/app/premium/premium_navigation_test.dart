import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/home/presentation/home_page.dart';
import 'package:calcademy/features/premium/presentation/premium_page.dart';
import 'package:calcademy/features/settings/presentation/settings_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Settings opens the Premium page', (tester) async {
    final router = _router('/settings');
    addTearDown(router.dispose);
    await _pump(tester, router);

    final tile = find.byKey(const Key('settings-premium-tile'));
    for (var attempt = 0; attempt < 8 && tile.evaluate().isEmpty; attempt++) {
      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile.hitTestable());
    await tester.pumpAndSettle();

    expect(find.byType(PremiumPage), findsOneWidget);
  });

  testWidgets('Home search opens the Premium page', (tester) async {
    final router = _router('/home');
    addTearDown(router.dispose);
    await _pump(tester, router);

    await tester.enterText(
      find.byKey(const Key('home-module-search')),
      'premium',
    );
    await tester.pump();
    final card = find.byKey(const Key('module-card-premium'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card.hitTestable());
    await tester.pumpAndSettle();

    expect(find.byType(PremiumPage), findsOneWidget);
  });
}

GoRouter _router(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/home', builder: (_, _) => const HomePage()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
    GoRoute(path: '/premium', builder: (_, _) => const PremiumPage()),
  ],
);

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  final preferences = await SharedPreferences.getInstance();
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

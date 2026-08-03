import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/account/presentation/account_page.dart';
import 'package:calcademy/features/account/presentation/sign_in_page.dart';
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

  testWidgets('Settings opens the Account page', (tester) async {
    final router = _router('/settings');
    addTearDown(router.dispose);
    await _pump(tester, router);

    final tile = find.byKey(const Key('settings-account-tile'));
    for (var attempt = 0; attempt < 8 && tile.evaluate().isEmpty; attempt++) {
      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(tile);
    await tester.tap(tile.hitTestable());
    await tester.pumpAndSettle();

    expect(find.byType(AccountPage), findsOneWidget);
  });

  testWidgets('Premium sign in action opens the sign in page', (tester) async {
    final router = _router('/premium');
    addTearDown(router.dispose);
    await _pump(tester, router);

    await _scrollUntilVisible(tester, const Key('premium-sign-in-button'));
    await tester.tap(
      find.byKey(const Key('premium-sign-in-button')).hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SignInPage), findsOneWidget);
  });
}

GoRouter _router(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/home', builder: (_, _) => const HomePage()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
    GoRoute(path: '/premium', builder: (_, _) => const PremiumPage()),
    GoRoute(path: '/account', builder: (_, _) => const AccountPage()),
    GoRoute(path: '/sign-in', builder: (_, _) => const SignInPage()),
  ],
);

Future<void> _scrollUntilVisible(WidgetTester tester, Key key) async {
  for (var attempt = 0; attempt < 12; attempt++) {
    final target = find.byKey(key);
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      return;
    }
    await tester.drag(
      find.byKey(const Key('premium-scroll')),
      const Offset(0, -280),
    );
    await tester.pumpAndSettle();
  }
}

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

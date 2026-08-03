import 'dart:io';

import 'package:calcademy/app/auth/app_user.dart';
import 'package:calcademy/app/auth/auth_providers.dart';
import 'package:calcademy/app/auth/auth_repository.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/auth/local_auth_repository.dart';
import 'package:calcademy/app/premium/entitlement_repository.dart';
import 'package:calcademy/app/premium/local_entitlement_repository.dart';
import 'package:calcademy/app/premium/premium_entitlement.dart';
import 'package:calcademy/app/premium/premium_gate_controller.dart';
import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/features/camera_solver/presentation/camera_solver_page.dart';
import 'package:calcademy/features/premium/presentation/premium_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    '/premium shows free status, benefits, and disabled purchase UI',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/premium',
        routes: [
          GoRoute(path: '/premium', builder: (_, _) => const PremiumPage()),
        ],
      );
      addTearDown(router.dispose);
      await _pump(tester, router);

      expect(find.byType(PremiumPage), findsOneWidget);
      expect(find.text('Free plan'), findsOneWidget);
      expect(find.text('Gemini-powered assistant'), findsOneWidget);
      expect(find.text('Camera Solver'), findsOneWidget);
      expect(find.text('Remove ads'), findsOneWidget);
      expect(find.text('Higher daily limits'), findsOneWidget);
      await _scrollUntilBuilt(tester, const Key('premium-subscribe-button'));
      final subscribe = tester.widget<FilledButton>(
        find.byKey(const Key('premium-subscribe-button')),
      );
      expect(subscribe.onPressed, isNull);
      expect(find.byKey(const Key('premium-coming-soon')), findsOneWidget);
    },
  );

  testWidgets('signed-in premium page shows account email', (tester) async {
    final router = GoRouter(
      initialLocation: '/premium',
      routes: [
        GoRoute(path: '/premium', builder: (_, _) => const PremiumPage()),
      ],
    );
    addTearDown(router.dispose);
    final authRepository = LocalAuthRepository(
      initialStatus: AuthStatus.signedIn,
      initialUser: const AppUser(
        id: 'premium-user',
        email: 'student@example.com',
      ),
    );
    addTearDown(authRepository.dispose);

    await _pump(tester, router, authRepository: authRepository);

    expect(find.byKey(const Key('premium-user-email')), findsOneWidget);
    expect(find.text('student@example.com'), findsOneWidget);
  });

  testWidgets(
    'mock premium status is visible without enabling a purchase flow',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/premium',
        routes: [
          GoRoute(path: '/premium', builder: (_, _) => const PremiumPage()),
        ],
      );
      addTearDown(router.dispose);
      await _pump(
        tester,
        router,
        repository: LocalEntitlementRepository(
          initialEntitlement: const PremiumEntitlement.mockPremium(),
        ),
      );

      expect(find.text('Premium active'), findsWidgets);
      await _scrollUntilBuilt(tester, const Key('premium-subscribe-button'));
      expect(find.textContaining('mock premium entitlement'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('premium-subscribe-button')),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('/camera-solver opens a premium coming-soon placeholder', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/camera-solver',
      routes: [
        GoRoute(
          path: '/camera-solver',
          builder: (_, _) => const CameraSolverPage(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await _pump(tester, router);

    expect(find.byType(CameraSolverPage), findsOneWidget);
    expect(find.text('Camera Solver coming soon'), findsOneWidget);
    expect(find.byKey(const Key('premium-gate-cameraSolver')), findsOneWidget);
    expect(find.text('No camera permission is requested yet.'), findsOneWidget);
    expect(find.text('OCR is not included yet.'), findsOneWidget);
    expect(find.text('No image is selected or uploaded.'), findsOneWidget);
  });

  testWidgets('premium placeholders remain bounded at 320px and 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 690);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final router = GoRouter(
      initialLocation: '/premium',
      routes: [
        GoRoute(path: '/premium', builder: (_, _) => const PremiumPage()),
      ],
    );
    addTearDown(router.dispose);
    await _pump(tester, router);

    expect(tester.takeException(), isNull);
    await tester.fling(
      find.byKey(const Key('premium-scroll')),
      const Offset(0, -3000),
      1400,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('camera placeholder adds no permission or imaging dependency', () async {
    final manifest = await File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsString();
    final pubspec = await File('pubspec.yaml').readAsString();

    expect(manifest, isNot(contains('android.permission.CAMERA')));
    expect(
      pubspec,
      isNot(contains(RegExp(r'^\s*camera\s*:', multiLine: true))),
    );
    expect(pubspec, isNot(contains('image_picker:')));
    expect(pubspec.toLowerCase(), isNot(contains('mlkit')));
    expect(pubspec.toLowerCase(), isNot(contains('billing_client')));
    expect(pubspec.toLowerCase(), isNot(contains('in_app_purchase:')));
  });

  test('Premium localization keys have English and Turkish parity', () {
    const english = AppLocalizations(Locale('en'));
    const turkish = AppLocalizations(Locale('tr'));
    const keys = [
      'premium',
      'calcademyPremium',
      'freePlan',
      'premiumActive',
      'premiumRequired',
      'signInRequired',
      'signIn',
      'createAccount',
      'subscribe',
      'manageSubscription',
      'comingSoon',
      'removeAds',
      'premiumGeminiAssistant',
      'cameraSolver',
      'higherDailyLimits',
      'premiumFeatureRequired',
      'basicToolsRemain',
      'basicToolsNoAccount',
      'accountDeletionFuture',
    ];
    for (final key in keys) {
      expect(english.t(key), isNot(key), reason: 'English missing $key');
      expect(turkish.t(key), isNot(key), reason: 'Turkish missing $key');
    }
  });

  test(
    'auth foundation adds Supabase without billing or AI providers',
    () async {
      final pubspec = await File('pubspec.yaml').readAsString();
      final premiumPage = await File(
        'lib/features/premium/presentation/premium_page.dart',
      ).readAsString();
      final authRepository = await File(
        'lib/app/auth/local_auth_repository.dart',
      ).readAsString();

      expect(pubspec, contains('supabase_flutter: 2.16.0'));
      expect(pubspec.toLowerCase(), isNot(contains('in_app_purchase')));
      expect(pubspec.toLowerCase(), isNot(contains('google_generative_ai')));
      expect(premiumPage, isNot(contains('productId')));
      expect(premiumPage, isNot(contains('launchUrl')));
      expect(authRepository, isNot(contains('http')));
    },
  );
}

Future<void> _scrollUntilBuilt(WidgetTester tester, Key key) async {
  for (
    var attempt = 0;
    attempt < 12 && find.byKey(key).evaluate().isEmpty;
    attempt++
  ) {
    await tester.drag(
      find.byKey(const Key('premium-scroll')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _pump(
  WidgetTester tester,
  GoRouter router, {
  EntitlementRepository? repository,
  AuthRepository? authRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repository != null)
          entitlementRepositoryProvider.overrideWithValue(repository),
        if (authRepository != null)
          authRepositoryProvider.overrideWithValue(authRepository),
        if (authRepository != null)
          isAuthConfiguredProvider.overrideWithValue(true),
      ],
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

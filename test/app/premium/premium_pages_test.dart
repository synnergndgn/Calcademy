import 'dart:io';

import 'package:calcademy/app/auth/app_user.dart';
import 'package:calcademy/app/auth/auth_providers.dart';
import 'package:calcademy/app/auth/auth_repository.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/auth/local_auth_repository.dart';
import 'package:calcademy/app/billing/billing_controller.dart';
import 'package:calcademy/app/billing/billing_repository.dart';
import 'package:calcademy/app/billing/local_billing_repository.dart';
import 'package:calcademy/app/premium/entitlement_repository.dart';
import 'package:calcademy/app/premium/local_entitlement_repository.dart';
import 'package:calcademy/app/premium/premium_entitlement.dart';
import 'package:calcademy/app/premium/premium_gate_controller.dart';
import 'package:calcademy/app/premium/premium_status.dart';
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
  testWidgets('/premium shows free status, benefits, and account-required UI', (
    tester,
  ) async {
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
    await _scrollUntilBuilt(tester, const Key('premium-sign-in-button'));
    expect(find.text('Premium requires an account'), findsOneWidget);
    expect(find.byKey(const Key('premium-subscribe-button')), findsNothing);
  });

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

    await _pump(
      tester,
      router,
      authRepository: authRepository,
      billingRepository: LocalBillingRepository(),
    );

    expect(find.byKey(const Key('premium-user-email')), findsOneWidget);
    expect(find.text('student@example.com'), findsOneWidget);
    await _scrollUntilBuilt(tester, const Key('premium-subscribe-button'));
    expect(find.byKey(const Key('premium-billing-section')), findsOneWidget);
    expect(find.byKey(const Key('premium-subscribe-button')), findsOneWidget);
    expect(find.byKey(const Key('premium-restore-button')), findsOneWidget);
    expect(find.byKey(const Key('premium-manage-button')), findsOneWidget);
    expect(find.text('Subscription managed by Google Play.'), findsOneWidget);
  });

  testWidgets('signed-in unsupported build shows billing unavailable', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/premium',
      routes: [
        GoRoute(path: '/premium', builder: (_, _) => const PremiumPage()),
      ],
    );
    addTearDown(router.dispose);
    final authRepository = LocalAuthRepository(
      initialStatus: AuthStatus.signedIn,
      initialUser: const AppUser(id: 'premium-user'),
    );
    final billingRepository = LocalBillingRepository(available: false);
    addTearDown(authRepository.dispose);
    addTearDown(billingRepository.dispose);

    await _pump(
      tester,
      router,
      authRepository: authRepository,
      billingRepository: billingRepository,
    );
    await _scrollUntilBuilt(tester, const Key('premium-billing-unavailable'));

    expect(
      find.text('Billing is not available on this device or build.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('premium-subscribe-button')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('purchase receipt stays pending validation and free', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/premium',
      routes: [
        GoRoute(path: '/premium', builder: (_, _) => const PremiumPage()),
      ],
    );
    addTearDown(router.dispose);
    final authRepository = LocalAuthRepository(
      initialStatus: AuthStatus.signedIn,
      initialUser: const AppUser(id: 'premium-user'),
    );
    final billingRepository = LocalBillingRepository();
    addTearDown(authRepository.dispose);
    addTearDown(billingRepository.dispose);

    await _pump(
      tester,
      router,
      authRepository: authRepository,
      billingRepository: billingRepository,
    );
    await _scrollUntilBuilt(tester, const Key('premium-subscribe-button'));
    await tester.ensureVisible(
      find.byKey(const Key('premium-subscribe-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('premium-subscribe-button')).hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('premium-purchase-received')), findsOneWidget);
    expect(
      find.text(
        'Backend validation pending. Backend validation is not enabled yet.',
      ),
      findsOneWidget,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PremiumPage)),
    );
    expect(container.read(premiumGateControllerProvider).isPremium, isFalse);
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
      expect(find.byKey(const Key('premium-subscribe-button')), findsNothing);
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
    expect(pubspec, contains('in_app_purchase: ^3.3.0'));
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
      'restorePurchases',
      'manageSubscription',
      'billingUnavailable',
      'purchasePending',
      'purchaseReceived',
      'validatingPurchase',
      'purchaseValidationRequired',
      'backendValidationPending',
      'purchaseValidationUnavailable',
      'premiumStatusSyncedFromAccount',
      'subscriptionExpired',
      'subscriptionCanceled',
      'couldNotSyncEntitlement',
      'tryAgain',
      'premiumSubscription',
      'monthlyPlan',
      'currentPlan',
      'noActiveSubscription',
      'subscriptionManagedByGooglePlay',
      'cancelAnytimeGooglePlay',
      'purchasesProcessedGooglePlay',
      'signInToSubscribe',
      'billingComingSoon',
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

  test('billing foundation adds Play Billing without AI providers', () async {
    final pubspec = await File('pubspec.yaml').readAsString();
    final premiumPage = await File(
      'lib/features/premium/presentation/premium_page.dart',
    ).readAsString();
    final authRepository = await File(
      'lib/app/auth/local_auth_repository.dart',
    ).readAsString();

    expect(pubspec, contains('supabase_flutter: 2.16.0'));
    expect(pubspec, contains('in_app_purchase: ^3.3.0'));
    expect(pubspec.toLowerCase(), isNot(contains('google_generative_ai')));
    expect(premiumPage, contains('billingControllerProvider'));
    expect(premiumPage, contains("play.google.com"));
    expect(authRepository, isNot(contains('http')));
  });

  for (final statusCase in [
    (PremiumStatus.pendingValidation, 'Backend validation pending.'),
    (PremiumStatus.premiumExpired, 'Subscription expired'),
    (PremiumStatus.premiumCanceled, 'Subscription canceled'),
  ]) {
    testWidgets('premium page renders ${statusCase.$1.name}', (tester) async {
      final router = GoRouter(
        initialLocation: '/premium',
        routes: [
          GoRoute(path: '/premium', builder: (_, _) => const PremiumPage()),
        ],
      );
      addTearDown(router.dispose);
      final authRepository = LocalAuthRepository(
        initialStatus: AuthStatus.signedIn,
        initialUser: const AppUser(id: 'status-user'),
      );
      addTearDown(authRepository.dispose);
      await _pump(
        tester,
        router,
        repository: LocalEntitlementRepository(
          initialEntitlement: PremiumEntitlement.free(
            status: statusCase.$1,
            source: EntitlementSource.backend,
          ),
        ),
        authRepository: authRepository,
        billingRepository: LocalBillingRepository(available: false),
      );

      expect(find.textContaining(statusCase.$2), findsOneWidget);
      expect(find.text('Free plan'), findsOneWidget);
    });
  }
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
  BillingRepository? billingRepository,
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
        if (billingRepository != null)
          billingRepositoryProvider.overrideWithValue(billingRepository),
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

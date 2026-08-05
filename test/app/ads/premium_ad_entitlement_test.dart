import 'package:calcademy/app/ads/ad_banner.dart';
import 'package:calcademy/app/auth/app_user.dart';
import 'package:calcademy/app/auth/auth_providers.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/auth/local_auth_repository.dart';
import 'package:calcademy/app/premium/entitlement_repository.dart';
import 'package:calcademy/app/premium/local_entitlement_repository.dart';
import 'package:calcademy/app/premium/premium_entitlement.dart';
import 'package:calcademy/app/premium/premium_feature.dart';
import 'package:calcademy/app/premium/premium_gate_controller.dart';
import 'package:calcademy/app/premium/premium_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('free entitlement preserves the normal ad slot', (tester) async {
    await _pump(
      tester,
      LocalEntitlementRepository(
        initialEntitlement: const PremiumEntitlement.free(),
      ),
    );
    expect(find.byKey(const Key('ad-banner-not-loaded')), findsOneWidget);
    expect(find.byKey(const Key('ad-banner-premium-hidden')), findsNothing);
  });

  testWidgets('mock premium removeAds entitlement shrinks the ad slot', (
    tester,
  ) async {
    await _pump(
      tester,
      LocalEntitlementRepository(
        initialEntitlement: const PremiumEntitlement.mockPremium(),
      ),
    );
    expect(find.byKey(const Key('ad-banner-premium-hidden')), findsOneWidget);
    expect(tester.getSize(find.byType(AdBanner)).height, 0);
  });

  testWidgets('signed-in backend active entitlement hides the ad slot', (
    tester,
  ) async {
    final auth = LocalAuthRepository(
      initialStatus: AuthStatus.signedIn,
      initialUser: const AppUser(id: 'premium-user'),
    );
    addTearDown(auth.dispose);
    await _pump(
      tester,
      LocalEntitlementRepository(
        initialEntitlement: const PremiumEntitlement(
          status: PremiumStatus.premiumActive,
          activeFeatures: {PremiumFeature.removeAds},
          source: EntitlementSource.backend,
        ),
      ),
      auth: auth,
    );
    expect(find.byKey(const Key('ad-banner-premium-hidden')), findsOneWidget);
  });

  testWidgets('pending backend validation keeps the ad slot', (tester) async {
    final auth = LocalAuthRepository(
      initialStatus: AuthStatus.signedIn,
      initialUser: const AppUser(id: 'pending-user'),
    );
    addTearDown(auth.dispose);
    await _pump(
      tester,
      LocalEntitlementRepository(
        initialEntitlement: const PremiumEntitlement.free(
          status: PremiumStatus.pendingValidation,
          source: EntitlementSource.backend,
        ),
      ),
      auth: auth,
    );
    expect(find.byKey(const Key('ad-banner-not-loaded')), findsOneWidget);
    expect(find.byKey(const Key('ad-banner-premium-hidden')), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester,
  EntitlementRepository repository, {
  LocalAuthRepository? auth,
}) => tester.pumpWidget(
  ProviderScope(
    overrides: [
      entitlementRepositoryProvider.overrideWithValue(repository),
      if (auth != null) authRepositoryProvider.overrideWithValue(auth),
      if (auth != null) isAuthConfiguredProvider.overrideWithValue(true),
    ],
    child: const MaterialApp(
      home: Scaffold(bottomNavigationBar: AdBanner(enabled: false)),
    ),
  ),
);

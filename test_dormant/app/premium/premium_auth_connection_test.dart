import 'package:calcademy/app/auth/app_user.dart';
import 'package:calcademy/app/auth/auth_providers.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/auth/local_auth_repository.dart';
import 'package:calcademy/app/premium/local_entitlement_repository.dart';
import 'package:calcademy/app/premium/premium_entitlement.dart';
import 'package:calcademy/app/premium/premium_feature.dart';
import 'package:calcademy/app/premium/premium_gate_controller.dart';
import 'package:calcademy/app/premium/premium_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const backendPremium = PremiumEntitlement(
    status: PremiumStatus.premiumActive,
    activeFeatures: {PremiumFeature.removeAds},
    source: EntitlementSource.backend,
  );

  test('signed-out auth forces non-mock entitlement to free', () async {
    final auth = LocalAuthRepository();
    final container = _container(auth, backendPremium);
    addTearDown(container.dispose);
    addTearDown(auth.dispose);

    expect(container.read(premiumGateControllerProvider).isPremium, isFalse);
  });

  test('signed-in user remains free without backend premium', () async {
    final auth = LocalAuthRepository(
      initialStatus: AuthStatus.signedIn,
      initialUser: const AppUser(id: 'student'),
    );
    final container = _container(auth, const PremiumEntitlement.free());
    addTearDown(container.dispose);
    addTearDown(auth.dispose);

    expect(container.read(premiumGateControllerProvider).isPremium, isFalse);
  });

  test('signed-in user can receive a backend premium entitlement', () async {
    final auth = LocalAuthRepository(
      initialStatus: AuthStatus.signedIn,
      initialUser: const AppUser(id: 'premium-student'),
    );
    final container = _container(auth, backendPremium);
    addTearDown(container.dispose);
    addTearDown(auth.dispose);

    expect(container.read(premiumGateControllerProvider).isPremium, isTrue);
    expect(
      container
          .read(premiumGateControllerProvider)
          .canUse(PremiumFeature.removeAds),
      isTrue,
    );
  });
}

ProviderContainer _container(
  LocalAuthRepository auth,
  PremiumEntitlement entitlement,
) => ProviderContainer(
  overrides: [
    authRepositoryProvider.overrideWithValue(auth),
    isAuthConfiguredProvider.overrideWithValue(true),
    entitlementRepositoryProvider.overrideWithValue(
      LocalEntitlementRepository(initialEntitlement: entitlement),
    ),
  ],
);

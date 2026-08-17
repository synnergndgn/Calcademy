import 'package:calcademy/app/auth/app_user.dart';
import 'package:calcademy/app/auth/auth_providers.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/auth/local_auth_repository.dart';
import 'package:calcademy/app/billing/billing_controller.dart';
import 'package:calcademy/app/billing/billing_state.dart';
import 'package:calcademy/app/billing/local_billing_repository.dart';
import 'package:calcademy/app/premium/entitlement_sync_service.dart';
import 'package:calcademy/app/premium/local_entitlement_repository.dart';
import 'package:calcademy/app/premium/premium_entitlement.dart';
import 'package:calcademy/app/premium/premium_feature.dart';
import 'package:calcademy/app/premium/premium_gate_controller.dart';
import 'package:calcademy/app/premium/premium_status.dart';
import 'package:calcademy/app/premium/purchase_validation_request.dart';
import 'package:calcademy/app/premium/purchase_validation_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('signed-out user cannot subscribe', () async {
    final fixture = _Fixture(signedIn: false);
    addTearDown(fixture.dispose);
    await fixture.controller.initialize();
    expect(await fixture.controller.subscribe(), isFalse);
    expect(fixture.sync.requests, isEmpty);
    expect(
      fixture.container.read(premiumGateControllerProvider).isPremium,
      isFalse,
    );
  });

  test('signed-in user loads a purchasable product', () async {
    final fixture = _Fixture();
    addTearDown(fixture.dispose);
    final initializing = fixture.controller.initialize();
    expect(
      fixture.container.read(billingControllerProvider).status,
      BillingStatus.loading,
    );
    await initializing;
    final state = fixture.container.read(billingControllerProvider);
    expect(state.status, BillingStatus.available);
    expect(state.primaryProduct, isNotNull);
  });

  test('unavailable repository produces unavailable state', () async {
    final fixture = _Fixture(available: false);
    addTearDown(fixture.dispose);
    await fixture.controller.initialize();
    expect(
      fixture.container.read(billingControllerProvider).status,
      BillingStatus.unavailable,
    );
  });

  test('pending purchase remains pending', () async {
    final fixture = _Fixture(outcome: LocalPurchaseOutcome.pending);
    addTearDown(fixture.dispose);
    await fixture.controller.initialize();
    expect(await fixture.controller.subscribe(), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(
      fixture.container.read(billingControllerProvider).status,
      BillingStatus.purchasePending,
    );
  });

  test(
    'purchase receipt requires validation and never unlocks premium',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.dispose);
      await fixture.controller.initialize();
      expect(await fixture.controller.subscribe(), isTrue);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final state = fixture.container.read(billingControllerProvider);
      expect(state.status, BillingStatus.purchased);
      expect(state.isPendingValidation, isTrue);
      expect(fixture.sync.requests, hasLength(1));
      expect(fixture.repository.completedPurchaseCount, 1);
      expect(
        fixture.container.read(premiumGateControllerProvider).isPremium,
        isFalse,
      );
    },
  );

  test('restore is handled as pending backend validation', () async {
    final fixture = _Fixture();
    addTearDown(fixture.dispose);
    await fixture.controller.initialize();
    expect(await fixture.controller.restorePurchases(), isTrue);
    await Future<void>.delayed(Duration.zero);
    final state = fixture.container.read(billingControllerProvider);
    expect(state.status, BillingStatus.restored);
    expect(state.isPendingValidation, isTrue);
  });

  test('default entitlement sync stub is unsupported', () async {
    const service = PendingEntitlementSyncService();
    final result = await service.validateAndSync(
      const PurchaseValidationRequest(
        userId: 'student',
        productId: 'product',
        purchaseToken: 'memory-only',
        platform: 'android',
      ),
    );
    expect(result.status, PurchaseValidationStatus.unsupported);
    expect(result.grantsPremium, isFalse);
  });

  test(
    'mock active validation refreshes explicit backend entitlement',
    () async {
      final auth = LocalAuthRepository(
        initialStatus: AuthStatus.signedIn,
        initialUser: const AppUser(id: 'premium-student'),
      );
      final billing = LocalBillingRepository();
      final entitlement = LocalEntitlementRepository();
      final sync = _ActivatingSyncService(entitlement);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          isAuthConfiguredProvider.overrideWithValue(true),
          billingRepositoryProvider.overrideWithValue(billing),
          entitlementRepositoryProvider.overrideWithValue(entitlement),
          entitlementSyncServiceProvider.overrideWithValue(sync),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(auth.dispose);
      addTearDown(billing.dispose);

      final controller = container.read(billingControllerProvider.notifier);
      await controller.initialize();
      expect(await controller.subscribe(), isTrue);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(premiumGateControllerProvider).isPremium, isTrue);
      expect(
        container
            .read(premiumGateControllerProvider)
            .canUse(PremiumFeature.removeAds),
        isTrue,
      );
    },
  );
}

class _Fixture {
  _Fixture({
    bool signedIn = true,
    bool available = true,
    LocalPurchaseOutcome outcome = LocalPurchaseOutcome.success,
  }) : auth = LocalAuthRepository(
         initialStatus: signedIn ? AuthStatus.signedIn : AuthStatus.signedOut,
         initialUser: signedIn ? const AppUser(id: 'student') : null,
       ),
       repository = LocalBillingRepository(
         available: available,
         outcome: outcome,
       ),
       sync = _RecordingSyncService() {
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        isAuthConfiguredProvider.overrideWithValue(true),
        billingRepositoryProvider.overrideWithValue(repository),
        entitlementSyncServiceProvider.overrideWithValue(sync),
      ],
    );
  }

  final LocalAuthRepository auth;
  final LocalBillingRepository repository;
  final _RecordingSyncService sync;
  late final ProviderContainer container;

  BillingController get controller =>
      container.read(billingControllerProvider.notifier);

  void dispose() {
    container.dispose();
    auth.dispose();
    repository.dispose();
  }
}

class _RecordingSyncService implements EntitlementSyncService {
  final requests = <PurchaseValidationRequest>[];

  @override
  Future<PurchaseValidationResult> validateAndSync(
    PurchaseValidationRequest request,
  ) async {
    requests.add(request);
    return const PurchaseValidationResult.unsupported();
  }
}

class _ActivatingSyncService implements EntitlementSyncService {
  _ActivatingSyncService(this.repository);

  final LocalEntitlementRepository repository;

  @override
  Future<PurchaseValidationResult> validateAndSync(
    PurchaseValidationRequest request,
  ) async {
    repository.setEntitlement(
      const PremiumEntitlement(
        status: PremiumStatus.premiumActive,
        activeFeatures: {PremiumFeature.removeAds},
        source: EntitlementSource.backend,
      ),
    );
    return const PurchaseValidationResult.active();
  }
}

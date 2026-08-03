import 'package:calcademy/app/auth/auth_gate_controller.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/premium/entitlement_repository.dart';
import 'package:calcademy/app/premium/local_entitlement_repository.dart';
import 'package:calcademy/app/premium/premium_entitlement.dart';
import 'package:calcademy/app/premium/premium_feature.dart';
import 'package:calcademy/app/premium/premium_feature_gate.dart';
import 'package:calcademy/app/premium/premium_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final entitlementRepositoryProvider = Provider<EntitlementRepository>(
  (ref) => LocalEntitlementRepository(),
);

final premiumFeatureGateProvider = Provider<PremiumFeatureGate>(
  (ref) => const PremiumFeatureGate(),
);

final premiumGateControllerProvider =
    NotifierProvider<PremiumGateController, PremiumEntitlement>(
      PremiumGateController.new,
    );

class PremiumGateController extends Notifier<PremiumEntitlement> {
  @override
  PremiumEntitlement build() {
    final auth = ref.watch(authGateControllerProvider);
    final entitlement = ref.watch(entitlementRepositoryProvider).current;
    // Preserve the explicit mock seam used by UI and ad regression tests.
    if (entitlement.source == EntitlementSource.localMock &&
        entitlement.isPremium) {
      return entitlement;
    }
    if (auth.status != AuthStatus.signedIn) {
      return const PremiumEntitlement.free();
    }
    return entitlement;
  }

  bool canUse(PremiumFeature feature) =>
      ref.read(premiumFeatureGateProvider).canAccess(state, feature);

  void setMockEntitlement(PremiumEntitlement entitlement) {
    ref.read(entitlementRepositoryProvider).setEntitlement(entitlement);
    state = entitlement;
  }
}

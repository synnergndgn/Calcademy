import 'package:calcademy/app/premium/entitlement_repository.dart';
import 'package:calcademy/app/premium/local_entitlement_repository.dart';
import 'package:calcademy/app/premium/premium_entitlement.dart';
import 'package:calcademy/app/premium/premium_feature.dart';
import 'package:calcademy/app/premium/premium_feature_gate.dart';
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
  PremiumEntitlement build() =>
      ref.watch(entitlementRepositoryProvider).current;

  bool canUse(PremiumFeature feature) =>
      ref.read(premiumFeatureGateProvider).canAccess(state, feature);

  void setMockEntitlement(PremiumEntitlement entitlement) {
    ref.read(entitlementRepositoryProvider).setEntitlement(entitlement);
    state = entitlement;
  }
}

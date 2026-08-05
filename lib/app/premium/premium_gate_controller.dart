import 'package:calcademy/app/auth/auth_gate_controller.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/premium/backend_entitlement_repository.dart';
import 'package:calcademy/app/premium/entitlement_repository.dart';
import 'package:calcademy/app/premium/local_entitlement_repository.dart';
import 'package:calcademy/app/premium/premium_entitlement.dart';
import 'package:calcademy/app/premium/premium_feature.dart';
import 'package:calcademy/app/premium/premium_feature_gate.dart';
import 'package:calcademy/app/premium/premium_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? LocalEntitlementRepository()
      : BackendEntitlementRepository(client);
});

final premiumFeatureGateProvider = Provider<PremiumFeatureGate>(
  (ref) => const PremiumFeatureGate(),
);

final premiumGateControllerProvider =
    NotifierProvider<PremiumGateController, PremiumEntitlement>(
      PremiumGateController.new,
    );

class PremiumGateController extends Notifier<PremiumEntitlement> {
  String? _lastRefreshUserId;

  @override
  PremiumEntitlement build() {
    final auth = ref.watch(authGateControllerProvider);
    final repository = ref.watch(entitlementRepositoryProvider);
    final entitlement = repository.current;
    // Preserve the explicit mock seam used by UI and ad regression tests.
    if (entitlement.source == EntitlementSource.localMock &&
        entitlement.isPremium) {
      return entitlement;
    }
    if (auth.status != AuthStatus.signedIn) {
      _lastRefreshUserId = null;
      return const PremiumEntitlement.free();
    }
    final userId = auth.user?.id;
    if (repository is BackendEntitlementRepository &&
        userId != null &&
        _lastRefreshUserId != userId) {
      _lastRefreshUserId = userId;
      Future<void>.microtask(refresh);
    }
    return entitlement;
  }

  Future<void> refresh() async {
    if (!ref.mounted) return;
    final auth = ref.read(authGateControllerProvider);
    final userId = auth.user?.id;
    if (auth.status != AuthStatus.signedIn || userId == null) {
      state = const PremiumEntitlement.free();
      return;
    }
    final entitlement = await ref.read(entitlementRepositoryProvider).refresh();
    if (!ref.mounted) return;
    final currentAuth = ref.read(authGateControllerProvider);
    if (currentAuth.status == AuthStatus.signedIn &&
        currentAuth.user?.id == userId) {
      state = entitlement;
    }
  }

  bool canUse(PremiumFeature feature) =>
      ref.read(premiumFeatureGateProvider).canAccess(state, feature);

  void setMockEntitlement(PremiumEntitlement entitlement) {
    ref.read(entitlementRepositoryProvider).setEntitlement(entitlement);
    state = entitlement;
  }
}

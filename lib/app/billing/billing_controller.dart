import 'dart:async';

import 'package:calcademy/app/auth/auth_gate_controller.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/billing/billing_error.dart';
import 'package:calcademy/app/billing/billing_product_id.dart';
import 'package:calcademy/app/billing/billing_purchase.dart';
import 'package:calcademy/app/billing/billing_purchase_status.dart';
import 'package:calcademy/app/billing/billing_repository.dart';
import 'package:calcademy/app/billing/billing_state.dart';
import 'package:calcademy/app/billing/play_billing_repository.dart';
import 'package:calcademy/app/premium/entitlement_sync_service.dart';
import 'package:calcademy/app/premium/purchase_validation_request.dart';
import 'package:calcademy/app/premium/purchase_validation_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  final repository = PlayBillingRepository();
  ref.onDispose(() => unawaited(repository.dispose()));
  return repository;
});

final entitlementSyncServiceProvider = Provider<EntitlementSyncService>(
  (ref) => const PendingEntitlementSyncService(),
);

final billingControllerProvider =
    NotifierProvider<BillingController, BillingState>(BillingController.new);

class BillingController extends Notifier<BillingState> {
  StreamSubscription<BillingPurchase>? _subscription;
  bool _initialized = false;
  bool _hasBuilt = false;

  BillingRepository get _repository => ref.read(billingRepositoryProvider);

  @override
  BillingState build() {
    final auth = ref.watch(authGateControllerProvider);
    final isSignedIn = auth.status == AuthStatus.signedIn;
    if (_hasBuilt) return state.copyWith(isSignedIn: isSignedIn);
    _hasBuilt = true;
    _subscription?.cancel();
    _subscription = ref
        .watch(billingRepositoryProvider)
        .purchaseUpdates
        .listen(_handlePurchase, onError: _handleStreamError);
    ref.onDispose(() => _subscription?.cancel());
    return BillingState.unavailable(isSignedIn: isSignedIn);
  }

  Future<void> initialize({bool force = false}) async {
    if (_initialized && !force) return;
    _initialized = true;
    state = state.copyWith(
      status: BillingStatus.loading,
      clearError: true,
      clearPurchase: true,
      clearValidation: true,
    );
    try {
      if (!await _repository.isAvailable()) {
        state = state.copyWith(status: BillingStatus.unavailable);
        return;
      }
      final products = await _repository.queryProducts();
      state = state.copyWith(
        status: BillingStatus.available,
        products: products,
        clearError: true,
      );
    } on BillingException catch (error) {
      state = state.copyWith(
        status: BillingStatus.error,
        errorMessage: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: BillingStatus.error,
        errorMessage: 'Billing could not be initialized.',
      );
    }
  }

  Future<bool> subscribe({String? productId}) async {
    if (!state.isSignedIn) {
      state = state.copyWith(errorMessage: 'signInToSubscribe');
      return false;
    }
    final id = productId ?? state.primaryProduct?.id;
    if (state.status != BillingStatus.available || id == null) return false;
    state = state.copyWith(
      status: BillingStatus.purchasePending,
      clearError: true,
      clearValidation: true,
    );
    try {
      await _repository.purchase(id);
      return true;
    } on BillingException catch (error) {
      state = state.copyWith(
        status: BillingStatus.error,
        errorMessage: error.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: BillingStatus.error,
        errorMessage: 'Purchase could not be started.',
      );
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    if (!state.isSignedIn || !state.isAvailable) return false;
    state = state.copyWith(status: BillingStatus.loading, clearError: true);
    try {
      await _repository.restorePurchases();
      return true;
    } on BillingException catch (error) {
      state = state.copyWith(
        status: BillingStatus.error,
        errorMessage: error.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: BillingStatus.error,
        errorMessage: 'Purchases could not be restored.',
      );
      return false;
    }
  }

  Future<void> _handlePurchase(BillingPurchase purchase) async {
    switch (purchase.status) {
      case BillingPurchaseStatus.pending:
        state = state.copyWith(
          status: BillingStatus.purchasePending,
          purchase: purchase,
          clearError: true,
        );
      case BillingPurchaseStatus.error:
        state = state.copyWith(
          status: BillingStatus.error,
          purchase: purchase,
          errorMessage: purchase.errorMessage ?? 'Purchase failed.',
        );
      case BillingPurchaseStatus.canceled:
        state = state.copyWith(
          status: BillingStatus.available,
          purchase: purchase,
          clearError: true,
        );
      case BillingPurchaseStatus.purchased:
      case BillingPurchaseStatus.restored:
        await _validateAndComplete(purchase);
    }
  }

  Future<void> _validateAndComplete(BillingPurchase purchase) async {
    state = state.copyWith(
      status: purchase.status == BillingPurchaseStatus.restored
          ? BillingStatus.restored
          : BillingStatus.purchased,
      purchase: purchase,
      validationResult: const PurchaseValidationResult.pending(),
      clearError: true,
    );
    PurchaseValidationResult result;
    final auth = ref.read(authGateControllerProvider);
    if (auth.status != AuthStatus.signedIn ||
        auth.user == null ||
        purchase.purchaseToken.isEmpty) {
      result = const PurchaseValidationResult.unsupported();
    } else {
      try {
        result = await ref
            .read(entitlementSyncServiceProvider)
            .validateAndSync(
              PurchaseValidationRequest(
                userId: auth.user!.id,
                productId: purchase.productId,
                purchaseToken: purchase.purchaseToken,
                platform: purchase.platform,
              ),
            );
      } catch (_) {
        result = const PurchaseValidationResult(
          status: PurchaseValidationStatus.error,
          messageKey: 'purchaseValidationRequired',
        );
      }
    }
    state = state.copyWith(validationResult: result);
    if (purchase.pendingCompletePurchase) {
      try {
        await _repository.completePurchase(purchase);
      } on BillingException catch (error) {
        state = state.copyWith(
          status: BillingStatus.error,
          errorMessage: error.message,
        );
      }
    }
  }

  void _handleStreamError(Object _) {
    state = state.copyWith(
      status: BillingStatus.error,
      errorMessage: 'Purchase updates are unavailable.',
    );
  }

  String get productId =>
      state.primaryProduct?.id ?? BillingProductId.premiumMonthly;
}

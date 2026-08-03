import 'package:calcademy/app/billing/billing_product.dart';
import 'package:calcademy/app/billing/billing_purchase.dart';
import 'package:calcademy/app/premium/purchase_validation_result.dart';

enum BillingStatus {
  unavailable,
  loading,
  available,
  purchasePending,
  purchased,
  restored,
  error,
}

class BillingState {
  const BillingState({
    required this.status,
    required this.isSignedIn,
    this.products = const [],
    this.purchase,
    this.validationResult,
    this.errorMessage,
  });

  const BillingState.unavailable({required bool isSignedIn})
    : this(status: BillingStatus.unavailable, isSignedIn: isSignedIn);

  final BillingStatus status;
  final bool isSignedIn;
  final List<BillingProduct> products;
  final BillingPurchase? purchase;
  final PurchaseValidationResult? validationResult;
  final String? errorMessage;

  BillingProduct? get primaryProduct => products.firstOrNull;

  bool get isAvailable => switch (status) {
    BillingStatus.available ||
    BillingStatus.purchasePending ||
    BillingStatus.purchased ||
    BillingStatus.restored => true,
    BillingStatus.unavailable ||
    BillingStatus.loading ||
    BillingStatus.error => false,
  };

  bool get isPurchasePending => status == BillingStatus.purchasePending;

  bool get isPendingValidation =>
      validationResult?.status == PurchaseValidationStatus.pending ||
      validationResult?.status == PurchaseValidationStatus.unsupported;

  BillingState copyWith({
    BillingStatus? status,
    bool? isSignedIn,
    List<BillingProduct>? products,
    BillingPurchase? purchase,
    bool clearPurchase = false,
    PurchaseValidationResult? validationResult,
    bool clearValidation = false,
    String? errorMessage,
    bool clearError = false,
  }) => BillingState(
    status: status ?? this.status,
    isSignedIn: isSignedIn ?? this.isSignedIn,
    products: products ?? this.products,
    purchase: clearPurchase ? null : purchase ?? this.purchase,
    validationResult: clearValidation
        ? null
        : validationResult ?? this.validationResult,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

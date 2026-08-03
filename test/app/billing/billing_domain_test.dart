import 'package:calcademy/app/billing/billing_product.dart';
import 'package:calcademy/app/billing/billing_product_id.dart';
import 'package:calcademy/app/billing/billing_purchase.dart';
import 'package:calcademy/app/billing/billing_purchase_status.dart';
import 'package:calcademy/app/billing/billing_state.dart';
import 'package:calcademy/app/premium/purchase_validation_request.dart';
import 'package:calcademy/app/premium/purchase_validation_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BillingProduct represents a subscription', () {
    const product = BillingProduct(
      id: BillingProductId.premiumMonthly,
      title: 'Monthly',
      description: 'Premium',
      price: r'$2.99',
      currencyCode: 'USD',
      rawPrice: 2.99,
    );
    expect(product.id, 'calcademy_premium_monthly');
    expect(product.type, BillingProductType.subscription);
    expect(product.currencyCode, 'USD');
  });

  test('BillingPurchase models all lifecycle statuses', () {
    expect(
      BillingPurchaseStatus.values,
      containsAll([
        BillingPurchaseStatus.pending,
        BillingPurchaseStatus.purchased,
        BillingPurchaseStatus.restored,
        BillingPurchaseStatus.canceled,
        BillingPurchaseStatus.error,
      ]),
    );
    const purchase = BillingPurchase(
      productId: BillingProductId.premiumMonthly,
      purchaseToken: 'memory-only',
      status: BillingPurchaseStatus.purchased,
      platform: 'android',
      pendingCompletePurchase: true,
    );
    expect(purchase.pendingCompletePurchase, isTrue);
  });

  test('BillingState exposes loading, available, and validation states', () {
    const initial = BillingState.unavailable(isSignedIn: true);
    final loading = initial.copyWith(status: BillingStatus.loading);
    final available = loading.copyWith(
      status: BillingStatus.available,
      products: const [
        BillingProduct(
          id: BillingProductId.premiumMonthly,
          title: 'Monthly',
          description: 'Premium',
          price: r'$2.99',
        ),
      ],
    );
    final validating = available.copyWith(
      status: BillingStatus.purchased,
      validationResult: const PurchaseValidationResult.pending(),
    );
    expect(loading.status, BillingStatus.loading);
    expect(available.primaryProduct?.id, BillingProductId.premiumMonthly);
    expect(validating.isPendingValidation, isTrue);
  });

  test('product IDs and validation request/result remain explicit', () {
    expect(BillingProductId.active, {BillingProductId.premiumMonthly});
    expect(
      BillingProductId.active,
      isNot(contains(BillingProductId.premiumYearly)),
    );
    const request = PurchaseValidationRequest(
      userId: 'student',
      productId: BillingProductId.premiumMonthly,
      purchaseToken: 'memory-only',
      platform: 'android',
    );
    const result = PurchaseValidationResult.unsupported();
    expect(request.productId, BillingProductId.premiumMonthly);
    expect(result.status, PurchaseValidationStatus.unsupported);
    expect(result.grantsPremium, isFalse);
  });
}

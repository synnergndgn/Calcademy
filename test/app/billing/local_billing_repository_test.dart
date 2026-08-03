import 'package:calcademy/app/billing/billing_product_id.dart';
import 'package:calcademy/app/billing/billing_purchase_status.dart';
import 'package:calcademy/app/billing/local_billing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'unavailable local repository is safe and returns no products',
    () async {
      final repository = LocalBillingRepository(available: false);
      addTearDown(repository.dispose);
      expect(await repository.isAvailable(), isFalse);
      expect(await repository.queryProducts(), isEmpty);
    },
  );

  test('available repository returns the monthly mock product', () async {
    final repository = LocalBillingRepository();
    addTearDown(repository.dispose);
    final products = await repository.queryProducts();
    expect(products.single.id, BillingProductId.premiumMonthly);
    expect(products.single.price, isNotEmpty);
  });

  test('purchase emits pending then success and can be completed', () async {
    final repository = LocalBillingRepository();
    addTearDown(repository.dispose);
    final updates = repository.purchaseUpdates.take(2).toList();
    await repository.purchase(BillingProductId.premiumMonthly);
    final purchases = await updates;
    expect(purchases.map((purchase) => purchase.status), [
      BillingPurchaseStatus.pending,
      BillingPurchaseStatus.purchased,
    ]);
    await repository.completePurchase(purchases.last);
    expect(repository.completedPurchaseCount, 1);
  });

  test('purchase supports pending and error outcomes', () async {
    final pending = LocalBillingRepository(
      outcome: LocalPurchaseOutcome.pending,
    );
    addTearDown(pending.dispose);
    final pendingUpdate = pending.purchaseUpdates.first;
    await pending.purchase(BillingProductId.premiumMonthly);
    expect((await pendingUpdate).status, BillingPurchaseStatus.pending);

    final failed = LocalBillingRepository(outcome: LocalPurchaseOutcome.error);
    addTearDown(failed.dispose);
    final failedUpdates = failed.purchaseUpdates.take(2).toList();
    await failed.purchase(BillingProductId.premiumMonthly);
    expect((await failedUpdates).last.status, BillingPurchaseStatus.error);
  });

  test('restore emits a restored purchase', () async {
    final repository = LocalBillingRepository();
    addTearDown(repository.dispose);
    final update = repository.purchaseUpdates.first;
    await repository.restorePurchases();
    expect((await update).status, BillingPurchaseStatus.restored);
  });
}

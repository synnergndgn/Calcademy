import 'package:calcademy/app/billing/billing_product.dart';
import 'package:calcademy/app/billing/billing_purchase.dart';

abstract interface class BillingRepository {
  Future<bool> isAvailable();

  Future<List<BillingProduct>> queryProducts();

  Future<void> purchase(String productId);

  Future<void> restorePurchases();

  Stream<BillingPurchase> get purchaseUpdates;

  Future<void> completePurchase(BillingPurchase purchase);

  Future<void> dispose();
}

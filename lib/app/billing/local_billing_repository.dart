import 'dart:async';

import 'package:calcademy/app/billing/billing_error.dart';
import 'package:calcademy/app/billing/billing_product.dart';
import 'package:calcademy/app/billing/billing_product_id.dart';
import 'package:calcademy/app/billing/billing_purchase.dart';
import 'package:calcademy/app/billing/billing_purchase_status.dart';
import 'package:calcademy/app/billing/billing_repository.dart';

enum LocalPurchaseOutcome { success, pending, error, canceled }

class LocalBillingRepository implements BillingRepository {
  LocalBillingRepository({
    this.available = true,
    this.outcome = LocalPurchaseOutcome.success,
    List<BillingProduct>? products,
  }) : _products = products ?? const [mockMonthlyProduct];

  static const mockMonthlyProduct = BillingProduct(
    id: BillingProductId.premiumMonthly,
    title: 'Calcademy Premium Monthly',
    description: 'Remove ads and unlock future Premium capabilities.',
    price: r'$2.99',
    currencyCode: 'USD',
    rawPrice: 2.99,
  );

  final bool available;
  final LocalPurchaseOutcome outcome;
  final List<BillingProduct> _products;
  final _updates = StreamController<BillingPurchase>.broadcast();
  int completedPurchaseCount = 0;

  @override
  Stream<BillingPurchase> get purchaseUpdates => _updates.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<BillingProduct>> queryProducts() async {
    if (!available) return const [];
    return List.unmodifiable(_products);
  }

  @override
  Future<void> purchase(String productId) async {
    if (!available) {
      throw const BillingException('unavailable', 'Billing is unavailable.');
    }
    if (!_products.any((product) => product.id == productId)) {
      throw const BillingException('product-not-found', 'Product not found.');
    }
    _updates.add(_purchase(productId, BillingPurchaseStatus.pending));
    await Future<void>.delayed(Duration.zero);
    switch (outcome) {
      case LocalPurchaseOutcome.success:
        _updates.add(_purchase(productId, BillingPurchaseStatus.purchased));
      case LocalPurchaseOutcome.pending:
        break;
      case LocalPurchaseOutcome.error:
        _updates.add(
          _purchase(
            productId,
            BillingPurchaseStatus.error,
            errorMessage: 'Local test purchase failed.',
          ),
        );
      case LocalPurchaseOutcome.canceled:
        _updates.add(_purchase(productId, BillingPurchaseStatus.canceled));
    }
  }

  @override
  Future<void> restorePurchases() async {
    if (!available) {
      throw const BillingException('unavailable', 'Billing is unavailable.');
    }
    _updates.add(
      _purchase(
        BillingProductId.premiumMonthly,
        BillingPurchaseStatus.restored,
      ),
    );
  }

  @override
  Future<void> completePurchase(BillingPurchase purchase) async {
    if (purchase.pendingCompletePurchase) completedPurchaseCount++;
  }

  BillingPurchase _purchase(
    String productId,
    BillingPurchaseStatus status, {
    String? errorMessage,
  }) => BillingPurchase(
    productId: productId,
    purchaseToken: status == BillingPurchaseStatus.pending
        ? ''
        : 'local-verification-value',
    status: status,
    transactionDate: DateTime.now(),
    isAcknowledged: false,
    platform: 'local-test',
    pendingCompletePurchase:
        status == BillingPurchaseStatus.purchased ||
        status == BillingPurchaseStatus.restored,
    errorMessage: errorMessage,
  );

  @override
  Future<void> dispose() => _updates.close();
}

import 'dart:async';

import 'package:calcademy/app/billing/billing_error.dart';
import 'package:calcademy/app/billing/billing_product.dart';
import 'package:calcademy/app/billing/billing_product_id.dart';
import 'package:calcademy/app/billing/billing_purchase.dart';
import 'package:calcademy/app/billing/billing_purchase_status.dart';
import 'package:calcademy/app/billing/billing_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PlayBillingRepository implements BillingRepository {
  PlayBillingRepository({InAppPurchase? store})
    : _store = store ?? InAppPurchase.instance {
    if (isSupportedPlatform) {
      _subscription = _store.purchaseStream.listen(
        _onPurchaseDetails,
        onError: _onStreamError,
      );
    }
  }

  final InAppPurchase _store;
  final _updates = StreamController<BillingPurchase>.broadcast();
  final Map<String, ProductDetails> _products = {};
  final Map<String, PurchaseDetails> _pendingCompletion = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Stream<BillingPurchase> get purchaseUpdates => _updates.stream;

  @override
  Future<bool> isAvailable() async {
    if (!isSupportedPlatform) return false;
    try {
      return await _store.isAvailable();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<BillingProduct>> queryProducts() async {
    if (!await isAvailable()) return const [];
    try {
      final response = await _store.queryProductDetails(
        BillingProductId.active,
      );
      if (response.error case final error?) {
        throw BillingException(error.code, error.message);
      }
      _products
        ..clear()
        ..addEntries(
          response.productDetails.map(
            (product) => MapEntry(product.id, product),
          ),
        );
      return response.productDetails
          .map(
            (product) => BillingProduct(
              id: product.id,
              title: product.title,
              description: product.description,
              price: product.price,
              currencyCode: product.currencyCode,
              rawPrice: product.rawPrice,
            ),
          )
          .toList(growable: false);
    } on BillingException {
      rethrow;
    } catch (_) {
      throw const BillingException(
        'product-query-failed',
        'Products could not be loaded.',
      );
    }
  }

  @override
  Future<void> purchase(String productId) async {
    if (!await isAvailable()) {
      throw const BillingException('unavailable', 'Billing is unavailable.');
    }
    var product = _products[productId];
    if (product == null) {
      await queryProducts();
      product = _products[productId];
    }
    if (product == null) {
      throw const BillingException('product-not-found', 'Product not found.');
    }
    try {
      final launched = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!launched) {
        throw const BillingException(
          'purchase-not-launched',
          'Google Play did not launch the purchase flow.',
        );
      }
    } on BillingException {
      rethrow;
    } catch (_) {
      throw const BillingException(
        'purchase-launch-failed',
        'The purchase flow could not be started.',
      );
    }
  }

  @override
  Future<void> restorePurchases() async {
    if (!await isAvailable()) {
      throw const BillingException('unavailable', 'Billing is unavailable.');
    }
    try {
      await _store.restorePurchases();
    } catch (_) {
      throw const BillingException(
        'restore-failed',
        'Purchases could not be restored.',
      );
    }
  }

  @override
  Future<void> completePurchase(BillingPurchase purchase) async {
    if (!purchase.pendingCompletePurchase) return;
    final details = _pendingCompletion.remove(_keyFor(purchase));
    if (details == null) return;
    try {
      await _store.completePurchase(details);
    } catch (_) {
      _pendingCompletion[_keyFor(purchase)] = details;
      throw const BillingException(
        'complete-purchase-failed',
        'The purchase could not be completed.',
      );
    }
  }

  void _onPurchaseDetails(List<PurchaseDetails> detailsList) {
    for (final details in detailsList) {
      final purchase = _toDomain(details);
      if (details.pendingCompletePurchase) {
        _pendingCompletion[_keyFor(purchase)] = details;
      }
      _updates.add(purchase);
    }
  }

  void _onStreamError(Object _) {
    _updates.add(
      const BillingPurchase(
        productId: '',
        purchaseToken: '',
        status: BillingPurchaseStatus.error,
        platform: 'android',
        pendingCompletePurchase: false,
        errorMessage: 'Google Play purchase updates are unavailable.',
      ),
    );
  }

  BillingPurchase _toDomain(PurchaseDetails details) => BillingPurchase(
    productId: details.productID,
    purchaseToken: details.verificationData.serverVerificationData,
    status: switch (details.status) {
      PurchaseStatus.pending => BillingPurchaseStatus.pending,
      PurchaseStatus.purchased => BillingPurchaseStatus.purchased,
      PurchaseStatus.restored => BillingPurchaseStatus.restored,
      PurchaseStatus.canceled => BillingPurchaseStatus.canceled,
      PurchaseStatus.error => BillingPurchaseStatus.error,
    },
    transactionDate: _parseTransactionDate(details.transactionDate),
    platform: 'android',
    pendingCompletePurchase: details.pendingCompletePurchase,
    errorMessage: details.error?.message,
  );

  DateTime? _parseTransactionDate(String? value) {
    final milliseconds = int.tryParse(value ?? '');
    return milliseconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  String _keyFor(BillingPurchase purchase) =>
      '${purchase.productId}:${purchase.transactionDate?.millisecondsSinceEpoch ?? 0}';

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _updates.close();
  }
}

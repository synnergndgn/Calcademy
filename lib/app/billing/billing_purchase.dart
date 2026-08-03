import 'package:calcademy/app/billing/billing_purchase_status.dart';

class BillingPurchase {
  const BillingPurchase({
    required this.productId,
    required this.purchaseToken,
    required this.status,
    required this.platform,
    required this.pendingCompletePurchase,
    this.transactionDate,
    this.isAcknowledged,
    this.errorMessage,
  });

  final String productId;
  final String purchaseToken;
  final BillingPurchaseStatus status;
  final DateTime? transactionDate;
  final bool? isAcknowledged;
  final String platform;
  final bool pendingCompletePurchase;
  final String? errorMessage;
}

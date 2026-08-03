class PurchaseValidationRequest {
  const PurchaseValidationRequest({
    required this.userId,
    required this.productId,
    required this.purchaseToken,
    required this.platform,
  });

  final String userId;
  final String productId;
  final String purchaseToken;
  final String platform;
}

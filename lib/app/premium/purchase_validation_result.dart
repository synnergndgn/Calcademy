enum PurchaseValidationStatus { pending, active, rejected, unsupported, error }

class PurchaseValidationResult {
  const PurchaseValidationResult({
    required this.status,
    required this.messageKey,
  });

  const PurchaseValidationResult.pending()
    : this(
        status: PurchaseValidationStatus.pending,
        messageKey: 'validatingPurchase',
      );

  const PurchaseValidationResult.unsupported()
    : this(
        status: PurchaseValidationStatus.unsupported,
        messageKey: 'purchaseValidationRequired',
      );

  final PurchaseValidationStatus status;
  final String messageKey;

  bool get grantsPremium => status == PurchaseValidationStatus.active;
}

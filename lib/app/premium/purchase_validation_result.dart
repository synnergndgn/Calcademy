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

  const PurchaseValidationResult.active()
    : this(
        status: PurchaseValidationStatus.active,
        messageKey: 'premiumStatusSyncedFromAccount',
      );

  const PurchaseValidationResult.rejected()
    : this(
        status: PurchaseValidationStatus.rejected,
        messageKey: 'purchaseValidationRejected',
      );

  const PurchaseValidationResult.unsupported()
    : this(
        status: PurchaseValidationStatus.unsupported,
        messageKey: 'backendValidationPending',
      );

  const PurchaseValidationResult.error()
    : this(
        status: PurchaseValidationStatus.error,
        messageKey: 'purchaseValidationUnavailable',
      );

  final PurchaseValidationStatus status;
  final String messageKey;

  bool get grantsPremium => status == PurchaseValidationStatus.active;
}

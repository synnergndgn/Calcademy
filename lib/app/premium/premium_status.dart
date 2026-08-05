enum PremiumStatus {
  free,
  premiumActive,
  premiumGracePeriod,
  pendingValidation,
  premiumExpired,
  premiumCanceled,
  premiumRevoked,
  unknown,
}

enum EntitlementSource { localMock, playBilling, backend }

import 'package:calcademy/app/premium/premium_feature.dart';
import 'package:calcademy/app/premium/premium_status.dart';

class PremiumEntitlement {
  const PremiumEntitlement({
    required this.status,
    required this.activeFeatures,
    required this.source,
    this.expiresAt,
    this.backendSource,
    this.productId,
    this.cancelAtPeriodEnd = false,
  });

  const PremiumEntitlement.free({
    this.status = PremiumStatus.free,
    this.source = EntitlementSource.localMock,
    this.expiresAt,
    this.backendSource,
    this.productId,
    this.cancelAtPeriodEnd = false,
  }) : activeFeatures = const {},
       assert(status != PremiumStatus.premiumActive),
       assert(status != PremiumStatus.premiumGracePeriod);

  const PremiumEntitlement.mockPremium({this.expiresAt})
    : status = PremiumStatus.premiumActive,
      activeFeatures = const {
        PremiumFeature.removeAds,
        PremiumFeature.geminiAssistant,
        PremiumFeature.cameraSolver,
        PremiumFeature.higherDailyLimits,
      },
      source = EntitlementSource.localMock,
      backendSource = null,
      productId = null,
      cancelAtPeriodEnd = false;

  final PremiumStatus status;
  final Set<PremiumFeature> activeFeatures;
  final DateTime? expiresAt;
  final EntitlementSource source;
  final String? backendSource;
  final String? productId;
  final bool cancelAtPeriodEnd;

  bool get isPremium =>
      (status == PremiumStatus.premiumActive ||
          status == PremiumStatus.premiumGracePeriod) &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  bool canUse(PremiumFeature feature) =>
      isPremium && activeFeatures.contains(feature);
}

import 'package:calcademy/app/premium/premium_feature.dart';
import 'package:calcademy/app/premium/premium_status.dart';

class PremiumEntitlement {
  const PremiumEntitlement({
    required this.status,
    required this.activeFeatures,
    required this.source,
    this.expiresAt,
  });

  const PremiumEntitlement.free()
    : status = PremiumStatus.free,
      activeFeatures = const {},
      source = EntitlementSource.localMock,
      expiresAt = null;

  const PremiumEntitlement.mockPremium({this.expiresAt})
    : status = PremiumStatus.premiumActive,
      activeFeatures = const {
        PremiumFeature.removeAds,
        PremiumFeature.geminiAssistant,
        PremiumFeature.cameraSolver,
        PremiumFeature.higherDailyLimits,
      },
      source = EntitlementSource.localMock;

  final PremiumStatus status;
  final Set<PremiumFeature> activeFeatures;
  final DateTime? expiresAt;
  final EntitlementSource source;

  bool get isPremium =>
      status == PremiumStatus.premiumActive &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  bool canUse(PremiumFeature feature) =>
      isPremium && activeFeatures.contains(feature);
}

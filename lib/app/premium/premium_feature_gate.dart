import 'package:calcademy/app/premium/premium_entitlement.dart';
import 'package:calcademy/app/premium/premium_feature.dart';

class PremiumFeatureGate {
  const PremiumFeatureGate();

  bool canAccess(PremiumEntitlement entitlement, PremiumFeature feature) =>
      entitlement.canUse(feature);
}

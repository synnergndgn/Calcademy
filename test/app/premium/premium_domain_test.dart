import 'package:calcademy/app/premium/premium_entitlement.dart';
import 'package:calcademy/app/premium/premium_feature.dart';
import 'package:calcademy/app/premium/premium_feature_gate.dart';
import 'package:calcademy/app/premium/premium_status.dart';
import 'package:calcademy/app/premium/usage_limit.dart';
import 'package:calcademy/app/premium/usage_quota.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('free entitlement is the safe default', () {
    const entitlement = PremiumEntitlement.free();
    expect(entitlement.status, PremiumStatus.free);
    expect(entitlement.isPremium, isFalse);
    for (final feature in PremiumFeature.values) {
      expect(entitlement.canUse(feature), isFalse);
    }
  });

  test('mock premium entitlement unlocks defined premium features', () {
    const entitlement = PremiumEntitlement.mockPremium();
    expect(entitlement.isPremium, isTrue);
    expect(entitlement.canUse(PremiumFeature.removeAds), isTrue);
    expect(entitlement.canUse(PremiumFeature.geminiAssistant), isTrue);
    expect(entitlement.canUse(PremiumFeature.cameraSolver), isTrue);
    expect(entitlement.canUse(PremiumFeature.higherDailyLimits), isTrue);
  });

  test('usage quota clamps remaining uses at zero', () {
    final quota = UsageQuota(
      feature: UsageFeature.geminiAssistant,
      dailyLimit: 20,
      usedToday: 23,
      resetsAt: DateTime(2026, 8, 4),
    );
    expect(quota.remainingToday, 0);
    expect(quota.canUse, isFalse);
  });

  test('PremiumFeatureGate blocks locked features', () {
    const gate = PremiumFeatureGate();
    expect(
      gate.canAccess(
        const PremiumEntitlement.free(),
        PremiumFeature.cameraSolver,
      ),
      isFalse,
    );
    expect(
      gate.canAccess(
        const PremiumEntitlement.mockPremium(),
        PremiumFeature.cameraSolver,
      ),
      isTrue,
    );
  });
}

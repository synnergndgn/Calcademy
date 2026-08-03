import 'package:calcademy/app/premium/local_usage_limit_service.dart';
import 'package:calcademy/app/premium/premium_plan.dart';
import 'package:calcademy/app/premium/usage_limit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('free and premium placeholder limits match the product model', () {
    final service = LocalUsageLimitService(
      clock: () => DateTime(2026, 8, 3, 10),
    );
    expect(
      service
          .getQuota(UsageFeature.localAssistant, PremiumPlan.free)
          .isUnlimited,
      isTrue,
    );
    expect(
      service
          .getQuota(UsageFeature.geminiAssistant, PremiumPlan.free)
          .dailyLimit,
      0,
    );
    expect(
      service.getQuota(UsageFeature.cameraSolver, PremiumPlan.free).dailyLimit,
      0,
    );
    expect(
      service
          .getQuota(UsageFeature.geminiAssistant, PremiumPlan.premium)
          .dailyLimit,
      20,
    );
    expect(
      service
          .getQuota(UsageFeature.cameraSolver, PremiumPlan.premium)
          .dailyLimit,
      10,
    );
  });

  test('recordUse updates only in-memory daily quota', () {
    final service = LocalUsageLimitService(
      clock: () => DateTime(2026, 8, 3, 10),
    );
    service.recordUse(UsageFeature.geminiAssistant);
    final quota = service.getQuota(
      UsageFeature.geminiAssistant,
      PremiumPlan.premium,
    );
    expect(quota.usedToday, 1);
    expect(quota.remainingToday, 19);
  });
}

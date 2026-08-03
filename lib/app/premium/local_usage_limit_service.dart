import 'package:calcademy/app/premium/premium_plan.dart';
import 'package:calcademy/app/premium/usage_limit.dart';
import 'package:calcademy/app/premium/usage_limit_service.dart';
import 'package:calcademy/app/premium/usage_quota.dart';

class LocalUsageLimitService implements UsageLimitService {
  LocalUsageLimitService({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<UsageFeature, int> _usage = {};
  DateTime? _usageDay;

  @override
  bool canUse(UsageFeature feature, PremiumPlan plan) =>
      getQuota(feature, plan).canUse;

  @override
  UsageQuota getQuota(UsageFeature feature, PremiumPlan plan) {
    _resetIfNeeded();
    final now = _clock();
    return UsageQuota(
      feature: feature,
      dailyLimit: _limitFor(feature, plan),
      usedToday: _usage[feature] ?? 0,
      resetsAt: DateTime(now.year, now.month, now.day + 1),
    );
  }

  @override
  void recordUse(UsageFeature feature) {
    _resetIfNeeded();
    _usage[feature] = (_usage[feature] ?? 0) + 1;
  }

  int? _limitFor(UsageFeature feature, PremiumPlan plan) =>
      switch ((feature, plan)) {
        (UsageFeature.localAssistant, _) => null,
        (UsageFeature.geminiAssistant, PremiumPlan.free) => 0,
        (UsageFeature.cameraSolver, PremiumPlan.free) => 0,
        (UsageFeature.geminiAssistant, PremiumPlan.premium) => 20,
        (UsageFeature.cameraSolver, PremiumPlan.premium) => 10,
      };

  void _resetIfNeeded() {
    final now = _clock();
    final day = DateTime(now.year, now.month, now.day);
    if (_usageDay == day) return;
    _usageDay = day;
    _usage.clear();
  }
}

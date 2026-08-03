import 'package:calcademy/app/premium/premium_plan.dart';
import 'package:calcademy/app/premium/usage_limit.dart';
import 'package:calcademy/app/premium/usage_quota.dart';

abstract interface class UsageLimitService {
  bool canUse(UsageFeature feature, PremiumPlan plan);

  void recordUse(UsageFeature feature);

  UsageQuota getQuota(UsageFeature feature, PremiumPlan plan);
}

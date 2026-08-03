import 'dart:math' as math;

import 'package:calcademy/app/premium/usage_limit.dart';

class UsageQuota {
  const UsageQuota({
    required this.feature,
    required this.dailyLimit,
    required this.usedToday,
    required this.resetsAt,
  });

  final UsageFeature feature;
  final int? dailyLimit;
  final int usedToday;
  final DateTime resetsAt;

  bool get isUnlimited => dailyLimit == null;

  int? get remainingToday => dailyLimit == null
      ? null
      : math.max(0, dailyLimit! - math.max(0, usedToday));

  bool get canUse => isUnlimited || remainingToday! > 0;
}

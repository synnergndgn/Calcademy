enum UsageFeature { localAssistant, geminiAssistant, cameraSolver }

class UsageLimit {
  const UsageLimit({required this.feature, required this.dailyLimit});

  final UsageFeature feature;

  /// `null` means unlimited. Zero means unavailable for the selected plan.
  final int? dailyLimit;
}

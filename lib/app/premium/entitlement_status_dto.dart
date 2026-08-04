import 'package:calcademy/app/premium/premium_entitlement.dart';
import 'package:calcademy/app/premium/premium_feature.dart';
import 'package:calcademy/app/premium/premium_status.dart';

class EntitlementStatusDto {
  const EntitlementStatusDto({
    required this.isPremiumActive,
    required this.status,
    required this.source,
    required this.cancelAtPeriodEnd,
    this.productId,
    this.currentPeriodEnd,
  });

  const EntitlementStatusDto.inactive()
    : this(
        isPremiumActive: false,
        status: 'inactive',
        source: 'unknown',
        cancelAtPeriodEnd: false,
      );

  factory EntitlementStatusDto.fromResponse(Object? response) {
    final Object? value = switch (response) {
      final List<Object?> rows when rows.isNotEmpty => rows.first,
      _ => response,
    };
    if (value is! Map) return const EntitlementStatusDto.inactive();
    final json = value.map((key, value) => MapEntry(key.toString(), value));
    return EntitlementStatusDto(
      isPremiumActive: json['is_premium_active'] == true,
      status: json['status']?.toString() ?? 'inactive',
      source: json['source']?.toString() ?? 'unknown',
      productId: json['product_id']?.toString(),
      currentPeriodEnd: DateTime.tryParse(
        json['current_period_end']?.toString() ?? '',
      ),
      cancelAtPeriodEnd: json['cancel_at_period_end'] == true,
    );
  }

  final bool isPremiumActive;
  final String status;
  final String source;
  final String? productId;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;

  PremiumEntitlement toEntitlement() {
    final mappedStatus = _mappedStatus;
    if (!isPremiumActive ||
        (mappedStatus != PremiumStatus.premiumActive &&
            mappedStatus != PremiumStatus.premiumGracePeriod)) {
      return PremiumEntitlement.free(
        status: mappedStatus,
        source: EntitlementSource.backend,
        expiresAt: currentPeriodEnd,
        backendSource: source,
        productId: productId,
        cancelAtPeriodEnd: cancelAtPeriodEnd,
      );
    }
    return PremiumEntitlement(
      status: mappedStatus,
      activeFeatures: const {
        PremiumFeature.removeAds,
        PremiumFeature.geminiAssistant,
        PremiumFeature.cameraSolver,
        PremiumFeature.higherDailyLimits,
      },
      source: EntitlementSource.backend,
      expiresAt: currentPeriodEnd,
      backendSource: source,
      productId: productId,
      cancelAtPeriodEnd: cancelAtPeriodEnd,
    );
  }

  PremiumStatus get _mappedStatus => switch (status) {
    'active' when isPremiumActive => PremiumStatus.premiumActive,
    'grace_period' when isPremiumActive => PremiumStatus.premiumGracePeriod,
    'active' || 'grace_period' => PremiumStatus.premiumExpired,
    'pending_validation' => PremiumStatus.pendingValidation,
    'expired' => PremiumStatus.premiumExpired,
    'canceled' => PremiumStatus.premiumCanceled,
    'revoked' => PremiumStatus.premiumRevoked,
    'inactive' => PremiumStatus.free,
    _ => PremiumStatus.unknown,
  };
}

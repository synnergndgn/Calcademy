import 'package:calcademy/app/premium/backend_entitlement_repository.dart';
import 'package:calcademy/app/premium/premium_feature.dart';
import 'package:calcademy/app/premium/premium_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final client = SupabaseClient(
    'https://staging-project.supabase.co',
    'public-test-key',
  );

  for (final status in ['active', 'grace_period']) {
    test('backend $status grants Premium and remove ads', () async {
      final repository = BackendEntitlementRepository(
        client,
        hasSignedInUser: () => true,
        fetchStatus: () async => [
          {
            'is_premium_active': true,
            'status': status,
            'source': 'google_play',
            'product_id': 'calcademy_premium_monthly',
            'current_period_end': '2099-08-04T12:00:00Z',
            'cancel_at_period_end': false,
          },
        ],
      );

      final entitlement = await repository.refresh();
      expect(entitlement.isPremium, isTrue);
      expect(entitlement.canUse(PremiumFeature.removeAds), isTrue);
      expect(entitlement.source, EntitlementSource.backend);
    });
  }

  for (final statusCase in [
    ('pending_validation', PremiumStatus.pendingValidation),
    ('expired', PremiumStatus.premiumExpired),
    ('canceled', PremiumStatus.premiumCanceled),
    ('revoked', PremiumStatus.premiumRevoked),
    ('inactive', PremiumStatus.free),
  ]) {
    test('backend ${statusCase.$1} remains free', () async {
      final repository = BackendEntitlementRepository(
        client,
        hasSignedInUser: () => true,
        fetchStatus: () async => {
          'is_premium_active': false,
          'status': statusCase.$1,
          'source': 'google_play',
          'cancel_at_period_end': false,
        },
      );

      final entitlement = await repository.refresh();
      expect(entitlement.status, statusCase.$2);
      expect(entitlement.isPremium, isFalse);
      expect(entitlement.canUse(PremiumFeature.removeAds), isFalse);
    });
  }

  test('backend error fails closed', () async {
    final repository = BackendEntitlementRepository(
      client,
      hasSignedInUser: () => true,
      fetchStatus: () async => throw StateError('offline'),
    );

    final entitlement = await repository.refresh();
    expect(entitlement.status, PremiumStatus.unknown);
    expect(entitlement.isPremium, isFalse);
  });

  test('signed-out repository stays free without fetching', () async {
    var fetched = false;
    final repository = BackendEntitlementRepository(
      client,
      hasSignedInUser: () => false,
      fetchStatus: () async {
        fetched = true;
        return null;
      },
    );

    final entitlement = await repository.refresh();
    expect(fetched, isFalse);
    expect(entitlement.isPremium, isFalse);
  });
}

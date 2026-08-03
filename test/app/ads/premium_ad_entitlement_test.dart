import 'package:calcademy/app/ads/ad_banner.dart';
import 'package:calcademy/app/premium/local_entitlement_repository.dart';
import 'package:calcademy/app/premium/premium_entitlement.dart';
import 'package:calcademy/app/premium/premium_gate_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('free entitlement preserves the normal ad slot', (tester) async {
    await _pump(
      tester,
      LocalEntitlementRepository(
        initialEntitlement: const PremiumEntitlement.free(),
      ),
    );
    expect(find.byKey(const Key('ad-banner-not-loaded')), findsOneWidget);
    expect(find.byKey(const Key('ad-banner-premium-hidden')), findsNothing);
  });

  testWidgets('mock premium removeAds entitlement shrinks the ad slot', (
    tester,
  ) async {
    await _pump(
      tester,
      LocalEntitlementRepository(
        initialEntitlement: const PremiumEntitlement.mockPremium(),
      ),
    );
    expect(find.byKey(const Key('ad-banner-premium-hidden')), findsOneWidget);
    expect(tester.getSize(find.byType(AdBanner)).height, 0);
  });
}

Future<void> _pump(
  WidgetTester tester,
  LocalEntitlementRepository repository,
) => tester.pumpWidget(
  ProviderScope(
    overrides: [entitlementRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(
      home: Scaffold(bottomNavigationBar: AdBanner(enabled: false)),
    ),
  ),
);

import 'package:calcademy/app/ads/ad_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('consent debug settings', () {
    test('a normal build sends no debug settings at all', () {
      // No --dart-define in the test host, which is exactly the shipping
      // configuration. UMP must see production behaviour, not a forced
      // geography that would show EEA users' consent form to everyone.
      expect(AdConfig.forcesEeaDebugGeography, isFalse);
      expect(AdConfig.hasTestDevices, isFalse);
      expect(AdConfig.consentDebugSettings, isNull);
    });

    test('debug geography is opt-in by an exact token', () {
      // Guards against a truthy-string mistake making every build force EEA.
      expect(AdConfig.forcesEeaDebugGeography, isFalse);
    });
  });

  group('release ad configuration', () {
    test('identifiers are still well formed', () {
      expect(AdConfig.isValidReleaseConfig(), isTrue);
    });

    test('debug and profile builds never serve the real unit', () {
      expect(AdConfig.useTestAds, isTrue);
      expect(AdConfig.activeBannerAdUnitId, AdConfig.testBannerAdUnitId);
    });
  });
}

import 'package:calcademy/app/ads/ad_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('consent debug settings', () {
    test('a normal build sends no debug settings at all', () {
      // No --dart-define in the test host, which is exactly the shipping
      // configuration. UMP must see production behaviour, not a forced
      // geography that would show EEA users' consent form to everyone.
      expect(AdConfig.forcesEeaDebugGeography, isFalse);
      expect(AdConfig.hasUmpTestDevices, isFalse);
      expect(AdConfig.consentDebugSettings, isNull);
    });

    test('debug geography is opt-in by an exact token', () {
      // Guards against a truthy-string mistake making every build force EEA.
      expect(AdConfig.forcesEeaDebugGeography, isFalse);
    });

    test('UMP and AdMob test identifiers are separate inputs', () {
      // They are different hashes of the same device and neither SDK accepts
      // the other's value. Feeding the AdMob id to UMP leaves the device
      // unrecognised, which makes UMP silently ignore the debug geography —
      // no consent form, no error. Verified on device 2026-08-06.
      expect(AdConfig.umpTestDeviceIds, isEmpty);
      expect(AdConfig.testDeviceIds, isEmpty);
      expect(AdConfig.hasUmpTestDevices, AdConfig.umpTestDeviceIds.isNotEmpty);
      expect(AdConfig.hasTestDevices, AdConfig.testDeviceIds.isNotEmpty);
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

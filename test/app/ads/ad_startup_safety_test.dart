import 'package:calcademy/app/ads/ad_service.dart';
import 'package:calcademy/app/ads/consent_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Startup crash-safety: on the test host (ads disabled) the ad and consent
/// services must be fully inert — never touching the plugin, never throwing,
/// always resolving to the fail-closed default.
void main() {
  setUp(() {
    AdService.resetForTest();
    ConsentService.resetForTest();
  });

  test('AdService stays unavailable and never throws', () async {
    expect(AdService.isAvailable, isFalse);

    final ready = await AdService.ensureInitialized();
    expect(ready, isFalse);
    expect(AdService.isAvailable, isFalse);

    // Idempotent and safe to call repeatedly.
    expect(await AdService.ensureInitialized(), isFalse);
    expect(AdService.isAvailable, isFalse);
  });

  test('ConsentService gathering completes without throwing', () async {
    // Must resolve (not hang or throw) when ads are disabled.
    await ConsentService.ensureGathered();
    await ConsentService.gatherIfRequired();
  });

  test('canRequestAds is fail-closed (false) when ads are disabled', () async {
    expect(await ConsentService.canRequestAds(), isFalse);
  });
}

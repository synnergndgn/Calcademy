import 'package:calcademy/app/ads/ad_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Startup crash-safety: on the test host (ads disabled) the ad service must be
/// fully inert — never touching the plugin, never throwing, always resolving to
/// the fail-closed default.
void main() {
  setUp(AdService.resetForTest);

  test('AdService stays unavailable and never throws', () async {
    expect(AdService.isAvailable, isFalse);

    final ready = await AdService.ensureInitialized();
    expect(ready, isFalse);
    expect(AdService.isAvailable, isFalse);

    // Idempotent and safe to call repeatedly.
    expect(await AdService.ensureInitialized(), isFalse);
    expect(AdService.isAvailable, isFalse);
  });

  test('concurrent initialization calls share one future (no race)', () async {
    final results = await Future.wait([
      AdService.ensureInitialized(),
      AdService.ensureInitialized(),
      AdService.ensureInitialized(),
    ]);

    expect(results, everyElement(isFalse));
    expect(AdService.isAvailable, isFalse);
  });
}

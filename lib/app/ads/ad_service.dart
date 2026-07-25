import 'package:calcademy/app/ads/ad_config.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// One-time, fail-closed initialization of the Google Mobile Ads SDK.
///
/// **Never call this before `runApp`.** The 1.0.0+6 startup crash originated in
/// the ads SDK's native AndroidX Startup provider, and blocking first frame on
/// ad initialization only widens the window in which a native fault is fatal.
/// Initialization is driven lazily by [AdBanner] instead, so the app is already
/// interactive before the SDK is touched, and a failure degrades to "no banner"
/// rather than "no app".
///
/// Guarded by [AdConfig.adsEnabled], so calling [ensureInitialized] from a test
/// or on an unsupported platform is a no-op that never touches the plugin. A
/// failed initialization leaves ads unavailable for the rest of the session
/// (fail-closed) rather than crashing the app or retrying in a tight loop.
abstract final class AdService {
  static Future<bool>? _initFuture;
  static bool _available = false;

  /// Whether the SDK finished initializing successfully. Ad widgets must check
  /// this before requesting an ad. Defaults to `false` until a successful init.
  static bool get isAvailable => _available;

  @visibleForTesting
  static void resetForTest() {
    _initFuture = null;
    _available = false;
  }

  /// Initializes the Mobile Ads SDK exactly once and reports whether ads are
  /// usable.
  ///
  /// Concurrent callers share a single in-flight future — the `??=` assignment
  /// happens before the first `await`, so two widgets initializing on the same
  /// frame cannot race into two `MobileAds.initialize` calls. Safe to call
  /// repeatedly and from anywhere; it never throws to the caller.
  static Future<bool> ensureInitialized() {
    if (!AdConfig.adsEnabled) return Future.value(false);
    return _initFuture ??= _initialize();
  }

  static Future<bool> _initialize() async {
    try {
      // Opt-in only: without --dart-define=ADMOB_TEST_DEVICE_IDS this is a
      // no-op and the SDK sees exactly the production configuration.
      if (AdConfig.hasTestDevices) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: AdConfig.testDeviceIds),
        );
      }
      await MobileAds.instance.initialize();
      _available = true;
    } on Object catch (error, stackTrace) {
      _available = false;
      debugPrint('AdService init failed (ads disabled): $error\n$stackTrace');
    }
    return _available;
  }
}

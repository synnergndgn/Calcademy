import 'package:calcademy/app/ads/ad_config.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// One-time, fail-closed initialization of the Google Mobile Ads SDK.
///
/// Guarded by [AdConfig.adsEnabled], so calling [ensureInitialized] from a test
/// or on an unsupported platform is a no-op that never touches the plugin. A
/// failed initialization leaves ads permanently unavailable for the session
/// (fail-closed) rather than crashing the app or being retried in a tight loop.
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
  /// usable. Safe to call repeatedly (the first call's result is cached) and
  /// safe to call from anywhere; it never throws to the caller.
  static Future<bool> ensureInitialized() {
    if (!AdConfig.adsEnabled) return Future.value(false);
    return _initFuture ??= _initialize();
  }

  static Future<bool> _initialize() async {
    try {
      await MobileAds.instance.initialize();
      _available = true;
    } on Object catch (error, stackTrace) {
      _available = false;
      debugPrint('AdService init failed (ads disabled): $error\n$stackTrace');
    }
    return _available;
  }
}

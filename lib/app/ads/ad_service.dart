import 'package:calcademy/app/ads/ad_config.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// One-time initialization of the Google Mobile Ads SDK.
///
/// Guarded by [AdConfig.adsEnabled], so calling [ensureInitialized] from a test
/// or on an unsupported platform is a no-op that never touches the plugin.
abstract final class AdService {
  static bool _initialized = false;

  @visibleForTesting
  static void resetForTest() => _initialized = false;

  /// Initializes the Mobile Ads SDK exactly once. Safe to call on every app
  /// start; never throws to the caller — a failed init simply leaves ads
  /// unavailable rather than crashing the app.
  static Future<void> ensureInitialized() async {
    if (!AdConfig.adsEnabled || _initialized) return;
    _initialized = true;
    try {
      await MobileAds.instance.initialize();
    } on Object catch (error, stackTrace) {
      _initialized = false;
      debugPrint('AdService init failed: $error\n$stackTrace');
    }
  }
}

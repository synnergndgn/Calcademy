import 'package:calcademy/app/ads/ad_config.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Thin scaffold around the Google User Messaging Platform (UMP) consent flow.
///
/// This sprint wires the *gathering* step so a consent form can be presented in
/// regulated regions (EEA / UK / Switzerland) once the messages are configured
/// in the AdMob console. The app makes no assumption of personalized-ad consent
/// until UMP confirms it: if the status is unknown or the request fails, we
/// keep the conservative default (`canRequestAds` gates personalized serving).
///
/// Guarded by [AdConfig.adsEnabled], so tests and unsupported platforms never
/// reach the platform channel. Nothing here ever throws to the caller.
abstract final class ConsentService {
  /// Requests the latest consent information and, only when UMP reports that a
  /// form is required and available, loads and shows it. Called once at app
  /// start after [AdService.ensureInitialized].
  static Future<void> gatherIfRequired() async {
    if (!AdConfig.adsEnabled) return;
    // Fire-and-forget: consent gathering runs alongside the first ad request
    // and must never block app start.
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          ConsentForm.loadAndShowConsentFormIfRequired((formError) {
            if (formError != null) {
              debugPrint('Consent form error: ${formError.message}');
            }
          });
        },
        (requestError) {
          // Status unknown → callers keep non-personalized-safe behavior.
          debugPrint('Consent info update error: ${requestError.message}');
        },
      );
    } on Object catch (error) {
      debugPrint('Consent gathering failed: $error');
    }
  }

  /// Whether personalized ads may be requested. Stays `false` until UMP
  /// confirms, and on any platform where ads are disabled.
  static Future<bool> canRequestAds() async {
    if (!AdConfig.adsEnabled) return false;
    try {
      return await ConsentInformation.instance.canRequestAds();
    } on Object catch (error) {
      debugPrint('canRequestAds failed: $error');
      return false;
    }
  }
}

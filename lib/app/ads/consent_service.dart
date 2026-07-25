import 'dart:async';

import 'package:calcademy/app/ads/ad_config.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Thin, fail-closed scaffold around the Google User Messaging Platform (UMP)
/// consent flow.
///
/// This wires the *gathering* step so a consent form can be presented in
/// regulated regions (EEA / UK / Switzerland) once the messages are configured
/// in the AdMob console. Every UMP call is guarded: an unconfigured console,
/// an unavailable form, or any error is treated as normal and never rethrown,
/// so consent handling can never crash startup. When consent cannot be
/// confirmed, [canRequestAds] returns `false` and the banner simply stays
/// hidden (the app runs ad-free).
///
/// Guarded by [AdConfig.adsEnabled], so tests and unsupported platforms never
/// reach the platform channel.
abstract final class ConsentService {
  static Future<void>? _gatherFuture;

  @visibleForTesting
  static void resetForTest() => _gatherFuture = null;

  /// Runs the UMP consent-info update at most once (result cached). Completes
  /// when the update finishes or errors; never throws and never blocks longer
  /// than the SDK itself takes. Safe to await from multiple callers.
  static Future<void> ensureGathered() {
    if (!AdConfig.adsEnabled) return Future.value();
    return _gatherFuture ??= _gather();
  }

  /// Backwards-compatible entry point invoked during app bootstrap.
  static Future<void> gatherIfRequired() => ensureGathered();

  static Future<void> _gather() async {
    final completer = Completer<void>();
    void done() {
      if (!completer.isCompleted) completer.complete();
    }

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          // Consent info succeeded. Best-effort: show a form only if UMP
          // requires one and it loads. Any error here is non-fatal.
          try {
            ConsentForm.loadAndShowConsentFormIfRequired((formError) {
              if (formError != null) {
                debugPrint('Consent form error: ${formError.message}');
              }
              done();
            });
          } on Object catch (error) {
            debugPrint('Consent form load failed: $error');
            done();
          }
        },
        (requestError) {
          // Status unknown → callers keep the non-personalized-safe default.
          debugPrint('Consent info update error: ${requestError.message}');
          done();
        },
      );
    } on Object catch (error) {
      debugPrint('Consent gathering failed: $error');
      done();
    }

    return completer.future;
  }

  /// Whether ads may be requested. Returns `false` on any platform where ads
  /// are disabled and on any UMP error (fail-closed → app runs ad-free).
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

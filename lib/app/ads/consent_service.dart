import 'package:calcademy/app/ads/ad_config.dart';
import 'package:calcademy/app/ads/consent_gateway.dart';
import 'package:flutter/foundation.dart';

/// Gathers advertising consent once per session, before any ad is requested.
///
/// Google requires a UMP consent flow wherever EEA/UK rules apply, and the SDK
/// must not request an ad until the user has been asked. So this runs ahead of
/// [AdService]: no consent, no banner. Outside those regions UMP reports that
/// consent is not required and the flow is a single no-op round trip.
///
/// Shaped like [AdService] deliberately — one shared in-flight future, guarded
/// by [AdConfig.adsEnabled] so it is inert in tests and on unsupported
/// platforms, and never throwing to the caller.
abstract final class AdConsentService {
  static Future<ConsentState>? _pending;
  static ConsentState _state = const ConsentState.blocked();

  /// Overridable only from tests; production always talks to UMP.
  @visibleForTesting
  static ConsentGateway gateway = const UmpConsentGateway();

  /// The most recent known state. Blocked until [ensureConsent] resolves, so a
  /// caller that skips the await can never accidentally serve an ad.
  static ConsentState get state => _state;

  static bool get canRequestAds => _state.canRequestAds;

  @visibleForTesting
  static void resetForTest() {
    _pending = null;
    _state = const ConsentState.blocked();
    gateway = const UmpConsentGateway();
  }

  @visibleForTesting
  static void useGateway(ConsentGateway value) {
    _pending = null;
    _state = const ConsentState.blocked();
    gateway = value;
  }

  /// Runs the consent flow at most once per session and reports the result.
  ///
  /// Concurrent callers share one future, so two banners mounting on the same
  /// frame cannot present two consent forms.
  static Future<ConsentState> ensureConsent() {
    if (!AdConfig.adsEnabled) {
      return Future.value(const ConsentState.blocked());
    }
    return _pending ??= _gather();
  }

  static Future<ConsentState> _gather() async {
    try {
      _state = await gateway.gather();
    } on Object catch (error, stackTrace) {
      _state = const ConsentState.blocked();
      debugPrint('Consent gathering failed (no ads): $error\n$stackTrace');
    }
    return _state;
  }

  /// Re-reads the cached state, for example after the user changes their mind
  /// through the privacy options form.
  static Future<ConsentState> refresh() async {
    if (!AdConfig.adsEnabled) return const ConsentState.blocked();
    try {
      _state = await gateway.read();
    } on Object {
      _state = const ConsentState.blocked();
    }
    return _state;
  }

  /// Reopens the user's consent choices, then refreshes the cached state so a
  /// withdrawal takes effect without restarting the app.
  static Future<ConsentState> showPrivacyOptions() async {
    if (!AdConfig.adsEnabled) return const ConsentState.blocked();
    try {
      await gateway.showPrivacyOptions();
    } on Object catch (error) {
      debugPrint('Privacy options form failed to open: $error');
    }
    return refresh();
  }
}

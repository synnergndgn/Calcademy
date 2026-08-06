import 'dart:async';

import 'package:calcademy/app/ads/ad_config.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Whether Calcademy may request an ad, and whether the user must be offered a
/// way to reopen their choice.
///
/// [canRequestAds] mirrors UMP's own meaning: the consent flow has completed,
/// not that the user agreed. Someone who declined still returns true and gets a
/// non-personalised ad. Do not read this field as "has consent".
class ConsentState {
  const ConsentState({
    required this.canRequestAds,
    required this.privacyOptionsRequired,
  });

  /// Nothing gathered yet, and nothing may be requested. The safe starting
  /// point and the safe answer whenever the state cannot be determined.
  const ConsentState.blocked()
    : canRequestAds = false,
      privacyOptionsRequired = false;

  final bool canRequestAds;
  final bool privacyOptionsRequired;
}

/// A narrow seam over Google's User Messaging Platform.
///
/// UMP is reached through static entry points (`ConsentInformation.instance`,
/// `ConsentForm.loadAndShowConsentFormIfRequired`) that call into a platform
/// channel, so consent logic written directly against it cannot be tested off
/// a device. This interface exposes only what Calcademy needs, in plain Dart
/// types, so the decision logic is testable and the plugin stays behind one
/// implementation.
abstract interface class ConsentGateway {
  /// Refreshes consent state and presents the form when UMP says it is
  /// required. Returns the resulting state.
  Future<ConsentState> gather();

  /// Reads the cached state without presenting anything.
  Future<ConsentState> read();

  /// Reopens the consent choices from a privacy-options entry point.
  Future<void> showPrivacyOptions();
}

class UmpConsentGateway implements ConsentGateway {
  const UmpConsentGateway();

  /// Only ever non-null in a build that opted in at compile time.
  ConsentDebugSettings? get debugSettings => AdConfig.consentDebugSettings;

  @override
  Future<ConsentState> gather() async {
    try {
      await _requestUpdate();
    } on Object {
      // A failed refresh is not a reason to block ads outright: UMP keeps the
      // previous decision, and `canRequestAds` below reflects it. Treating a
      // dropped connection as "no consent" would silently cost every offline
      // impression; treating it as "consent" would be a compliance problem.
      // Reading the cached answer is the only defensible middle.
    }
    try {
      await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
    } on Object {
      // Same reasoning: if the form could not be shown, the user simply has
      // not consented yet and `canRequestAds` will say so.
    }
    return read();
  }

  @override
  Future<ConsentState> read() async {
    try {
      final information = ConsentInformation.instance;
      final canRequest = await information.canRequestAds();
      final status = await information.getPrivacyOptionsRequirementStatus();
      return ConsentState(
        canRequestAds: canRequest,
        privacyOptionsRequired:
            status == PrivacyOptionsRequirementStatus.required,
      );
    } on Object {
      return const ConsentState.blocked();
    }
  }

  @override
  Future<void> showPrivacyOptions() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {});
    } on Object {
      // The entry point stays available; nothing else depends on this.
    }
  }

  Future<void> _requestUpdate() {
    final parameters = ConsentRequestParameters(
      consentDebugSettings: debugSettings,
    );
    // The UMP callback API predates futures; bridge it so callers can await.
    final completed = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      parameters,
      () {
        if (!completed.isCompleted) completed.complete();
      },
      (error) {
        if (!completed.isCompleted) {
          completed.completeError(StateError(error.message));
        }
      },
    );
    return completed.future;
  }
}

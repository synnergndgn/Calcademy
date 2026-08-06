import 'package:calcademy/app/ads/consent_gateway.dart';
import 'package:calcademy/app/ads/consent_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current consent state for the UI.
///
/// Reads the cached value rather than gathering: presenting a consent form is
/// [AdBanner]'s job and must happen once, driven by an ad request, not
/// re-triggered every time a settings screen is built.
final adConsentStateProvider =
    NotifierProvider<AdConsentController, ConsentState>(
      AdConsentController.new,
    );

class AdConsentController extends Notifier<ConsentState> {
  @override
  ConsentState build() {
    Future<void>.microtask(refresh);
    return AdConsentService.state;
  }

  Future<void> refresh() async {
    final next = await AdConsentService.refresh();
    if (ref.mounted) state = next;
  }

  /// Reopens the consent choices and reflects the outcome, so withdrawing
  /// consent hides the banner without a restart.
  Future<void> showPrivacyOptions() async {
    final next = await AdConsentService.showPrivacyOptions();
    if (ref.mounted) state = next;
  }
}

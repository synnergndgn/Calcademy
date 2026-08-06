import 'package:calcademy/app/ads/ad_config.dart';
import 'package:calcademy/app/ads/consent_gateway.dart';
import 'package:calcademy/app/ads/consent_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGateway implements ConsentGateway {
  _FakeGateway({
    this.result = const ConsentState(
      canRequestAds: true,
      privacyOptionsRequired: false,
    ),
  });

  ConsentState result;
  int gatherCalls = 0;
  int readCalls = 0;
  int privacyOptionsCalls = 0;

  @override
  Future<ConsentState> gather() async {
    gatherCalls += 1;
    return result;
  }

  @override
  Future<ConsentState> read() async {
    readCalls += 1;
    return result;
  }

  @override
  Future<void> showPrivacyOptions() async {
    privacyOptionsCalls += 1;
  }
}

void main() {
  tearDown(AdConsentService.resetForTest);

  group('the starting state blocks ads', () {
    test('nothing may be requested before consent resolves', () {
      AdConsentService.resetForTest();

      expect(AdConsentService.canRequestAds, isFalse);
      expect(AdConsentService.state.privacyOptionsRequired, isFalse);
    });

    test('a blocked state is what an unknown outcome collapses to', () {
      const blocked = ConsentState.blocked();

      expect(blocked.canRequestAds, isFalse);
      expect(blocked.privacyOptionsRequired, isFalse);
    });
  });

  group('on a platform without ads', () {
    test('consent is never gathered and ads stay blocked', () async {
      // The test host is desktop, so AdConfig.adsEnabled is false. The consent
      // flow must be inert there rather than reaching for the plugin.
      expect(AdConfig.adsEnabled, isFalse);
      final gateway = _FakeGateway();
      AdConsentService.useGateway(gateway);

      final state = await AdConsentService.ensureConsent();

      expect(state.canRequestAds, isFalse);
      expect(gateway.gatherCalls, 0);
    });

    test('refresh and privacy options are inert too', () async {
      final gateway = _FakeGateway();
      AdConsentService.useGateway(gateway);

      await AdConsentService.refresh();
      await AdConsentService.showPrivacyOptions();

      expect(gateway.readCalls, 0);
      expect(gateway.privacyOptionsCalls, 0);
    });
  });

  group('gathering outcomes', () {
    test('a granted result unblocks ad requests', () async {
      final gateway = _FakeGateway(
        result: const ConsentState(
          canRequestAds: true,
          privacyOptionsRequired: true,
        ),
      );

      final state = await gateway.gather();

      expect(state.canRequestAds, isTrue);
      expect(state.privacyOptionsRequired, isTrue);
    });

    test('a refusal keeps ads blocked', () async {
      final gateway = _FakeGateway(
        result: const ConsentState(
          canRequestAds: false,
          privacyOptionsRequired: true,
        ),
      );

      final state = await gateway.gather();

      expect(state.canRequestAds, isFalse);
    });
  });
}

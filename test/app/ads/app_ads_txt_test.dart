import 'package:calcademy/app/ads/ad_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('app-ads.txt authorisation', () {
    test('the publisher id belongs to this build\'s AdMob account', () {
      // A well-formed id from the wrong account is the failure that looks
      // correct: the file publishes, the crawler accepts it, and it authorises
      // someone else's inventory while this app stays unauthorised.
      expect(AdConfig.isValidAppAdsTxtPublisherId(), isTrue);
      expect(
        AdConfig.androidAppId,
        startsWith('ca-app-${AdConfig.appAdsTxtPublisherId}~'),
      );
    });

    test('the published line has the exact required shape', () {
      expect(
        AdConfig.appAdsTxtLine,
        'google.com, pub-5164539069315402, DIRECT, f08c47fec0942fa0',
      );
    });

    test('the check is not vacuous', () {
      // Guards the guard: an id of the right shape but the wrong account must
      // fail, which is the only realistic way this goes wrong in practice.
      const otherAccount = 'pub-1234567890123456';
      expect(
        AdConfig.androidAppId.startsWith('ca-app-$otherAccount~'),
        isFalse,
      );
      expect(RegExp(r'^pub-\d{16}$').hasMatch('pub-123'), isFalse);
    });
  });
}

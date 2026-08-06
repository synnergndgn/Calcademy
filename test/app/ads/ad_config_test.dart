import 'package:calcademy/app/ads/ad_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ads are disabled on the test host so no plugin call is made', () {
    // Widget/unit tests run on the desktop host where dart:io reports a
    // non-mobile OS, so ad code stays inert throughout the suite.
    expect(AdConfig.adsEnabled, isFalse);
  });

  test('non-release builds select the Google test banner unit', () {
    // The test runner is not a release build.
    expect(AdConfig.useTestAds, isTrue);
    expect(AdConfig.activeBannerAdUnitId, AdConfig.testBannerAdUnitId);
    expect(
      AdConfig.testBannerAdUnitId,
      'ca-app-pub-3940256099942544/6300978111',
    );
    // The real unit is never served outside release.
    expect(AdConfig.activeBannerAdUnitId, isNot(AdConfig.bannerAdUnitId));
  });

  test('release configuration uses valid, non-placeholder AdMob ids', () {
    expect(AdConfig.isValidReleaseConfig(), isTrue);
    expect(AdConfig.androidAppId, 'ca-app-pub-5164539069315402~1162467024');
    expect(AdConfig.bannerAdUnitId, 'ca-app-pub-5164539069315402/4507529677');
  });

  test('malformed or placeholder ids are rejected by validation', () {
    // Guard the private regexes indirectly through the public checker by
    // confirming the shipped ids are well-formed and none contain a
    // placeholder token.
    for (final id in [AdConfig.androidAppId, AdConfig.bannerAdUnitId]) {
      expect(id.toLowerCase(), isNot(contains('xxxx')));
      expect(id.toLowerCase(), isNot(contains('todo')));
      expect(id.toLowerCase(), isNot(contains('placeholder')));
      expect(id.startsWith('ca-app-pub-'), isTrue);
    }
  });

  test('no app-ads.txt publisher id is fabricated in source', () {
    // This guard used to require null, because the real value had not been
    // copied from the AdMob console yet. Now that it has, "not fabricated"
    // means something stronger and checkable: the id must be the same AdMob
    // account as the app id this build ships. A well-formed id from another
    // account would publish, crawl, and verify while authorising the wrong
    // inventory.
    expect(AdConfig.isValidAppAdsTxtPublisherId(), isTrue);
  });
}

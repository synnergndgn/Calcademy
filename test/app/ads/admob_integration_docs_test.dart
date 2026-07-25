import 'dart:io';

import 'package:calcademy/app/ads/ad_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the release paperwork so an ad-supported build can never ship with a
/// stale "no ads" claim, and keeps the manifest AdMob wiring in sync with
/// [AdConfig].
void main() {
  test('main manifest declares AdMob App ID and network permissions', () async {
    final manifest = await File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsString();

    expect(manifest, contains('com.google.android.gms.ads.APPLICATION_ID'));
    // The manifest App ID must match the single source of truth in code.
    expect(manifest, contains(AdConfig.androidAppId));
    expect(manifest, contains('android.permission.INTERNET'));
    expect(manifest, contains('android.permission.ACCESS_NETWORK_STATE'));
  });

  test('no Firebase/analytics config or google-services.json is present', () {
    expect(File('android/app/google-services.json').existsSync(), isFalse);
    expect(File('google-services.json').existsSync(), isFalse);
  });

  test(
    'privacy policy discloses Google AdMob and drops no-ads claim',
    () async {
      final policy = await File('docs/privacy_policy.md').readAsString();
      expect(policy, contains('Google AdMob'));
      expect(policy.toLowerCase(), contains('admob'));
      expect(policy.toLowerCase(), isNot(contains('no ads or advertising')));
    },
  );

  test('data safety draft reflects AdMob device-identifier sharing', () async {
    final dataSafety = await File('docs/data_safety_draft.md').readAsString();
    expect(dataSafety, contains('AdMob'));
    expect(dataSafety.toLowerCase(), contains('advertising'));
  });

  test('play app-content checklist declares contains-ads = yes', () async {
    final checklist = await File(
      'docs/play_console_app_content_checklist.md',
    ).readAsString();
    expect(checklist.toLowerCase(), contains('contains ads'));
    expect(checklist, contains('AdMob'));
  });

  test(
    'app-ads.txt setup is documented without a fabricated publisher id',
    () async {
      final doc = await File('docs/app_ads_txt_setup.md').readAsString();
      expect(doc, contains('app-ads.txt'));
      // No fabricated authorization line: the real pub id stays a manual step.
      expect(AdConfig.appAdsTxtPublisherId, isNull);
    },
  );

  test('store listing no longer advertises the app as ad-free', () async {
    final listing = await File('docs/store_listing.md').readAsString();
    expect(listing.toLowerCase(), contains('ad-supported'));
    expect(listing, contains('AdMob'));
  });
}

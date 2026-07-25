import 'dart:io';

import 'package:calcademy/app/ads/ad_config.dart';
import 'package:calcademy/app/app_metadata.dart';
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

  test('manifest embeds the App ID (with ~) but not the banner unit', () async {
    final manifest = await File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsString();

    // App ids use '~'; ad-unit ids use '/'. The banner unit must never leak
    // into the manifest APPLICATION_ID slot.
    expect(manifest, contains(AdConfig.androidAppId));
    expect(AdConfig.androidAppId, contains('~'));
    expect(manifest, isNot(contains(AdConfig.bannerAdUnitId)));
  });

  test('release proguard keeps the AdMob/UMP SDK surface', () async {
    final rules = await File('android/app/proguard-rules.pro').readAsString();
    expect(rules, contains('com.google.android.gms.ads'));
    expect(rules, contains('com.google.android.ump'));
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

  test('store listing scopes banners to Home and Saved', () async {
    final listing = await File('docs/store_listing.md').readAsString();

    // The placement promise made to users must match the code, which puts
    // AdBanner only on Home and Saved.
    expect(listing, contains('Home and Saved'));
  });

  test('app metadata declares the ad-supported posture', () {
    expect(AppMetadata.adsStatus, 'admob-banner');
    expect(AppMetadata.analyticsStatus, 'not-included');
    expect(AppMetadata.cloudSyncStatus, 'not-included');
  });

  test('privacy policy does not claim consent is already active', () async {
    final policy = await File('docs/privacy_policy.md').readAsString();

    // UMP is out of scope for this sprint. Publishing a policy that implies a
    // live consent flow would be a false statement to users and reviewers.
    expect(policy, contains('Consent is not yet implemented in this build'));
    expect(policy, contains('User Messaging Platform'));
  });

  test('data safety declares collection and sharing, not "no data"', () async {
    final dataSafety = await File('docs/data_safety_draft.md').readAsString();

    expect(dataSafety, contains('Yes (via AdMob)'));
    expect(dataSafety.toLowerCase(), isNot(contains('no data collected')));
  });

  test('ad-related permissions are declared in the main manifest', () async {
    final manifest = await File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsString();

    expect(manifest, contains('android.permission.INTERNET'));
    expect(manifest, contains('android.permission.ACCESS_NETWORK_STATE'));
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the AdMob rollback (1.0.0+7): the ads SDK, its code, manifest entries,
/// network permissions, and store "contains ads" claims must all be gone, so a
/// future accidental re-introduction is caught before it can crash startup or
/// mislead the store declaration again.
void main() {
  test('no google_mobile_ads dependency in pubspec', () async {
    final pubspec = await File('pubspec.yaml').readAsString();
    expect(pubspec, isNot(contains('google_mobile_ads')));
    expect(pubspec.toLowerCase(), isNot(contains('mobile_ads')));
  });

  test('no google_mobile_ads in the lock file', () async {
    final lock = await File('pubspec.lock').readAsString();
    expect(lock, isNot(contains('google_mobile_ads')));
  });

  test('the lib/app/ads directory no longer exists', () {
    expect(Directory('lib/app/ads').existsSync(), isFalse);
  });

  test('no Dart source imports the ads plugin or removed ad modules', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (source.contains('package:google_mobile_ads/') ||
          source.contains('app/ads/')) {
        offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty, reason: 'ad references remain in: $offenders');
  });

  test(
    'main manifest has no AdMob App ID and no network permissions',
    () async {
      final manifest = await File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsString();
      expect(manifest, isNot(contains('com.google.android.gms.ads')));
      expect(manifest, isNot(contains('APPLICATION_ID')));
      expect(manifest, isNot(contains('android.permission.INTERNET')));
      expect(manifest, isNot(contains('ACCESS_NETWORK_STATE')));
    },
  );

  test('proguard rules keep no AdMob/UMP SDK surface', () async {
    final rules = await File('android/app/proguard-rules.pro').readAsString();
    expect(rules, isNot(contains('com.google.android.gms.ads')));
    expect(rules, isNot(contains('com.google.android.ump')));
  });

  test('no google-services.json is present', () {
    expect(File('android/app/google-services.json').existsSync(), isFalse);
    expect(File('google-services.json').existsSync(), isFalse);
  });

  test('store + Play docs declare the ad-free posture', () async {
    final listing = await File('docs/store_listing.md').readAsString();
    expect(listing.toLowerCase(), isNot(contains('ad-supported')));

    final checklist = await File(
      'docs/play_console_app_content_checklist.md',
    ).readAsString();
    // The Ads section must answer No, not "Contains ads = Yes".
    expect(checklist, contains('No — this app contains no ads'));
  });
}

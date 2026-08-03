import 'dart:io';

import 'package:calcademy/app/ads/ad_config.dart';
import 'package:calcademy/app/app_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression guards for the 1.0.0+6 startup crash that forced the 1.0.0+7
/// rollback:
///
///   Unable to get provider androidx.startup.InitializationProvider
///     Caused by: com.google.android.gms.internal.ads...
///     Caused by: Failed to create an instance of androidx.work.impl.WorkDatabase
///
/// That fault happened in a native ContentProvider during process start, before
/// Dart `main()` ran, so no Dart-side try/catch could contain it. These tests
/// lock in the two things that actually prevent it: a WorkManager/Room pair new
/// enough for R8 full mode, and an app that never touches the ads SDK before
/// `runApp`.
void main() {
  group('nothing touches the ads SDK before runApp', () {
    test('main.dart contains no ads import or ad service call', () async {
      final source = await File('lib/main.dart').readAsString();

      expect(source, isNot(contains('package:google_mobile_ads/')));
      expect(source, isNot(contains('app/ads/')));
      expect(source, isNot(contains('MobileAds')));
      expect(source, isNot(contains('AdService')));
    });

    test('ad initialization is reachable only from the banner widget', () async {
      // AdService.ensureInitialized is the single entry point into the SDK; it
      // must be driven lazily by AdBanner, never by app bootstrap.
      final callers = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final path = entity.path.replaceAll(r'\', '/');
        if (path.endsWith('lib/app/ads/ad_service.dart')) continue;
        if (entity.readAsStringSync().contains('AdService.ensureInitialized')) {
          callers.add(path);
        }
      }

      expect(callers, ['lib/app/ads/ad_banner.dart']);
    });
  });

  group('native dependency floor', () {
    test('WorkManager is forced past the Room 2.2.5 era', () async {
      // play-services-ads pins androidx.work 2.7.0, which pins Room 2.2.5 —
      // pre-R8-full-mode, whose generated WorkDatabase_Impl loses the no-arg
      // constructor Room instantiates reflectively. Dropping this force
      // reintroduces the crash.
      final gradle = await File('android/app/build.gradle.kts').readAsString();

      // Match the declaration itself, not the version numbers quoted in the
      // surrounding explanatory comment.
      final force = RegExp(
        r'implementation\("androidx\.work:work-runtime:(\d+)\.(\d+)\.(\d+)"\)',
      ).firstMatch(gradle);
      expect(force, isNotNull, reason: 'work-runtime force is missing');

      final major = int.parse(force!.group(1)!);
      final minor = int.parse(force.group(2)!);
      expect(
        major > 2 || (major == 2 && minor >= 11),
        isTrue,
        reason: 'work-runtime must stay >= 2.11.0, got ${force.group(0)}',
      );
    });

    test('R8 keeps Room database constructors', () async {
      final rules = await File('android/app/proguard-rules.pro').readAsString();

      // "Failed to create an instance of" means the class survived but its
      // constructor did not, so the <init>() member is the part that matters.
      expect(
        rules,
        contains('-keep class * extends androidx.room.RoomDatabase'),
      );
      expect(rules, contains('<init>()'));
      expect(rules, contains('androidx.startup.Initializer'));
    });
  });

  group('test device configuration', () {
    test('no test device is baked into a normal build', () {
      // Test device ids arrive via --dart-define, never from source, so a
      // personal device id cannot be committed and production behaviour is
      // unchanged unless the define is passed explicitly.
      expect(AdConfig.testDeviceIds, isEmpty);
      expect(AdConfig.hasTestDevices, isFalse);
    });

    test('ad config source declares no literal device id', () async {
      final source = await File('lib/app/ads/ad_config.dart').readAsString();

      expect(source, contains('String.fromEnvironment'));
      expect(source, contains('ADMOB_TEST_DEVICE_IDS'));
    });
  });

  group('release identity', () {
    test('current release is 1.5.0+14', () async {
      final pubspec = await File('pubspec.yaml').readAsString();

      expect(pubspec, contains('version: 1.5.0+14'));
      expect(AppMetadata.versionName, '1.5.0');
      expect(AppMetadata.buildNumber, 14);
    });
  });

  group('banner placement', () {
    const adFreeFeatures = [
      'calculator',
      'calculus',
      'equation_solver',
      'financial_calculator',
      'formula_library',
      'graph',
      'integer_programming',
      'linear_programming',
      'matrix',
      'operations_research',
      'optimization',
      'statistics',
    ];

    test('calculation and input screens carry no ads', () {
      final offenders = <String>[];
      for (final feature in adFreeFeatures) {
        final directory = Directory('lib/features/$feature');
        if (!directory.existsSync()) continue;
        for (final entity in directory.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final source = entity.readAsStringSync();
          if (source.contains('app/ads/') || source.contains('AdBanner')) {
            offenders.add(entity.path.replaceAll(r'\', '/'));
          }
        }
      }

      expect(offenders, isEmpty, reason: 'ads leaked into: $offenders');
    });

    test('Home and Saved anchor the banner', () async {
      for (final path in [
        'lib/features/home/presentation/home_page.dart',
        'lib/features/saved/presentation/saved_page.dart',
      ]) {
        final source = await File(path).readAsString();
        expect(source, contains('AdBanner'), reason: '$path lost its banner');
        expect(source, contains('bottomNavigationBar: const AdBanner()'));
      }
    });
  });
}

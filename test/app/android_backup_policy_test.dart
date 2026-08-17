import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android manifest disables backup and declares extraction rules', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
  });

  test('legacy backup rules exclude every eligible data domain', () {
    final rules = File(
      'android/app/src/main/res/xml/backup_rules.xml',
    ).readAsStringSync();

    for (final domain in [
      'root',
      'file',
      'database',
      'sharedpref',
      'external',
    ]) {
      expect(rules, contains('<exclude domain="$domain" path="." />'));
    }
  });

  test('Android 12 rules exclude cloud backup and device transfer', () {
    final rules = File(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ).readAsStringSync();

    expect(rules, contains('<cloud-backup>'));
    expect(rules, contains('<device-transfer>'));
    for (final domain in [
      'root',
      'file',
      'database',
      'sharedpref',
      'external',
      'device_root',
      'device_file',
      'device_database',
      'device_sharedpref',
    ]) {
      expect(
        RegExp('<exclude domain="$domain" path="\\." />').allMatches(rules),
        hasLength(2),
      );
    }
  });
}

import 'dart:io';

import 'package:calcademy/app/app_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('version is 1.4.0+13 everywhere', () async {
    final pubspec = await File('pubspec.yaml').readAsString();
    expect(pubspec, contains('version: 1.4.0+13'));
    expect(AppMetadata.versionName, '1.4.0');
    expect(AppMetadata.buildNumber, 13);
  });

  test(
    'tracked files contain no forbidden secret or signing artifacts',
    () async {
      final result = await Process.run('git', ['ls-files']);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      final tracked = (result.stdout as String)
          .split(RegExp(r'\r?\n'))
          .where((path) => path.isNotEmpty)
          .toList();
      final normalized = tracked.map((path) => path.replaceAll('\\', '/'));

      const forbiddenFiles = {
        '.env',
        'android/key.properties',
        'android/local.properties',
        'google-services.json',
        '.claude/settings.local.json',
      };
      for (final path in normalized) {
        expect(forbiddenFiles.contains(path), isFalse, reason: path);
        expect(path.endsWith('.jks'), isFalse, reason: path);
        expect(path.endsWith('.keystore'), isFalse, reason: path);
        expect(path.endsWith('/google-services.json'), isFalse, reason: path);
      }

      const forbiddenText = [
        'SERVICE'
            '_ROLE_KEY',
        'SUPABASE'
            '_SERVICE_ROLE',
        'GEMINI'
            '_API_KEY',
        'OPENAI'
            '_API_KEY',
        'ANTHROPIC'
            '_API_KEY',
      ];
      for (final path in tracked.where(_isTextSource)) {
        final contents = await File(path).readAsString();
        for (final pattern in forbiddenText) {
          expect(
            contents,
            isNot(contains(pattern)),
            reason: '$pattern in $path',
          );
        }
      }
    },
  );

  test('auth config uses dart defines and no hardcoded credentials', () async {
    final config = await File('lib/app/config/app_config.dart').readAsString();
    final main = await File('lib/main.dart').readAsString();

    expect(config, contains("String.fromEnvironment('SUPABASE_URL')"));
    expect(config, contains("String.fromEnvironment('SUPABASE_ANON_KEY')"));
    expect(main, contains('if (AppConfig.isSupabaseConfigured)'));
    expect(main, contains('supabaseClientProvider.overrideWithValue'));
  });
}

bool _isTextSource(String path) {
  const extensions = {
    '.dart',
    '.md',
    '.yaml',
    '.yml',
    '.json',
    '.html',
    '.xml',
    '.kts',
    '.gradle',
    '.properties',
  };
  return extensions.any(path.toLowerCase().endsWith);
}

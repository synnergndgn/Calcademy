import 'dart:io';

import 'package:calcademy/app/app_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('version is 1.10.2+34 everywhere', () async {
    final pubspec = await File('pubspec.yaml').readAsString();
    expect(pubspec, contains('version: 1.10.2+34'));
    expect(AppMetadata.versionName, '1.10.2');
    expect(AppMetadata.buildNumber, 34);
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

      const clientForbiddenText = [
        'SERVICE'
            '_ROLE_KEY',
        'service'
            '_role',
        'GEMINI'
            '_API_KEY',
        'OPENAI'
            '_API_KEY',
        'ANTHROPIC'
            '_API_KEY',
      ];
      for (final path in tracked.where(
        (path) =>
            path.replaceAll('\\', '/').startsWith('lib/') &&
            _isTextSource(path),
      )) {
        final contents = await File(path).readAsString();
        for (final pattern in clientForbiddenText) {
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

    // The config file is retained for the dormant auth experiment, so it must
    // keep reading its values from the environment and never carry a literal.
    expect(config, contains("String.fromEnvironment('SUPABASE_URL')"));
    expect(config, contains("String.fromEnvironment('SUPABASE_ANON_KEY')"));
  });

  test('the entrypoint does not wire Supabase into the shipped app', () async {
    final main = await File('lib/main.dart').readAsString();

    // Until 1.9.4+28 this test asserted the opposite, because main.dart did
    // initialise Supabase when configured. The release removed that wiring and
    // the published policy states there is no account client, so the assertion
    // has to run the other way: a reintroduced initialisation would make the
    // policy false without anything else failing.
    expect(main, isNot(contains('AppConfig')));
    expect(main, isNot(contains('supabaseClientProvider')));
    expect(main, isNot(contains('Supabase')));
  });

  test(
    'service role is referenced only by the server function environment',
    () async {
      final result = await Process.run('git', ['ls-files']);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      final tracked = (result.stdout as String)
          .split(RegExp(r'\r?\n'))
          .where((path) => path.endsWith('.dart') || path.endsWith('.ts'));
      final matches = <String>[];
      const pattern =
          'SUPABASE'
          '_SERVICE_ROLE_KEY';
      for (final path in tracked) {
        final contents = await File(path).readAsString();
        if (contents.contains(pattern)) matches.add(path.replaceAll('\\', '/'));
      }
      expect(matches, everyElement(startsWith('supabase/functions/')));
    },
  );
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

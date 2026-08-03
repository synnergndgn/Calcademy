import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('billing client contains no privileged backend credentials', () async {
    final sources = await Directory('lib')
        .list(recursive: true)
        .where((entry) => entry is File && entry.path.endsWith('.dart'))
        .cast<File>()
        .toList();
    const forbidden = [
      'PLAY_DEVELOPER'
          '_API_KEY',
      'private'
          '_key',
      'service'
          '_role',
    ];
    for (final source in sources) {
      final contents = await source.readAsString();
      for (final pattern in forbidden) {
        expect(contents, isNot(contains(pattern)), reason: source.path);
      }
    }
  });

  test('purchase verification values are never logged or persisted', () async {
    final billingSources = await Directory('lib/app')
        .list(recursive: true)
        .where((entry) => entry is File && entry.path.endsWith('.dart'))
        .cast<File>()
        .toList();
    final loggingPattern = RegExp(
      r'(?:debugPrint|print|log)\s*\([^;]*(?:purchaseToken|purchase_token)',
      caseSensitive: false,
    );
    for (final source in billingSources) {
      final contents = await source.readAsString();
      expect(contents, isNot(matches(loggingPattern)), reason: source.path);
    }
    final billingController = await File(
      'lib/app/billing/billing_controller.dart',
    ).readAsString();
    expect(billingController, isNot(contains('SharedPreferences')));
    expect(billingController, isNot(contains('writeAsString')));
  });

  test('premium flow contains no external payment provider', () async {
    final source = await File(
      'lib/features/premium/presentation/premium_page.dart',
    ).readAsString();
    for (final provider in ['stripe', 'paypal', 'iban']) {
      expect(source.toLowerCase(), isNot(contains(provider)));
    }
    expect(source, contains("Uri.https('play.google.com'"));
  });
}

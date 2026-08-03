import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ads remain limited to Home and Saved presentation files', () async {
    final assistant = await File(
      'lib/features/ai_assistant/presentation/ai_assistant_page.dart',
    ).readAsString();
    final calculator = await File(
      'lib/features/calculator/presentation/calculator_page.dart',
    ).readAsString();
    final formulas = await File(
      'lib/features/formula_library/presentation/formula_library_page.dart',
    ).readAsString();
    final home = await File(
      'lib/features/home/presentation/home_page.dart',
    ).readAsString();
    final saved = await File(
      'lib/features/saved/presentation/saved_page.dart',
    ).readAsString();

    expect(assistant, isNot(contains('AdBanner')));
    expect(calculator, isNot(contains('AdBanner')));
    expect(formulas, isNot(contains('AdBanner')));
    expect(home, contains('const AdBanner()'));
    expect(saved, contains('const AdBanner()'));
  });
}

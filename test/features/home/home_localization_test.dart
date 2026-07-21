import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'professional home localization keys have English and Turkish parity',
    () {
      const english = AppLocalizations(Locale('en'));
      const turkish = AppLocalizations(Locale('tr'));
      const keys = [
        'homeHeroEyebrow',
        'homeTools',
        'homeOffline',
        'homeOnDevice',
        'homeSearchLabel',
        'homeSearchHint',
        'homeNoResultsTitle',
        'homeNoResultsBody',
        'homeComingSoonBody',
        'openModule',
        'categoryMathematics',
        'categoryMathematicsDescription',
        'categoryOptimization',
        'categoryOptimizationDescription',
        'categoryDataStatistics',
        'categoryDataStatisticsDescription',
        'categoryFinance',
        'categoryFinanceDescription',
        'categoryWorkspace',
        'categoryWorkspaceDescription',
      ];

      for (final key in keys) {
        expect(english.t(key), isNot(key), reason: 'English missing $key');
        expect(turkish.t(key), isNot(key), reason: 'Turkish missing $key');
      }
    },
  );
}

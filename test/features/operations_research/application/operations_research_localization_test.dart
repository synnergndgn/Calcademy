import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OR 1.1 localization keys have English and Turkish parity', () {
    const english = AppLocalizations(Locale('en'));
    const turkish = AppLocalizations(Locale('tr'));
    const keys = [
      'orShortTitle',
      'orGoalProgramming',
      'orCpmPert',
      'orDecisionVariables',
      'orHardConstraints',
      'orGoals',
      'orUnderWeight',
      'orOverWeight',
      'orTotalWeightedDeviation',
      'orActivity',
      'orDuration',
      'orPredecessors',
      'orCriticalPath',
      'orProjectDuration',
      'orOptimistic',
      'orMostLikely',
      'orPessimistic',
      'orExpectedTime',
      'orVariance',
      'orErrorCyclicNetwork',
      'orErrorPertTimes',
    ];

    for (final key in keys) {
      expect(english.t(key), isNot(key), reason: 'English missing $key');
      expect(turkish.t(key), isNot(key), reason: 'Turkish missing $key');
    }
  });
}

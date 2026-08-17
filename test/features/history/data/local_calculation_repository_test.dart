import 'dart:convert';

import 'package:calcademy/features/history/data/local_calculation_repository.dart';
import 'package:calcademy/features/history/domain/calculation_record.dart';
import 'package:calcademy/features/history/domain/saved_calculation.dart';
import 'package:calcademy/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('history and saved records survive a repository restart', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalCalculationRepository(preferences);
    final record = CalculationRecord(
      id: 'history-1',
      expression: '1+1',
      result: '2',
      createdAt: DateTime.utc(2026, 8, 10),
      angleMode: AngleMode.degrees,
    );
    final saved = SavedCalculation(
      id: 'saved-1',
      title: 'Addition',
      expression: '1+1',
      result: '2',
      createdAt: DateTime.utc(2026, 8, 10),
    );

    await repository.saveHistory([record]);
    await repository.saveSaved([saved]);
    final restored = LocalCalculationRepository(preferences);

    expect(restored.loadHistory().single.id, record.id);
    expect(restored.loadSaved().single.id, saved.id);
  });

  test(
    'malformed and wrong-shaped payloads fall back without throwing',
    () async {
      SharedPreferences.setMockInitialValues({
        'calculator.history': '{broken',
        'calculator.saved': jsonEncode({'items': []}),
      });
      final repository = LocalCalculationRepository(
        await SharedPreferences.getInstance(),
      );

      expect(repository.loadHistory(), isEmpty);
      expect(repository.loadSaved(), isEmpty);
    },
  );

  test(
    'corrupt records are skipped while valid records are preserved',
    () async {
      final validHistory = CalculationRecord(
        id: 'history-1',
        expression: '2+2',
        result: '4',
        createdAt: DateTime.utc(2026, 8, 10),
        angleMode: AngleMode.radians,
      );
      final validSaved = SavedCalculation(
        id: 'saved-1',
        title: 'Valid',
        expression: '2+2',
        result: '4',
        createdAt: DateTime.utc(2026, 8, 10),
      );
      SharedPreferences.setMockInitialValues({
        'calculator.history': jsonEncode([
          validHistory.toJson(),
          {'id': 'missing-required-fields'},
          'not-a-map',
        ]),
        'calculator.saved': jsonEncode([
          {'createdAt': 'not-a-date'},
          validSaved.toJson(),
        ]),
      });
      final repository = LocalCalculationRepository(
        await SharedPreferences.getInstance(),
      );

      expect(repository.loadHistory().map((item) => item.id), ['history-1']);
      expect(repository.loadSaved().map((item) => item.id), ['saved-1']);
    },
  );
}

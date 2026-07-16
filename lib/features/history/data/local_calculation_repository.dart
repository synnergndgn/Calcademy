import 'dart:convert';

import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/history/domain/calculation_record.dart';
import 'package:calcademy/features/history/domain/saved_calculation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final calculationRepositoryProvider = Provider<LocalCalculationRepository>(
  (ref) => LocalCalculationRepository(ref.watch(sharedPreferencesProvider)),
);

class LocalCalculationRepository {
  const LocalCalculationRepository(this.preferences);

  final SharedPreferences preferences;
  static const _historyKey = 'calculator.history';
  static const _savedKey = 'calculator.saved';

  List<CalculationRecord> loadHistory() =>
      _decode(_historyKey).map(CalculationRecord.fromJson).toList();

  List<SavedCalculation> loadSaved() =>
      _decode(_savedKey).map(SavedCalculation.fromJson).toList();

  Future<void> saveHistory(List<CalculationRecord> records) =>
      preferences.setString(
        _historyKey,
        jsonEncode(records.map((item) => item.toJson()).toList()),
      );

  Future<void> saveSaved(List<SavedCalculation> records) =>
      preferences.setString(
        _savedKey,
        jsonEncode(records.map((item) => item.toJson()).toList()),
      );

  List<Map<String, Object?>> _decode(String key) {
    final source = preferences.getString(key);
    if (source == null) return [];
    try {
      final items = jsonDecode(source) as List<Object?>;
      return items
          .whereType<Map<String, Object?>>()
          .map(Map<String, Object?>.from)
          .toList();
    } on FormatException {
      return [];
    }
  }
}

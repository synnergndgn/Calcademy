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
      _decode(_historyKey, CalculationRecord.fromJson);

  List<SavedCalculation> loadSaved() =>
      _decode(_savedKey, SavedCalculation.fromJson);

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

  List<T> _decode<T>(
    String key,
    T Function(Map<String, Object?> json) fromJson,
  ) {
    try {
      final source = preferences.getString(key);
      if (source == null) return [];
      final decoded = jsonDecode(source);
      if (decoded is! List) return [];
      final items = <T>[];
      for (final item in decoded) {
        try {
          if (item is! Map) continue;
          items.add(fromJson(Map<String, Object?>.from(item)));
        } on Object {
          // Preserve every valid record when an older or partially corrupted
          // payload contains an item that can no longer be decoded.
        }
      }
      return items;
    } on Object {
      // Local preference corruption or a legacy value of the wrong type must
      // not prevent the app from starting.
      return [];
    }
  }
}

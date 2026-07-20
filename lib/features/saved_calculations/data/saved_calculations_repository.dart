import 'dart:convert';

import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_failure.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_limits.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final savedCalculationsRepositoryProvider =
    Provider<SavedCalculationsRepository>((ref) {
      final preferences = ref.watch(sharedPreferencesProvider);
      return SharedPreferencesSavedCalculationsRepository(
        SharedPreferencesSavedCalculationsStorage(preferences),
      );
    });

class SavedCalculationsLoadResult {
  const SavedCalculationsLoadResult({
    required this.items,
    required this.skippedItemCount,
  });

  final List<SavedCalculation> items;
  final int skippedItemCount;
}

abstract interface class SavedCalculationsRepository {
  SavedCalculationsLoadResult load();
  Future<void> add(SavedCalculation item);
  Future<void> delete(String id);
  Future<void> clear();
  Future<void> setFavorite(String id, bool isFavorite, DateTime updatedAt);
}

abstract interface class SavedCalculationsStorage {
  String? read(String key);
  Future<bool> write(String key, String value);
  Future<bool> remove(String key);
}

class SharedPreferencesSavedCalculationsStorage
    implements SavedCalculationsStorage {
  const SharedPreferencesSavedCalculationsStorage(this.preferences);

  final SharedPreferences preferences;

  @override
  String? read(String key) => preferences.getString(key);

  @override
  Future<bool> write(String key, String value) =>
      preferences.setString(key, value);

  @override
  Future<bool> remove(String key) => preferences.remove(key);
}

class SharedPreferencesSavedCalculationsRepository
    implements SavedCalculationsRepository {
  const SharedPreferencesSavedCalculationsRepository(this.storage);

  final SavedCalculationsStorage storage;

  static const storageKey = 'saved_calculations.repository.v1';

  @override
  SavedCalculationsLoadResult load() {
    final String? source;
    try {
      source = storage.read(storageKey);
    } on Object catch (error) {
      throw SavedCalculationsException(
        SavedCalculationsIssue.storageRead,
        error,
      );
    }
    if (source == null || source.isEmpty) {
      return const SavedCalculationsLoadResult(items: [], skippedItemCount: 0);
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, Object?>) {
        throw const SavedCalculationsException(
          SavedCalculationsIssue.invalidPayload,
        );
      }
      if (decoded['schemaVersion'] != SavedCalculationsLimits.schemaVersion) {
        throw const SavedCalculationsException(
          SavedCalculationsIssue.invalidSchema,
        );
      }
      final rawItems = decoded['items'];
      if (rawItems is! List<Object?>) {
        throw const SavedCalculationsException(
          SavedCalculationsIssue.invalidPayload,
        );
      }
      final items = <SavedCalculation>[];
      var skipped = 0;
      for (final rawItem in rawItems) {
        try {
          if (rawItem is! Map) throw const FormatException();
          items.add(
            SavedCalculation.fromJson(Map<String, Object?>.from(rawItem)),
          );
        } on Object {
          skipped++;
        }
      }
      return SavedCalculationsLoadResult(
        items: List.unmodifiable(items),
        skippedItemCount: skipped,
      );
    } on SavedCalculationsException {
      rethrow;
    } on Object catch (error) {
      throw SavedCalculationsException(
        SavedCalculationsIssue.invalidPayload,
        error,
      );
    }
  }

  @override
  Future<void> add(SavedCalculation item) async {
    final current = load().items;
    await _write([item, ...current]);
  }

  @override
  Future<void> delete(String id) async {
    final current = load().items;
    await _write(current.where((item) => item.id != id).toList());
  }

  @override
  Future<void> setFavorite(
    String id,
    bool isFavorite,
    DateTime updatedAt,
  ) async {
    final current = load().items;
    await _write([
      for (final item in current)
        if (item.id == id)
          item.copyWith(isFavorite: isFavorite, updatedAt: updatedAt)
        else
          item,
    ]);
  }

  @override
  Future<void> clear() async {
    try {
      final succeeded = await storage.remove(storageKey);
      if (!succeeded) {
        throw const SavedCalculationsException(
          SavedCalculationsIssue.storageWrite,
        );
      }
    } on SavedCalculationsException {
      rethrow;
    } on Object catch (error) {
      throw SavedCalculationsException(
        SavedCalculationsIssue.storageWrite,
        error,
      );
    }
  }

  Future<void> _write(List<SavedCalculation> items) async {
    final payload = jsonEncode({
      'schemaVersion': SavedCalculationsLimits.schemaVersion,
      'items': items.map((item) => item.toJson()).toList(),
    });
    try {
      final succeeded = await storage.write(storageKey, payload);
      if (!succeeded) {
        throw const SavedCalculationsException(
          SavedCalculationsIssue.storageWrite,
        );
      }
    } on SavedCalculationsException {
      rethrow;
    } on Object catch (error) {
      throw SavedCalculationsException(
        SavedCalculationsIssue.storageWrite,
        error,
      );
    }
  }
}

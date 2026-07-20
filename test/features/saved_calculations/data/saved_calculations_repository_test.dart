import 'dart:convert';

import 'package:calcademy/features/saved_calculations/data/saved_calculations_repository.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_failure.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_limits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeStorage storage;
  late SharedPreferencesSavedCalculationsRepository repository;

  setUp(() {
    storage = _FakeStorage();
    repository = SharedPreferencesSavedCalculationsRepository(storage);
  });

  test('saves, loads, and preserves newest-first insertion order', () async {
    await repository.add(_item('old', DateTime.utc(2026, 1, 1)));
    await repository.add(_item('new', DateTime.utc(2026, 2, 1)));

    expect(repository.load().items.map((item) => item.id), ['new', 'old']);
  });

  test('deletes, clears, and updates favorite state', () async {
    await repository.add(_item('a', DateTime.utc(2026, 1, 1)));
    await repository.add(_item('b', DateTime.utc(2026, 1, 2)));
    await repository.setFavorite('a', true, DateTime.utc(2026, 3, 1));
    expect(
      repository.load().items.singleWhere((item) => item.id == 'a').isFavorite,
      isTrue,
    );

    await repository.delete('b');
    expect(repository.load().items.map((item) => item.id), ['a']);
    await repository.clear();
    expect(repository.load().items, isEmpty);
  });

  test('skips a corrupt item while preserving valid records', () {
    storage.values[SharedPreferencesSavedCalculationsRepository.storageKey] =
        jsonEncode({
          'schemaVersion': SavedCalculationsLimits.schemaVersion,
          'items': [
            _item('valid', DateTime.utc(2026)).toJson(),
            {'bad': true},
          ],
        });

    final loaded = repository.load();
    expect(loaded.items.single.id, 'valid');
    expect(loaded.skippedItemCount, 1);
  });

  test('maps invalid envelope schema and corrupt JSON to typed failures', () {
    storage.values[SharedPreferencesSavedCalculationsRepository.storageKey] =
        jsonEncode({'schemaVersion': 99, 'items': []});
    expect(
      repository.load,
      throwsA(
        isA<SavedCalculationsException>().having(
          (error) => error.issue,
          'issue',
          SavedCalculationsIssue.invalidSchema,
        ),
      ),
    );

    storage.values[SharedPreferencesSavedCalculationsRepository.storageKey] =
        '{broken';
    expect(
      repository.load,
      throwsA(
        isA<SavedCalculationsException>().having(
          (error) => error.issue,
          'issue',
          SavedCalculationsIssue.invalidPayload,
        ),
      ),
    );
  });

  test('maps storage read and write failures', () async {
    storage.throwOnRead = true;
    expect(
      repository.load,
      throwsA(
        isA<SavedCalculationsException>().having(
          (error) => error.issue,
          'issue',
          SavedCalculationsIssue.storageRead,
        ),
      ),
    );

    storage.throwOnRead = false;
    storage.writeSucceeds = false;
    await expectLater(
      repository.add(_item('a', DateTime.utc(2026))),
      throwsA(
        isA<SavedCalculationsException>().having(
          (error) => error.issue,
          'issue',
          SavedCalculationsIssue.storageWrite,
        ),
      ),
    );
  });
}

SavedCalculation _item(String id, DateTime createdAt) => SavedCalculation(
  id: id,
  title: id,
  module: SavedCalculationModule.statistics,
  calculationType: 'descriptive',
  createdAt: createdAt,
  updatedAt: createdAt,
  isFavorite: false,
  inputSummary: '1, 2, 3',
  resultSummary: 'Mean: 2',
  fullInputJson: const {},
  resultJson: const {},
  tags: const [],
);

class _FakeStorage implements SavedCalculationsStorage {
  final values = <String, String>{};
  bool throwOnRead = false;
  bool writeSucceeds = true;

  @override
  String? read(String key) {
    if (throwOnRead) throw StateError('read failed');
    return values[key];
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return writeSucceeds;
  }

  @override
  Future<bool> write(String key, String value) async {
    if (!writeSucceeds) return false;
    values[key] = value;
    return true;
  }
}

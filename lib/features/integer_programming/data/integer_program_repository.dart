import 'dart:convert';

import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/integer_programming/domain/saved_integer_program.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final integerProgramRepositoryProvider = Provider<IntegerProgramRepository>(
  (ref) => IntegerProgramRepository(ref.watch(sharedPreferencesProvider)),
);

final savedIntegerProgramsProvider =
    NotifierProvider<SavedIntegerProgramsController, List<SavedIntegerProgram>>(
      SavedIntegerProgramsController.new,
    );

class SavedIntegerProgramsController
    extends Notifier<List<SavedIntegerProgram>> {
  IntegerProgramRepository get _repository =>
      ref.read(integerProgramRepositoryProvider);

  @override
  List<SavedIntegerProgram> build() =>
      ref.watch(integerProgramRepositoryProvider).load();

  SavedIntegerProgram? find(String id) {
    for (final item in state) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> upsert(SavedIntegerProgram value) async {
    final exists = state.any((item) => item.id == value.id);
    state = exists
        ? [
            for (final item in state)
              if (item.id == value.id) value else item,
          ]
        : [value, ...state];
    await _repository.save(state);
  }

  Future<void> delete(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _repository.save(state);
  }
}

class IntegerProgramRepository {
  const IntegerProgramRepository(this.preferences);
  static const savedKey = 'integer_programming.saved';
  final SharedPreferences preferences;

  List<SavedIntegerProgram> load() {
    final source = preferences.getString(savedKey);
    if (source == null) return [];
    try {
      return (jsonDecode(source) as List<Object?>)
          .map(
            (item) => SavedIntegerProgram.fromJson(
              Map<String, Object?>.from(item! as Map),
            ),
          )
          .toList();
    } on Object {
      return [];
    }
  }

  Future<void> save(List<SavedIntegerProgram> values) => preferences.setString(
    savedKey,
    jsonEncode(values.map((item) => item.toJson()).toList()),
  );
}

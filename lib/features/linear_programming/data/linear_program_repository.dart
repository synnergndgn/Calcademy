import 'dart:convert';

import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/linear_programming/domain/saved_linear_program.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final linearProgramRepositoryProvider = Provider<LinearProgramRepository>(
  (ref) => LinearProgramRepository(ref.watch(sharedPreferencesProvider)),
);

final savedLinearProgramsProvider =
    NotifierProvider<SavedLinearProgramsController, List<SavedLinearProgram>>(
      SavedLinearProgramsController.new,
    );

class SavedLinearProgramsController extends Notifier<List<SavedLinearProgram>> {
  LinearProgramRepository get _repository =>
      ref.read(linearProgramRepositoryProvider);

  @override
  List<SavedLinearProgram> build() =>
      ref.watch(linearProgramRepositoryProvider).load();

  SavedLinearProgram? find(String id) {
    for (final item in state) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> upsert(SavedLinearProgram value) async {
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

class LinearProgramRepository {
  const LinearProgramRepository(this.preferences);
  static const savedKey = 'linear_programming.saved';
  final SharedPreferences preferences;

  List<SavedLinearProgram> load() {
    final source = preferences.getString(savedKey);
    if (source == null) return [];
    try {
      return (jsonDecode(source) as List<Object?>)
          .map(
            (item) => SavedLinearProgram.fromJson(
              Map<String, Object?>.from(item! as Map),
            ),
          )
          .toList();
    } on Object {
      return [];
    }
  }

  Future<void> save(List<SavedLinearProgram> values) => preferences.setString(
    savedKey,
    jsonEncode(values.map((item) => item.toJson()).toList()),
  );
}

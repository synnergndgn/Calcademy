import 'dart:convert';

import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/matrix/domain/saved_matrix_operation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final matrixRepositoryProvider = Provider<MatrixRepository>(
  (ref) => MatrixRepository(ref.watch(sharedPreferencesProvider)),
);

final savedMatricesProvider =
    NotifierProvider<SavedMatricesController, List<SavedMatrixOperation>>(
      SavedMatricesController.new,
    );

class SavedMatricesController extends Notifier<List<SavedMatrixOperation>> {
  MatrixRepository get _repository => ref.read(matrixRepositoryProvider);

  @override
  List<SavedMatrixOperation> build() =>
      ref.watch(matrixRepositoryProvider).load();

  SavedMatrixOperation? find(String id) {
    for (final item in state) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> upsert(SavedMatrixOperation operation) async {
    final exists = state.any((item) => item.id == operation.id);
    state = exists
        ? [
            for (final item in state)
              if (item.id == operation.id) operation else item,
          ]
        : [operation, ...state];
    await _repository.save(state);
  }

  Future<void> delete(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _repository.save(state);
  }
}

class MatrixRepository {
  const MatrixRepository(this.preferences);

  static const savedMatricesKey = 'matrix.saved';
  final SharedPreferences preferences;

  List<SavedMatrixOperation> load() {
    final source = preferences.getString(savedMatricesKey);
    if (source == null) return [];
    try {
      return (jsonDecode(source) as List<Object?>)
          .whereType<Map<String, Object?>>()
          .map(SavedMatrixOperation.fromJson)
          .toList();
    } on Object {
      return [];
    }
  }

  Future<void> save(List<SavedMatrixOperation> operations) =>
      preferences.setString(
        savedMatricesKey,
        jsonEncode(operations.map((item) => item.toJson()).toList()),
      );
}

import 'dart:convert';

import 'package:calcademy/features/matrix/data/matrix_repository.dart';
import 'package:calcademy/features/matrix/domain/matrix_operation.dart';
import 'package:calcademy/features/matrix/domain/matrix_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_value.dart';
import 'package:calcademy/features/matrix/domain/saved_matrix_operation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saves, loads, updates, and deletes matrix records', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = MatrixRepository(preferences);
    final saved = _saved('matrix-1', 'First');

    await repository.save([saved]);
    expect(repository.load().single.title, 'First');

    await repository.save([saved.copyWith(title: 'Updated')]);
    expect(repository.load().single.title, 'Updated');

    await repository.save([]);
    expect(repository.load(), isEmpty);
  });

  test('saved matrix JSON round-trips', () {
    final saved = _saved('matrix-json', 'Round trip');
    final decoded = SavedMatrixOperation.fromJson(
      jsonDecode(jsonEncode(saved.toJson())) as Map<String, Object?>,
    );
    expect(decoded.id, saved.id);
    expect(decoded.type, saved.type);
    expect(decoded.inputs.single, saved.inputs.single);
    expect((decoded.result as ScalarMatrixResult).value, 5);
  });

  test('matrix writes preserve calculator and graph preference keys', () async {
    SharedPreferences.setMockInitialValues({
      'calculator.saved': 'calculator-data',
      'graph.saved': 'graph-data',
    });
    final preferences = await SharedPreferences.getInstance();
    await MatrixRepository(preferences).save([_saved('matrix-2', 'Saved')]);

    expect(preferences.getString('calculator.saved'), 'calculator-data');
    expect(preferences.getString('graph.saved'), 'graph-data');
    expect(preferences.getString(MatrixRepository.savedMatricesKey), isNotNull);
  });
}

SavedMatrixOperation _saved(String id, String title) => SavedMatrixOperation(
  id: id,
  title: title,
  type: MatrixOperationType.trace,
  inputs: [
    MatrixValue(const [
      [1, 2],
      [3, 4],
    ]),
  ],
  result: const ScalarMatrixResult(5),
  createdAt: DateTime(2026, 7, 17),
);

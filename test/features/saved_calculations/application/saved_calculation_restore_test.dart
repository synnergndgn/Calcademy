import 'package:calcademy/features/saved_calculations/application/saved_calculation_restore.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculator restore route carries the saved expression', () {
    final item = _item(
      module: SavedCalculationModule.scientificCalculator,
      input: const {'expression': 'sin(30) + 2'},
    );

    expect(
      savedCalculationRestoreRoute(item),
      '/calculator?expression=sin%2830%29+%2B+2',
    );
  });

  test('graph restore route is exposed only for a complete configuration', () {
    final restorable = _item(
      module: SavedCalculationModule.graphPlotter,
      input: const {
        'expressions': ['x^2'],
        'xRange': {'min': -5.0, 'max': 7.0},
        'autoY': false,
        'yRange': {'min': -3.0, 'max': 12.0},
        'angleMode': 'degrees',
      },
    );
    final incomplete = _item(
      id: 'old-graph',
      module: SavedCalculationModule.graphPlotter,
      input: const {
        'expressions': ['x^2'],
      },
    );

    expect(
      savedCalculationRestoreRoute(restorable),
      '/graph?savedCalculationId=saved-1',
    );
    expect(savedCalculationRestoreRoute(incomplete), isNull);
  });

  test('matrix restore rejects old dimension-only archives', () {
    final restorable = _item(
      module: SavedCalculationModule.matrix,
      input: const {
        'operation': 'determinant',
        'inputs': [
          {
            'rows': 2,
            'columns': 2,
            'values': [
              [1.0, 2.0],
              [3.0, 4.0],
            ],
          },
        ],
        'inputDimensions': [
          {'rows': 2, 'columns': 2},
        ],
      },
    );
    final oldArchive = _item(
      id: 'old-matrix',
      module: SavedCalculationModule.matrix,
      input: const {
        'operation': 'determinant',
        'inputDimensions': [
          {'rows': 2, 'columns': 2},
        ],
      },
    );

    expect(
      savedCalculationRestoreRoute(restorable),
      '/matrix?savedCalculationId=saved-1',
    );
    expect(savedCalculationRestoreRoute(oldArchive), isNull);
  });

  test('result-only optimization archives never open an empty module', () {
    final item = _item(
      module: SavedCalculationModule.linearProgramming,
      input: const {'variableCount': 2, 'constraintCount': 1},
    );

    expect(savedCalculationRestoreRoute(item), isNull);
  });
}

SavedCalculation _item({
  String id = 'saved-1',
  required SavedCalculationModule module,
  required Map<String, Object?> input,
}) => SavedCalculation(
  id: id,
  title: 'Saved item',
  module: module,
  calculationType: 'test',
  createdAt: DateTime.utc(2026, 7, 24),
  updatedAt: DateTime.utc(2026, 7, 24),
  isFavorite: false,
  inputSummary: 'input',
  resultSummary: 'result',
  fullInputJson: input,
  resultJson: const {},
  tags: const [],
);

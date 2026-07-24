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
    final lp = _item(
      module: SavedCalculationModule.linearProgramming,
      input: const {'variableCount': 2, 'constraintCount': 1},
    );
    final ip = _item(
      module: SavedCalculationModule.integerProgramming,
      input: const {'variableCount': 2},
    );
    final or = _item(
      module: SavedCalculationModule.operationsResearch,
      input: const {'model': 'transportation'},
    );

    expect(savedCalculationRestoreRoute(lp), isNull);
    expect(savedCalculationRestoreRoute(ip), isNull);
    expect(savedCalculationRestoreRoute(or), isNull);
  });

  group('equation solver', () {
    test('single-equation route is exposed for a restorable payload', () {
      final item = _item(
        module: SavedCalculationModule.equationSolver,
        type: 'singleEquation',
        input: const {'equation': 'x^2 - 4 = 0', 'method': 'analytic'},
      );

      expect(
        savedCalculationRestoreRoute(item),
        '/equation-solver?savedCalculationId=saved-1',
      );
    });

    test('linear system without coefficients stays result-only', () {
      final item = _item(
        module: SavedCalculationModule.equationSolver,
        type: 'linearSystem',
        input: const {'dimension': 2},
      );

      expect(savedCalculationRestoreRoute(item), isNull);
    });
  });

  group('calculus', () {
    test('differentiation route is exposed for a restorable payload', () {
      final item = _item(
        module: SavedCalculationModule.calculus,
        type: 'differentiation',
        input: const {
          'function': 'x^2',
          'point': 1.0,
          'method': 'central',
          'stepSize': 0.001,
        },
      );

      expect(
        savedCalculationRestoreRoute(item),
        '/calculus?savedCalculationId=saved-1',
      );
    });

    test('malformed integration payload stays result-only', () {
      final item = _item(
        module: SavedCalculationModule.calculus,
        type: 'integration',
        // lower >= upper is rejected.
        input: const {
          'function': 'x^2',
          'lowerBound': 5.0,
          'upperBound': 1.0,
          'method': 'simpson13',
          'subintervals': 4,
        },
      );

      expect(savedCalculationRestoreRoute(item), isNull);
    });
  });

  group('statistics', () {
    test('descriptive route is exposed when the dataset is stored', () {
      final item = _item(
        module: SavedCalculationModule.statistics,
        type: 'descriptive',
        input: const {
          'count': 3,
          'values': [1.0, 2.0, 3.0],
        },
      );

      expect(
        savedCalculationRestoreRoute(item),
        '/statistics?savedCalculationId=saved-1',
      );
    });

    test('descriptive count-only archive stays result-only', () {
      final item = _item(
        module: SavedCalculationModule.statistics,
        type: 'descriptive',
        input: const {'count': 900},
      );

      expect(savedCalculationRestoreRoute(item), isNull);
    });

    test('legacy distribution without operation key stays result-only', () {
      final item = _item(
        module: SavedCalculationModule.statistics,
        type: 'binomial',
        // No `operation` key: ≤ / ≥ / = cannot be recovered.
        input: const {'n': 10.0, 'p': 0.5, 'k': 3.0},
      );

      expect(savedCalculationRestoreRoute(item), isNull);
    });
  });

  group('financial calculator', () {
    test('tvm route is exposed when the operation key is present', () {
      final item = _item(
        module: SavedCalculationModule.financialCalculator,
        type: 'tvm',
        input: const {
          'operation': 'presentValue',
          'futureValue': 1000.0,
          'ratePercent': 10.0,
          'periodCount': 5.0,
          'frequency': 1.0,
        },
      );

      expect(
        savedCalculationRestoreRoute(item),
        '/financial-calculator?savedCalculationId=saved-1',
      );
    });

    test('legacy tvm without operation key stays result-only', () {
      final item = _item(
        module: SavedCalculationModule.financialCalculator,
        type: 'tvm',
        input: const {
          'futureValue': 1000.0,
          'ratePercent': 10.0,
          'periodCount': 5.0,
          'frequency': 1.0,
        },
      );

      expect(savedCalculationRestoreRoute(item), isNull);
    });

    test('npv without a stored cash-flow list stays result-only', () {
      final item = _item(
        module: SavedCalculationModule.financialCalculator,
        type: 'npv',
        input: const {'initialInvestment': 1000.0, 'discountRatePercent': 10.0},
      );

      expect(savedCalculationRestoreRoute(item), isNull);
    });
  });
}

SavedCalculation _item({
  String id = 'saved-1',
  required SavedCalculationModule module,
  required Map<String, Object?> input,
  String type = 'test',
}) => SavedCalculation(
  id: id,
  title: 'Saved item',
  module: module,
  calculationType: type,
  createdAt: DateTime.utc(2026, 7, 24),
  updatedAt: DateTime.utc(2026, 7, 24),
  isFavorite: false,
  inputSummary: 'input',
  resultSummary: 'result',
  fullInputJson: input,
  resultJson: const {},
  tags: const [],
);

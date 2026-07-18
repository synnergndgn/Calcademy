import 'package:calcademy/features/matrix/domain/linear_system_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_engine.dart';
import 'package:calcademy/features/matrix/domain/matrix_error.dart';
import 'package:calcademy/features/matrix/domain/matrix_number_formatter.dart';
import 'package:calcademy/features/matrix/domain/matrix_value.dart';
import 'package:calcademy/features/matrix/domain/row_operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = MatrixEngine();

  group('MatrixEngine basic operations', () {
    test('adds matrices', () {
      expect(
        engine.add(
          _m([
            [1, 2],
            [3, 4],
          ]),
          _m([
            [5, 6],
            [7, 8],
          ]),
        ),
        _m([
          [6, 8],
          [10, 12],
        ]),
      );
    });

    test('subtracts matrices', () {
      expect(
        engine.subtract(
          _m([
            [5, 6],
            [7, 8],
          ]),
          _m([
            [1, 2],
            [3, 4],
          ]),
        ),
        _m([
          [4, 4],
          [4, 4],
        ]),
      );
    });

    test('multiplies by a scalar', () {
      expect(
        engine.scalarMultiply(
          _m([
            [1, -2],
          ]),
          -3,
        ),
        _m([
          [-3, 6],
        ]),
      );
    });

    test('multiplies matrices', () {
      expect(
        engine.multiply(
          _m([
            [1, 2],
            [3, 4],
          ]),
          _m([
            [2, 0],
            [1, 2],
          ]),
        ),
        _m([
          [4, 4],
          [10, 8],
        ]),
      );
    });

    test('transposes a matrix', () {
      expect(
        engine.transpose(
          _m([
            [1, 2, 3],
            [4, 5, 6],
          ]),
        ),
        _m([
          [1, 4],
          [2, 5],
          [3, 6],
        ]),
      );
    });

    test('calculates trace', () {
      expect(
        engine.trace(
          _m([
            [1, 2],
            [3, 4],
          ]),
        ),
        5,
      );
    });
  });

  group('determinant, inverse, and rank', () {
    test('calculates 1x1 determinant', () {
      expect(
        engine.determinant(
          _m([
            [7],
          ]),
        ),
        7,
      );
    });

    test('calculates 2x2 determinant', () {
      expect(
        engine.determinant(
          _m([
            [4, 7],
            [2, 6],
          ]),
        ),
        10,
      );
    });

    test('calculates 3x3 determinant by elimination', () {
      expect(
        engine.determinant(
          _m([
            [1, 2, 3],
            [0, 4, 5],
            [1, 0, 6],
          ]),
        ),
        closeTo(22, 1e-9),
      );
    });

    test('returns zero for singular determinant', () {
      expect(
        engine.determinant(
          _m([
            [1, 2],
            [2, 4],
          ]),
        ),
        0,
      );
    });

    test('calculates inverse with Gauss-Jordan', () {
      expect(
        engine.inverse(
          _m([
            [4, 7],
            [2, 6],
          ]),
        ),
        _m([
          [0.6, -0.7],
          [-0.2, 0.4],
        ]),
      );
    });

    test('rejects inverse of a singular matrix', () {
      expect(
        () => engine.inverse(
          _m([
            [1, 2],
            [2, 4],
          ]),
        ),
        throwsA(_matrixError(MatrixErrorCode.singular)),
      );
    });

    test('calculates rank with epsilon', () {
      expect(
        engine.rank(
          _m([
            [1, 2, 3],
            [2, 4, 6],
          ]),
        ),
        1,
      );
    });
  });

  group('row reduction', () {
    test('produces row echelon form', () {
      final result = engine.rowEchelon(
        _m([
          [1, 2],
          [2, 4],
        ]),
      );
      expect(
        result.result,
        _m([
          [1, 2],
          [0, 0],
        ]),
      );
    });

    test('produces reduced row echelon form', () {
      final result = engine.reducedRowEchelon(
        _m([
          [1, 2, 3],
          [0, 1, 2],
        ]),
      );
      expect(
        result.result,
        _m([
          [1, 0, -1],
          [0, 1, 2],
        ]),
      );
    });

    test('records a row swap', () {
      final result = engine.rowEchelon(
        _m([
          [0, 1],
          [2, 3],
        ]),
      );
      expect(result.operations.whereType<SwapRows>(), isNotEmpty);
    });

    test('records row scaling', () {
      final result = engine.rowEchelon(
        _m([
          [2, 1],
          [0, 1],
        ]),
      );
      expect(result.operations.whereType<ScaleRow>(), isNotEmpty);
    });

    test('records row addition', () {
      final result = engine.rowEchelon(
        _m([
          [1, 1],
          [2, 3],
        ]),
      );
      expect(result.operations.whereType<AddRowMultiple>(), isNotEmpty);
    });

    test('last step equals the reported result', () {
      final result = engine.reducedRowEchelon(
        _m([
          [1, 2],
          [3, 4],
        ]),
      );
      expect(result.matrixAt(result.operations.length), result.result);
    });

    test('replay reaches the same final matrix', () {
      final result = engine.reducedRowEchelon(
        _m([
          [0, 2, 4],
          [1, 1, 3],
        ]),
      );
      expect(result.replay(), result.result);
    });
  });

  group('dimension validation', () {
    test('rejects incompatible addition', () {
      expect(
        () => engine.add(
          _m([
            [1, 2],
          ]),
          _m([
            [1],
            [2],
          ]),
        ),
        throwsA(_matrixError(MatrixErrorCode.incompatibleDimensions)),
      );
    });

    test('rejects incompatible multiplication', () {
      expect(
        () => engine.multiply(
          _m([
            [1, 2],
          ]),
          _m([
            [1, 2],
          ]),
        ),
        throwsA(_matrixError(MatrixErrorCode.incompatibleDimensions)),
      );
    });

    test('rejects determinant for a non-square matrix', () {
      expect(
        () => engine.determinant(
          _m([
            [1, 2, 3],
          ]),
        ),
        throwsA(_matrixError(MatrixErrorCode.squareRequired)),
      );
    });

    test('rejects inverse for a non-square matrix', () {
      expect(
        () => engine.inverse(
          _m([
            [1, 2, 3],
          ]),
        ),
        throwsA(_matrixError(MatrixErrorCode.squareRequired)),
      );
    });

    test('rejects trace for a non-square matrix', () {
      expect(
        () => engine.trace(
          _m([
            [1, 2, 3],
          ]),
        ),
        throwsA(_matrixError(MatrixErrorCode.squareRequired)),
      );
    });
  });

  group('linear systems', () {
    test('classifies and solves a unique solution', () {
      final solution = engine.solveLinearSystem(
        _m([
          [1, 2, 5],
          [3, -1, 4],
        ]),
      );
      expect(solution.result, isA<UniqueSolution>());
      final values = (solution.result as UniqueSolution).values;
      expect(values[0], closeTo(13 / 7, 1e-9));
      expect(values[1], closeTo(11 / 7, 1e-9));
    });

    test('classifies infinitely many solutions', () {
      final result = engine
          .solveLinearSystem(
            _m([
              [1, 2, 3],
              [2, 4, 6],
            ]),
          )
          .result;
      expect(result, isA<InfiniteSolutions>());
      expect((result as InfiniteSolutions).freeColumns, [1]);
    });

    test('classifies a system with no solution', () {
      final result = engine
          .solveLinearSystem(
            _m([
              [1, 2, 3],
              [2, 4, 7],
            ]),
          )
          .result;
      expect(result, isA<NoSolution>());
    });

    test('solves an overdetermined system with one solution', () {
      final result =
          engine
                  .solveLinearSystem(
                    _m([
                      [1, 1, 2],
                      [1, -1, 0],
                      [2, 0, 2],
                    ]),
                  )
                  .result
              as UniqueSolution;
      expect(result.values, orderedEquals([1, 1]));
    });

    test('classifies an underdetermined system as infinite', () {
      final result = engine
          .solveLinearSystem(
            _m([
              [1, 0, 1, 2],
              [0, 1, 1, 3],
            ]),
          )
          .result;
      expect(result, isA<InfiniteSolutions>());
      expect((result as InfiniteSolutions).freeColumns, [2]);
    });

    test('uses epsilon for a nearly-zero pivot', () {
      final result =
          engine
                  .solveLinearSystem(
                    _m([
                      [1e-12, 1, 2],
                      [1, 1, 3],
                    ]),
                  )
                  .result
              as UniqueSolution;
      expect(result.values[0], closeTo(1, 1e-8));
      expect(result.values[1], closeTo(2, 1e-8));
    });

    test('solves a system that requires a row swap', () {
      final solution = engine.solveLinearSystem(
        _m([
          [0, 1, 2],
          [1, 0, 3],
        ]),
      );
      expect((solution.result as UniqueSolution).values, orderedEquals([3, 2]));
      expect(solution.reduction.operations.whereType<SwapRows>(), isNotEmpty);
    });
  });

  group('value and input model', () {
    test('parses decimal and fraction input', () {
      expect(parseMatrixNumber('2.5'), 2.5);
      expect(parseMatrixNumber('1/2'), 0.5);
      expect(parseMatrixNumber('-7/4'), -1.75);
      expect(parseMatrixNumber(''), 0);
    });

    test('rejects invalid and infinite input', () {
      expect(() => parseMatrixNumber('abc'), throwsA(isA<MatrixException>()));
      expect(() => parseMatrixNumber('1/0'), throwsA(isA<MatrixException>()));
      expect(
        () => parseMatrixNumber('Infinity'),
        throwsA(isA<MatrixException>()),
      );
    });

    test('is immutable and JSON round-trips', () {
      final source = <List<double>>[
        [1, 2],
        [3, 4],
      ];
      final matrix = MatrixValue(source);
      source[0][0] = 99;
      final decoded = MatrixValue.fromJson(matrix.toJson());
      expect(matrix.at(0, 0), 1);
      expect(() => matrix.values[0][0] = 5, throwsUnsupportedError);
      expect(decoded, matrix);
    });

    test('cleans negative zero in formatting', () {
      expect(formatMatrixNumber(-0.0), '0');
      expect(formatMatrixNumber(1e-12), '0');
    });
  });
}

MatrixValue _m(List<List<num>> values) => MatrixValue([
  for (final row in values) [for (final value in row) value.toDouble()],
]);

Matcher _matrixError(MatrixErrorCode code) =>
    isA<MatrixException>().having((error) => error.code, 'code', code);

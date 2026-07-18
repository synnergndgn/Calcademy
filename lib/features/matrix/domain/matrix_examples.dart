import 'package:calcademy/features/matrix/domain/matrix_operation.dart';
import 'package:calcademy/features/matrix/domain/matrix_value.dart';

class MatrixExample {
  const MatrixExample({
    required this.titleKey,
    required this.operation,
    required this.inputs,
  });

  final String titleKey;
  final MatrixOperationType operation;
  final List<MatrixValue> inputs;
}

final matrixExamples = [
  MatrixExample(
    titleKey: 'matrixExampleMultiplication',
    operation: MatrixOperationType.multiply,
    inputs: [
      MatrixValue(const [
        [1, 2],
        [3, 4],
      ]),
      MatrixValue(const [
        [2, 0],
        [1, 2],
      ]),
    ],
  ),
  MatrixExample(
    titleKey: 'matrixExampleDeterminant',
    operation: MatrixOperationType.determinant,
    inputs: [
      MatrixValue(const [
        [1, 2, 3],
        [0, 4, 5],
        [1, 0, 6],
      ]),
    ],
  ),
  MatrixExample(
    titleKey: 'matrixExampleInverse',
    operation: MatrixOperationType.inverse,
    inputs: [
      MatrixValue(const [
        [4, 7],
        [2, 6],
      ]),
    ],
  ),
  MatrixExample(
    titleKey: 'matrixExampleUnique',
    operation: MatrixOperationType.solveLinearSystem,
    inputs: [
      MatrixValue(const [
        [1, 2, 5],
        [3, -1, 4],
      ]),
    ],
  ),
  MatrixExample(
    titleKey: 'matrixExampleInfinite',
    operation: MatrixOperationType.solveLinearSystem,
    inputs: [
      MatrixValue(const [
        [1, 2, 3],
        [2, 4, 6],
      ]),
    ],
  ),
  MatrixExample(
    titleKey: 'matrixExampleNone',
    operation: MatrixOperationType.solveLinearSystem,
    inputs: [
      MatrixValue(const [
        [1, 2, 3],
        [2, 4, 7],
      ]),
    ],
  ),
];

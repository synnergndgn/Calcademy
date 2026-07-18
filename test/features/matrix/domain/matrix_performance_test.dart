import 'package:calcademy/features/matrix/domain/linear_system_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_engine.dart';
import 'package:calcademy/features/matrix/domain/matrix_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = MatrixEngine();

  test('bounded 10x10 workloads complete promptly', () {
    final small = MatrixValue(const [
      [1, 2],
      [3, 4],
    ]);
    final medium = MatrixValue([
      for (var row = 0; row < 5; row++)
        [
          for (var column = 0; column < 5; column++)
            (row * 5 + column + 1).toDouble(),
        ],
    ]);
    final matrix = MatrixValue([
      for (var row = 0; row < 10; row++)
        [
          for (var column = 0; column < 10; column++)
            row == column ? 20.0 + row : ((row + column) % 5 - 2).toDouble(),
        ],
    ]);
    final identity = MatrixValue.identity(10);
    final augmented = MatrixValue([
      for (var row = 0; row < 10; row++)
        [...matrix.values[row], (row + 1).toDouble()],
    ]);

    final smallMultiplyTime = _measure(() => engine.multiply(small, small));
    final mediumMultiplyTime = _measure(
      () => engine.multiply(medium, MatrixValue.identity(5)),
    );
    final multiplyTime = _measure(() => engine.multiply(matrix, identity));
    final determinantTime = _measure(() => engine.determinant(matrix));
    final rrefTime = _measure(() => engine.reducedRowEchelon(matrix));
    late LinearSystemSolution solution;
    final solveTime = _measure(
      () => solution = engine.solveLinearSystem(augmented),
    );

    // Printed values are captured during the explicit performance verification.
    // ignore: avoid_print
    print(
      'matrix-performance-us '
      'multiply2=$smallMultiplyTime multiply5=$mediumMultiplyTime '
      'multiply10=$multiplyTime determinant10=$determinantTime '
      'rref=$rrefTime solve=$solveTime',
    );
    expect(solution.result, isA<UniqueSolution>());
    expect(multiplyTime, lessThan(1000000));
    expect(smallMultiplyTime, lessThan(1000000));
    expect(mediumMultiplyTime, lessThan(1000000));
    expect(determinantTime, lessThan(1000000));
    expect(rrefTime, lessThan(1000000));
    expect(solveTime, lessThan(1000000));
  });
}

int _measure(void Function() action) {
  final stopwatch = Stopwatch()..start();
  action();
  stopwatch.stop();
  return stopwatch.elapsedMicroseconds;
}

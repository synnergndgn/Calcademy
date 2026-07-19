import 'package:calcademy/features/equation_solver/application/linear_system_service.dart';
import 'package:calcademy/features/equation_solver/domain/equation_solver_result.dart';
import 'package:calcademy/features/matrix/domain/linear_system_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = LinearSystemService();

  test('2x2 unique solution: 2x+3y=7, x-y=1 gives x=2, y=1', () {
    final result =
        service.solve(
              [
                [2, 3],
                [1, -1],
              ],
              [7, 1],
            )
            as LinearSystemSolved;
    final unique = result.result as UniqueSolution;
    expect(unique.values[0], closeTo(2, 1e-9));
    expect(unique.values[1], closeTo(1, 1e-9));
  });

  test('3x3 unique solution', () {
    final result =
        service.solve(
              [
                [1, 1, 1],
                [0, 2, 5],
                [2, 5, -1],
              ],
              [6, -4, 27],
            )
            as LinearSystemSolved;
    final unique = result.result as UniqueSolution;
    expect(unique.values[0], closeTo(5, 1e-9));
    expect(unique.values[1], closeTo(3, 1e-9));
    expect(unique.values[2], closeTo(-2, 1e-9));
  });

  test('inconsistent system reports no solution', () {
    final result =
        service.solve(
              [
                [1, 1],
                [1, 1],
              ],
              [2, 3],
            )
            as LinearSystemSolved;
    expect(result.result, isA<NoSolution>());
  });

  test('dependent rows report infinitely many solutions', () {
    final result =
        service.solve(
              [
                [1, 1],
                [2, 2],
              ],
              [2, 4],
            )
            as LinearSystemSolved;
    expect(result.result, isA<InfiniteSolutions>());
  });

  test('a singular homogeneous-like matrix is classified, not crashed', () {
    final result = service.solve(
      [
        [0, 0],
        [0, 0],
      ],
      [0, 0],
    );
    expect(result, isA<LinearSystemSolved>());
    expect((result as LinearSystemSolved).result, isA<InfiniteSolutions>());
  });

  test('size outside 2..10 is rejected with a typed failure', () {
    final tooSmall =
        service.solve(
              [
                [1.0],
              ],
              [1],
            )
            as LinearSystemInvalid;
    expect(tooSmall.failure, EquationFailure.tooManyVariables);

    final elevenByEleven = List.generate(11, (_) => List<double>.filled(11, 1));
    final tooBig =
        service.solve(elevenByEleven, List.filled(11, 1))
            as LinearSystemInvalid;
    expect(tooBig.failure, EquationFailure.tooManyVariables);
  });

  test('non-finite input is rejected', () {
    final result =
        service.solve(
              [
                [double.nan, 1],
                [1, 2],
              ],
              [1, 2],
            )
            as LinearSystemInvalid;
    expect(result.failure, EquationFailure.invalidNumber);
  });
}

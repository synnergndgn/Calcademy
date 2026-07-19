import 'package:calcademy/features/equation_solver/domain/equation_solver_limits.dart';
import 'package:calcademy/features/equation_solver/domain/equation_solver_result.dart';
import 'package:calcademy/features/matrix/domain/linear_system_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_engine.dart';
import 'package:calcademy/features/matrix/domain/matrix_error.dart';
import 'package:calcademy/features/matrix/domain/matrix_value.dart';

/// Outcome of a linear-system solve: either the matrix module's own
/// (already tested) classification, or a typed validation failure.
sealed class LinearSystemServiceResult {
  const LinearSystemServiceResult();
}

class LinearSystemSolved extends LinearSystemServiceResult {
  const LinearSystemSolved(this.result);

  /// [UniqueSolution], [InfiniteSolutions] or [NoSolution] - reused
  /// directly from the matrix module rather than re-implementing the same
  /// elimination and epsilon-based classification a second time.
  final LinearSystemResult result;
}

class LinearSystemInvalid extends LinearSystemServiceResult {
  const LinearSystemInvalid(this.failure);

  final EquationFailure failure;
}

/// Solves an n×n system A·x = b by delegating to the matrix module's
/// Gaussian-elimination engine ([MatrixEngine.solveLinearSystem]), which
/// already distinguishes unique / infinite / no solution with
/// epsilon-based comparisons and is covered by its own test suite.
class LinearSystemService {
  const LinearSystemService();

  LinearSystemServiceResult solve(
    List<List<double>> coefficients,
    List<double> rhs,
  ) {
    final n = coefficients.length;
    if (n < EquationSolverLimits.minSystemSize ||
        n > EquationSolverLimits.maxSystemSize ||
        rhs.length != n ||
        coefficients.any((row) => row.length != n)) {
      return const LinearSystemInvalid(EquationFailure.tooManyVariables);
    }
    for (final row in coefficients) {
      if (row.any((value) => !value.isFinite)) {
        return const LinearSystemInvalid(EquationFailure.invalidNumber);
      }
    }
    if (rhs.any((value) => !value.isFinite)) {
      return const LinearSystemInvalid(EquationFailure.invalidNumber);
    }
    try {
      final augmented = MatrixValue([
        for (var row = 0; row < n; row++) [...coefficients[row], rhs[row]],
      ]);
      final solution = const MatrixEngine().solveLinearSystem(augmented);
      return LinearSystemSolved(solution.result);
    } on MatrixException {
      return const LinearSystemInvalid(EquationFailure.singularSystem);
    }
  }
}

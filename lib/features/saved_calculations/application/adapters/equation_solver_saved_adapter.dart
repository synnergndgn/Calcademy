import 'package:calcademy/features/equation_solver/application/linear_system_service.dart';
import 'package:calcademy/features/equation_solver/domain/equation_solver_result.dart';
import 'package:calcademy/features/matrix/domain/linear_system_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_number_formatter.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/saved_adapter_utils.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_limits.dart';

abstract final class EquationSolverSavedAdapter {
  static SavedCalculationDraft? trySingle({
    required String equation,
    required SingleEquationResult? result,
  }) {
    if (result == null || result is EquationSolveFailure) return null;
    return single(equation: equation, result: result);
  }

  static SavedCalculationDraft single({
    required String equation,
    required SingleEquationResult result,
  }) {
    requireSavedText(equation);
    if (result is EquationSolveFailure) invalidSavedAdapterOutput();
    final method = result.method.name;
    final input = truncateSavedText(
      equation,
      SavedCalculationsLimits.maxExpressionSummaryLength,
    );
    final resultData = <String, Object?>{'status': _singleStatus(result)};
    final summary = switch (result) {
      EquationRootsFound(:final roots) => () {
        requireFinite(roots.expand((root) => [root.value, root.residual]));
        resultData['roots'] = roots.map((root) => root.value).toList();
        resultData['maxResidual'] = roots
            .map((root) => root.residual)
            .fold<double>(0, (a, b) => a > b ? a : b);
        return 'roots: ${roots.map((root) => formatMatrixNumber(root.value)).join(', ')}';
      }(),
      EquationNoRealRoots(:final complexRootsPossible) =>
        complexRootsPossible
            ? 'no real roots; complex possible'
            : 'no real roots',
      EquationIdentity() => 'identity; every real number is a solution',
      EquationContradiction() => 'contradiction; no solution',
      EquationSolveFailure() => invalidSavedAdapterOutput(),
    };
    return SavedCalculationDraft(
      title: truncateSavedText(input, SavedCalculationsLimits.maxTitleLength),
      module: SavedCalculationModule.equationSolver,
      calculationType: 'singleEquation',
      inputSummary: '$input · method: $method',
      resultSummary: summary,
      fullInputJson: {'equation': input, 'method': method},
      resultJson: resultData,
    );
  }

  static SavedCalculationDraft? tryNumerical({
    required String function,
    required NumericalMethodResult? result,
    required List<double> initialValues,
  }) {
    if (result == null || !result.converged) return null;
    return numerical(
      function: function,
      result: result,
      initialValues: initialValues,
    );
  }

  static SavedCalculationDraft numerical({
    required String function,
    required NumericalMethodResult result,
    required List<double> initialValues,
  }) {
    requireSavedText(function);
    if (!result.converged || result.root == null || result.residual == null) {
      invalidSavedAdapterOutput();
    }
    requireFinite([...initialValues, result.root, result.residual]);
    final input = truncateSavedText(
      function,
      SavedCalculationsLimits.maxExpressionSummaryLength,
    );
    final guesses = initialValues.map(formatMatrixNumber).join(', ');
    return SavedCalculationDraft(
      title: truncateSavedText(input, SavedCalculationsLimits.maxTitleLength),
      module: SavedCalculationModule.equationSolver,
      calculationType: 'numericalMethod',
      inputSummary: '$input · ${result.method.name} · initial: $guesses',
      resultSummary:
          'root ≈ ${formatMatrixNumber(result.root!)} · iterations: ${result.iterations} · residual: ${result.residual!.toStringAsExponential(2)}',
      fullInputJson: {
        'function': input,
        'method': result.method.name,
        'initialValues': initialValues,
      },
      resultJson: {
        'root': result.root,
        'iterations': result.iterations,
        'residual': result.residual,
      },
    );
  }

  static SavedCalculationDraft? tryLinearSystem({
    required int dimension,
    required LinearSystemServiceResult? result,
  }) {
    if (result is! LinearSystemSolved) return null;
    return linearSystem(dimension: dimension, result: result);
  }

  static SavedCalculationDraft linearSystem({
    required int dimension,
    required LinearSystemSolved result,
  }) {
    if (dimension <= 0) invalidSavedAdapterOutput();
    final value = result.result;
    final resultJson = <String, Object?>{'status': _linearStatus(value)};
    final summary = switch (value) {
      UniqueSolution(:final values) => () {
        requireFinite(values);
        final limited = values
            .take(SavedCalculationsLimits.maxVariableSummaryCount)
            .toList();
        resultJson['values'] = limited;
        return 'unique solution: ${limited.map(formatMatrixNumber).join(', ')}${values.length > limited.length ? ', …' : ''}';
      }(),
      InfiniteSolutions() => 'infinitely many solutions',
      NoSolution() => 'no solution',
    };
    return SavedCalculationDraft(
      title: '$dimension×$dimension linear system',
      module: SavedCalculationModule.equationSolver,
      calculationType: 'linearSystem',
      inputSummary: 'dimension: $dimension×$dimension',
      resultSummary: summary,
      fullInputJson: {'dimension': dimension},
      resultJson: resultJson,
    );
  }

  static String _singleStatus(SingleEquationResult result) => switch (result) {
    EquationRootsFound() => 'rootsFound',
    EquationNoRealRoots() => 'noRealRoots',
    EquationIdentity() => 'identity',
    EquationContradiction() => 'contradiction',
    EquationSolveFailure() => 'failure',
  };

  static String _linearStatus(LinearSystemResult result) => switch (result) {
    UniqueSolution() => 'unique',
    InfiniteSolutions() => 'infinite',
    NoSolution() => 'none',
  };
}

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
    double? scanMin,
    double? scanMax,
  }) {
    if (result == null || result is EquationSolveFailure) return null;
    return single(
      equation: equation,
      result: result,
      scanMin: scanMin,
      scanMax: scanMax,
    );
  }

  static SavedCalculationDraft single({
    required String equation,
    required SingleEquationResult result,
    double? scanMin,
    double? scanMax,
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
      // The restore payload keeps the *untruncated* equation (summaries
      // above stay truncated); scan bounds make the record replayable.
      fullInputJson: {
        'equation': equation.trim(),
        'method': method,
        if (scanMin != null && scanMin.isFinite) 'scanMin': scanMin,
        if (scanMax != null && scanMax.isFinite) 'scanMax': scanMax,
      },
      resultJson: resultData,
    );
  }

  static SavedCalculationDraft? tryNumerical({
    required String function,
    required NumericalMethodResult? result,
    required List<double> initialValues,
    double? tolerance,
    int? maxIterations,
  }) {
    if (result == null || !result.converged) return null;
    return numerical(
      function: function,
      result: result,
      initialValues: initialValues,
      tolerance: tolerance,
      maxIterations: maxIterations,
    );
  }

  static SavedCalculationDraft numerical({
    required String function,
    required NumericalMethodResult result,
    required List<double> initialValues,
    double? tolerance,
    int? maxIterations,
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
        'function': function.trim(),
        'method': result.method.name,
        'initialValues': initialValues,
        if (tolerance != null && tolerance.isFinite) 'tolerance': tolerance,
        if (maxIterations != null && maxIterations > 0)
          'maxIterations': maxIterations,
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
    List<List<double>>? coefficients,
    List<double>? rhs,
  }) {
    if (result is! LinearSystemSolved) return null;
    return linearSystem(
      dimension: dimension,
      result: result,
      coefficients: coefficients,
      rhs: rhs,
    );
  }

  static SavedCalculationDraft linearSystem({
    required int dimension,
    required LinearSystemSolved result,
    List<List<double>>? coefficients,
    List<double>? rhs,
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
      fullInputJson: {
        'dimension': dimension,
        // Full input payload so the record can be reopened for editing;
        // legacy dimension-only records simply stay non-restorable.
        if (coefficients != null &&
            coefficients.length == dimension &&
            coefficients.every(
              (row) => row.length == dimension && row.every((v) => v.isFinite),
            ))
          'coefficients': coefficients,
        if (rhs != null &&
            rhs.length == dimension &&
            rhs.every((v) => v.isFinite))
          'rhs': rhs,
      },
      resultJson: resultJson,
    );
  }

  /// Parses a saved record back into editable inputs, or null when the
  /// payload cannot faithfully rebuild them. Legacy caveat: v1 records
  /// truncated the stored expression to the summary length, so a legacy
  /// expression at exactly that length may have lost characters - those
  /// records are treated as non-restorable rather than silently restoring
  /// an altered equation. (v2 records carry extra keys and are exempt.)
  static EquationSolverRestore? tryRestore(SavedCalculation item) {
    if (item.module != SavedCalculationModule.equationSolver) return null;
    final payload = item.fullInputJson;
    switch (item.calculationType) {
      case 'singleEquation':
        final equation = payload['equation'];
        if (equation is! String || equation.trim().isEmpty) return null;
        final isV2 = payload.containsKey('scanMin');
        if (!isV2 &&
            equation.length >=
                SavedCalculationsLimits.maxExpressionSummaryLength) {
          return null;
        }
        return EquationSolverRestore.single(
          equation: equation.trim(),
          scanMin: _finiteOrNull(payload['scanMin']),
          scanMax: _finiteOrNull(payload['scanMax']),
        );
      case 'numericalMethod':
        final function = payload['function'];
        final method = payload['method'];
        final rawValues = payload['initialValues'];
        if (function is! String || function.trim().isEmpty) return null;
        if (method is! String ||
            !const {'bisection', 'newtonRaphson', 'secant'}.contains(method)) {
          return null;
        }
        if (rawValues is! List || rawValues.isEmpty || rawValues.length > 2) {
          return null;
        }
        final values = <double>[];
        for (final value in rawValues) {
          final parsed = _finiteOrNull(value);
          if (parsed == null) return null;
          values.add(parsed);
        }
        final isV2 = payload.containsKey('tolerance');
        if (!isV2 &&
            function.length >=
                SavedCalculationsLimits.maxExpressionSummaryLength) {
          return null;
        }
        return EquationSolverRestore.numerical(
          function: function.trim(),
          method: method,
          initialValues: values,
          tolerance: _finiteOrNull(payload['tolerance']),
          maxIterations: switch (payload['maxIterations']) {
            final int value when value > 0 => value,
            _ => null,
          },
        );
      case 'linearSystem':
        final dimension = payload['dimension'];
        final rawCoefficients = payload['coefficients'];
        final rawRhs = payload['rhs'];
        if (dimension is! int || dimension < 2 || dimension > 10) return null;
        if (rawCoefficients is! List || rawCoefficients.length != dimension) {
          return null;
        }
        if (rawRhs is! List || rawRhs.length != dimension) return null;
        final coefficients = <List<double>>[];
        for (final rawRow in rawCoefficients) {
          if (rawRow is! List || rawRow.length != dimension) return null;
          final row = <double>[];
          for (final value in rawRow) {
            final parsed = _finiteOrNull(value);
            if (parsed == null) return null;
            row.add(parsed);
          }
          coefficients.add(row);
        }
        final rhs = <double>[];
        for (final value in rawRhs) {
          final parsed = _finiteOrNull(value);
          if (parsed == null) return null;
          rhs.add(parsed);
        }
        return EquationSolverRestore.linearSystem(
          coefficients: coefficients,
          rhs: rhs,
        );
      default:
        return null;
    }
  }

  static double? _finiteOrNull(Object? value) =>
      value is num && value.isFinite ? value.toDouble() : null;

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

enum EquationSolverRestoreMode { single, numerical, linearSystem }

/// Editable inputs rebuilt from a saved equation-solver record.
class EquationSolverRestore {
  const EquationSolverRestore.single({
    required String this.equation,
    this.scanMin,
    this.scanMax,
  }) : mode = EquationSolverRestoreMode.single,
       function = null,
       method = null,
       initialValues = const [],
       tolerance = null,
       maxIterations = null,
       coefficients = const [],
       rhs = const [];

  const EquationSolverRestore.numerical({
    required String this.function,
    required String this.method,
    required this.initialValues,
    this.tolerance,
    this.maxIterations,
  }) : mode = EquationSolverRestoreMode.numerical,
       equation = null,
       scanMin = null,
       scanMax = null,
       coefficients = const [],
       rhs = const [];

  const EquationSolverRestore.linearSystem({
    required this.coefficients,
    required this.rhs,
  }) : mode = EquationSolverRestoreMode.linearSystem,
       equation = null,
       scanMin = null,
       scanMax = null,
       function = null,
       method = null,
       initialValues = const [],
       tolerance = null,
       maxIterations = null;

  final EquationSolverRestoreMode mode;
  final String? equation;
  final double? scanMin;
  final double? scanMax;
  final String? function;
  final String? method;
  final List<double> initialValues;
  final double? tolerance;
  final int? maxIterations;
  final List<List<double>> coefficients;
  final List<double> rhs;
}

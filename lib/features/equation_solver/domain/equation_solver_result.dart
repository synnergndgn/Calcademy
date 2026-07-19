import 'dart:collection';

/// Which algorithm produced a result - shown in the result card so the
/// user always knows whether they are looking at an analytic (exact) or a
/// numerically refined (approximate) answer.
enum EquationSolveMethod {
  analyticLinear,
  analyticQuadratic,
  scanAndBisect,
  bisection,
  newtonRaphson,
  secant,
}

/// Typed reasons a solve could not produce a solution. The presentation
/// layer maps each to a localized, user-friendly message; raw exception
/// text never reaches the UI.
enum EquationFailure {
  emptyInput,
  invalidSyntax,
  unbalancedParentheses,
  unknownVariable,
  unknownFunction,
  invalidNumber,
  invalidInterval,
  invalidBracket,
  derivativeNearZero,
  maxIterationsReached,
  nonFiniteEvaluation,
  singularSystem,
  tooManyVariables,
}

/// One root with its quality metadata.
class EquationRoot {
  const EquationRoot({
    required this.value,
    required this.residual,
    required this.exact,
  });

  /// |f(root)| - zero for analytic roots, small for converged numeric ones.
  final double value;
  final double residual;
  final bool exact;
}

/// Result of solving a single equation f(x) = 0.
sealed class SingleEquationResult {
  SingleEquationResult({required this.method, List<String> warnings = const []})
    : warnings = UnmodifiableListView(warnings);

  final EquationSolveMethod method;

  /// Localization keys, e.g. `eqWarningPossibleDoubleRoot`.
  final List<String> warnings;
}

/// One or more real roots were found.
class EquationRootsFound extends SingleEquationResult {
  EquationRootsFound({
    required super.method,
    required List<EquationRoot> roots,
    this.scanMin,
    this.scanMax,
    super.warnings,
  }) : roots = UnmodifiableListView(roots);

  final List<EquationRoot> roots;

  /// The interval that was scanned, when the roots came from a numeric
  /// scan; null for analytic solutions (which are global).
  final double? scanMin;
  final double? scanMax;

  bool get exact => roots.every((root) => root.exact);
}

/// No real root exists (analytic proof) or none was found in the scanned
/// interval (numeric search).
class EquationNoRealRoots extends SingleEquationResult {
  EquationNoRealRoots({
    required super.method,
    required this.provenNone,
    this.complexRootsPossible = false,
    this.scanMin,
    this.scanMax,
    super.warnings,
  });

  /// True for the analytic quadratic case (negative discriminant): there
  /// is provably no real root. False for a scan that simply found none in
  /// its interval.
  final bool provenNone;
  final bool complexRootsPossible;
  final double? scanMin;
  final double? scanMax;
}

/// The equation reduces to 0 = 0: every real number is a solution.
class EquationIdentity extends SingleEquationResult {
  EquationIdentity({required super.method, super.warnings});
}

/// The equation reduces to a false constant statement (e.g. 5 = 7).
class EquationContradiction extends SingleEquationResult {
  EquationContradiction({required super.method, super.warnings});
}

/// The solve could not run or did not converge.
class EquationSolveFailure extends SingleEquationResult {
  EquationSolveFailure({
    required super.method,
    required this.failure,
    this.iterations,
    this.lastEstimate,
    super.warnings,
  });

  final EquationFailure failure;
  final int? iterations;
  final double? lastEstimate;
}

/// Result of one explicit numerical-method run (bisection / Newton /
/// secant), which reports its convergence trajectory in more detail than
/// the general single-equation flow.
class NumericalMethodResult {
  const NumericalMethodResult({
    required this.method,
    required this.converged,
    required this.iterations,
    this.root,
    this.residual,
    this.failure,
    this.lastEstimate,
  });

  final EquationSolveMethod method;
  final bool converged;
  final int iterations;
  final double? root;
  final double? residual;
  final EquationFailure? failure;
  final double? lastEstimate;
}

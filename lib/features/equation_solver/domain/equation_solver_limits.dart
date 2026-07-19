/// Central safety limits for the equation solver. Presentation reads these
/// instead of scattering magic numbers, and the services clamp user input
/// against them.
abstract final class EquationSolverLimits {
  /// Linear systems reuse the matrix engine, whose editor ceiling is 10.
  static const maxSystemSize = 10;
  static const minSystemSize = 2;

  /// Default root-scan interval when the user does not override it.
  static const defaultScanMin = -10.0;
  static const defaultScanMax = 10.0;

  /// Samples taken across the scan interval when bracketing sign changes.
  static const scanSampleCount = 400;

  static const maxIterationsCeiling = 500;
  static const defaultMaxIterations = 100;

  /// User-supplied tolerances are clamped to at least this value; below it
  /// double arithmetic cannot honour the request anyway.
  static const toleranceFloor = 1e-14;
  static const defaultTolerance = 1e-9;

  /// A candidate root whose |f(root)| exceeds this is rejected - it is a
  /// discontinuity (e.g. 1/x at 0), not a zero crossing.
  static const residualAcceptance = 1e-6;

  /// Roots closer together than this (relative to interval width) are
  /// merged as duplicates.
  static const rootMergeTolerance = 1e-6;
}

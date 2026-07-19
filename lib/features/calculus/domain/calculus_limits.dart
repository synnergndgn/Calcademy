/// Central limits for the calculus module - presentation and services
/// both read these instead of scattering magic numbers.
abstract final class CalculusLimits {
  static const minStepSize = 1e-10;
  static const maxStepSize = 1.0;
  static const defaultStepSize = 1e-5;

  static const minSubintervals = 2;
  static const maxSubintervals = 10000;
  static const defaultSubintervals = 100;

  static const defaultAnalysisMin = -10.0;
  static const defaultAnalysisMax = 10.0;

  /// Grid resolution used by function analysis sampling.
  static const analysisSampleCount = 400;
  static const maxSampleCount = 2000;

  /// |f'(x)| below this is treated as "flat" when classifying intervals.
  static const derivativeFlatTolerance = 1e-7;

  /// General comparison tolerance for classification decisions.
  static const tolerance = 1e-9;
}

abstract final class StatisticsLimits {
  static const maxDatasetSize = 10000;
  static const maxBinomialN = 1000;
  static const maxPoissonK = 10000;
  static const maxPoissonLambda = 1000.0;
  static const minConfidenceLevel = 0.80;
  static const maxConfidenceLevel = 0.999;
  static const supportedConfidenceLevels = [0.90, 0.95, 0.99];
  static const decimalTolerance = 1e-12;
  static const displayPrecision = 8;
}

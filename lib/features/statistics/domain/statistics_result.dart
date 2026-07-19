enum StatisticsIssue {
  emptyDataset,
  invalidNumber,
  ambiguousSeparator,
  datasetTooLarge,
  insufficientSample,
  invalidStandardDeviation,
  invalidProbability,
  invalidN,
  invalidK,
  kGreaterThanN,
  invalidLambda,
  invalidConfidenceLevel,
  unsupportedConfidenceLevel,
  invalidSampleSize,
  invalidSuccesses,
  successesGreaterThanN,
  calculationRange,
}

enum StatisticsWarning {
  sampleVarianceUnavailable,
  quartilesLimited,
  approximateProbability,
  normalAssumption,
  independentTrialsAssumption,
  poissonAssumption,
  knownSigmaAssumption,
  tPopulationAssumption,
  wilsonIndependentAssumption,
}

enum DistributionKind { normal, binomial, poisson }

enum NormalOperation { lessOrEqual, greaterOrEqual, between }

enum DiscreteOperation { equal, lessOrEqual, greaterOrEqual }

enum ConfidenceIntervalKind { knownSigmaMean, unknownSigmaMean, proportion }

sealed class StatisticsResult {
  const StatisticsResult({
    required this.methodKey,
    required this.inputs,
    required this.diagnostics,
    required this.warnings,
    required this.approximate,
  });

  final String methodKey;
  final Map<String, double> inputs;
  final List<String> diagnostics;
  final List<StatisticsWarning> warnings;
  final bool approximate;
}

class DescriptiveStatisticsResult extends StatisticsResult {
  const DescriptiveStatisticsResult({
    required this.values,
    required this.count,
    required this.sum,
    required this.mean,
    required this.median,
    required this.modes,
    required this.minimum,
    required this.maximum,
    required this.range,
    required this.populationVariance,
    required this.sampleVariance,
    required this.populationStandardDeviation,
    required this.sampleStandardDeviation,
    required this.q1,
    required this.q3,
    required this.iqr,
    required this.outliers,
    required super.warnings,
    super.methodKey = 'statsMethodDescriptive',
    super.inputs = const {},
    super.diagnostics = const ['statsDiagnosticQuartileMethod'],
    super.approximate = false,
  });

  final List<double> values;
  final int count;
  final double sum;
  final double mean;
  final double median;
  final List<double> modes;
  final double minimum;
  final double maximum;
  final double range;
  final double populationVariance;
  final double? sampleVariance;
  final double populationStandardDeviation;
  final double? sampleStandardDeviation;
  final double q1;
  final double q3;
  final double iqr;
  final List<double> outliers;
}

class DistributionResult extends StatisticsResult {
  const DistributionResult({
    required this.kind,
    required this.operationLabel,
    required this.probability,
    required super.methodKey,
    required super.inputs,
    required super.diagnostics,
    required super.warnings,
    super.approximate = true,
  });

  final DistributionKind kind;
  final String operationLabel;
  final double probability;
}

class ConfidenceIntervalResult extends StatisticsResult {
  const ConfidenceIntervalResult({
    required this.kind,
    required this.lowerBound,
    required this.upperBound,
    required this.marginOfError,
    required super.methodKey,
    required super.inputs,
    required super.diagnostics,
    required super.warnings,
    super.approximate = true,
  });

  final ConfidenceIntervalKind kind;
  final double lowerBound;
  final double upperBound;
  final double marginOfError;
}

class StatisticsFailureResult extends StatisticsResult {
  const StatisticsFailureResult(this.issue)
    : super(
        methodKey: 'statsCalculationFailed',
        inputs: const {},
        diagnostics: const [],
        warnings: const [],
        approximate: false,
      );

  final StatisticsIssue issue;
}

class StatisticsValidationException implements Exception {
  const StatisticsValidationException(this.issue);

  final StatisticsIssue issue;
}

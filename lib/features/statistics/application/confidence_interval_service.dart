import 'dart:math' as math;

import 'package:calcademy/features/statistics/domain/statistics_limits.dart';
import 'package:calcademy/features/statistics/domain/statistics_result.dart';

class ConfidenceIntervalService {
  const ConfidenceIntervalService();

  ConfidenceIntervalResult knownSigmaMean({
    required double sampleMean,
    required double sigma,
    required int sampleSize,
    required double confidenceLevel,
  }) {
    _validateCommon(sampleSize, confidenceLevel);
    if (!sampleMean.isFinite || !sigma.isFinite || sigma <= 0) {
      throw const StatisticsValidationException(
        StatisticsIssue.invalidStandardDeviation,
      );
    }
    final critical = _zCritical(confidenceLevel);
    final margin = critical * sigma / math.sqrt(sampleSize);
    return ConfidenceIntervalResult(
      kind: ConfidenceIntervalKind.knownSigmaMean,
      lowerBound: sampleMean - margin,
      upperBound: sampleMean + margin,
      marginOfError: margin,
      methodKey: 'statsMethodZInterval',
      inputs: {
        'mean': sampleMean,
        'sigma': sigma,
        'n': sampleSize.toDouble(),
        'confidence': confidenceLevel,
      },
      diagnostics: const ['statsDiagnosticTwoSided'],
      warnings: const [StatisticsWarning.knownSigmaAssumption],
    );
  }

  ConfidenceIntervalResult unknownSigmaMean({
    required double sampleMean,
    required double sampleStandardDeviation,
    required int sampleSize,
    required double confidenceLevel,
  }) {
    _validateCommon(sampleSize, confidenceLevel);
    if (sampleSize < 2) {
      throw const StatisticsValidationException(
        StatisticsIssue.insufficientSample,
      );
    }
    if (!sampleMean.isFinite ||
        !sampleStandardDeviation.isFinite ||
        sampleStandardDeviation <= 0) {
      throw const StatisticsValidationException(
        StatisticsIssue.invalidStandardDeviation,
      );
    }
    final critical = _tCritical(sampleSize - 1, confidenceLevel);
    final margin = critical * sampleStandardDeviation / math.sqrt(sampleSize);
    return ConfidenceIntervalResult(
      kind: ConfidenceIntervalKind.unknownSigmaMean,
      lowerBound: sampleMean - margin,
      upperBound: sampleMean + margin,
      marginOfError: margin,
      methodKey: 'statsMethodTInterval',
      inputs: {
        'mean': sampleMean,
        'sampleStd': sampleStandardDeviation,
        'n': sampleSize.toDouble(),
        'confidence': confidenceLevel,
      },
      diagnostics: const ['statsDiagnosticStudentTable'],
      warnings: const [StatisticsWarning.tPopulationAssumption],
    );
  }

  ConfidenceIntervalResult proportion({
    required int successes,
    required int sampleSize,
    required double confidenceLevel,
  }) {
    _validateCommon(sampleSize, confidenceLevel);
    if (successes < 0) {
      throw const StatisticsValidationException(
        StatisticsIssue.invalidSuccesses,
      );
    }
    if (successes > sampleSize) {
      throw const StatisticsValidationException(
        StatisticsIssue.successesGreaterThanN,
      );
    }
    final z = _zCritical(confidenceLevel);
    final zSquared = z * z;
    final n = sampleSize.toDouble();
    final observed = successes / n;
    final denominator = 1 + zSquared / n;
    final center = (observed + zSquared / (2 * n)) / denominator;
    final margin =
        z *
        math.sqrt(observed * (1 - observed) / n + zSquared / (4 * n * n)) /
        denominator;
    return ConfidenceIntervalResult(
      kind: ConfidenceIntervalKind.proportion,
      lowerBound: center - margin,
      upperBound: center + margin,
      marginOfError: margin,
      methodKey: 'statsMethodWilsonInterval',
      inputs: {
        'successes': successes.toDouble(),
        'n': n,
        'confidence': confidenceLevel,
      },
      diagnostics: const ['statsDiagnosticWilson'],
      warnings: const [StatisticsWarning.wilsonIndependentAssumption],
    );
  }

  static void _validateCommon(int sampleSize, double confidenceLevel) {
    if (sampleSize <= 0) {
      throw const StatisticsValidationException(
        StatisticsIssue.invalidSampleSize,
      );
    }
    if (!confidenceLevel.isFinite ||
        confidenceLevel < StatisticsLimits.minConfidenceLevel ||
        confidenceLevel > StatisticsLimits.maxConfidenceLevel) {
      throw const StatisticsValidationException(
        StatisticsIssue.invalidConfidenceLevel,
      );
    }
    if (!StatisticsLimits.supportedConfidenceLevels.any(
      (value) =>
          (value - confidenceLevel).abs() < StatisticsLimits.decimalTolerance,
    )) {
      throw const StatisticsValidationException(
        StatisticsIssue.unsupportedConfidenceLevel,
      );
    }
  }

  static double _zCritical(double confidence) => switch (confidence) {
    0.90 => 1.6448536269514722,
    0.95 => 1.959963984540054,
    0.99 => 2.5758293035489004,
    _ => throw const StatisticsValidationException(
      StatisticsIssue.unsupportedConfidenceLevel,
    ),
  };

  static double _tCritical(int degreesOfFreedom, double confidence) {
    final values = switch (confidence) {
      0.90 => _t90,
      0.95 => _t95,
      0.99 => _t99,
      _ => throw const StatisticsValidationException(
        StatisticsIssue.unsupportedConfidenceLevel,
      ),
    };
    if (degreesOfFreedom <= values.length) {
      return values[degreesOfFreedom - 1];
    }
    final z = _zCritical(confidence);
    final df = degreesOfFreedom.toDouble();
    final z2 = z * z;
    return z +
        (z * z2 + z) / (4 * df) +
        (5 * z * z2 * z2 + 16 * z * z2 + 3 * z) / (96 * df * df);
  }

  static const _t90 = [
    6.313752,
    2.919986,
    2.353363,
    2.131847,
    2.015048,
    1.943180,
    1.894579,
    1.859548,
    1.833113,
    1.812461,
    1.795885,
    1.782288,
    1.770933,
    1.761310,
    1.753050,
    1.745884,
    1.739607,
    1.734064,
    1.729133,
    1.724718,
    1.720743,
    1.717144,
    1.713872,
    1.710882,
    1.708141,
    1.705618,
    1.703288,
    1.701131,
    1.699127,
    1.697261,
  ];
  static const _t95 = [
    12.706205,
    4.302653,
    3.182446,
    2.776445,
    2.570582,
    2.446912,
    2.364624,
    2.306004,
    2.262157,
    2.228139,
    2.200985,
    2.178813,
    2.160369,
    2.144787,
    2.131450,
    2.119905,
    2.109816,
    2.100922,
    2.093024,
    2.085963,
    2.079614,
    2.073873,
    2.068658,
    2.063899,
    2.059539,
    2.055529,
    2.051831,
    2.048407,
    2.045230,
    2.042272,
  ];
  static const _t99 = [
    63.656741,
    9.924843,
    5.840909,
    4.604095,
    4.032143,
    3.707428,
    3.499483,
    3.355387,
    3.249836,
    3.169273,
    3.105807,
    3.054540,
    3.012276,
    2.976843,
    2.946713,
    2.920782,
    2.898231,
    2.878440,
    2.860935,
    2.845340,
    2.831360,
    2.818756,
    2.807336,
    2.796940,
    2.787436,
    2.778715,
    2.770683,
    2.763262,
    2.756386,
    2.749996,
  ];
}

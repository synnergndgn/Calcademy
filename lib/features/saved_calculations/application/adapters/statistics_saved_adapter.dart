import 'package:calcademy/features/statistics/domain/statistics_limits.dart';
import 'package:calcademy/features/statistics/domain/statistics_result.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';

enum StatisticsRestoreMode { descriptive, distribution, confidenceInterval }

/// Editable inputs rebuilt from a saved statistics record.
class StatisticsRestore {
  const StatisticsRestore.descriptive({required this.values})
    : mode = StatisticsRestoreMode.descriptive,
      distributionKind = null,
      normalOperation = null,
      discreteOperation = null,
      fields = const {},
      intervalKind = null,
      confidenceLevel = null;

  const StatisticsRestore.distribution({
    required DistributionKind this.distributionKind,
    required this.fields,
    this.normalOperation,
    this.discreteOperation,
  }) : mode = StatisticsRestoreMode.distribution,
       values = const [],
       intervalKind = null,
       confidenceLevel = null;

  const StatisticsRestore.confidenceInterval({
    required ConfidenceIntervalKind this.intervalKind,
    required double this.confidenceLevel,
    required this.fields,
  }) : mode = StatisticsRestoreMode.confidenceInterval,
       values = const [],
       distributionKind = null,
       normalOperation = null,
       discreteOperation = null;

  final StatisticsRestoreMode mode;
  final List<double> values;
  final DistributionKind? distributionKind;
  final NormalOperation? normalOperation;
  final DiscreteOperation? discreteOperation;

  /// Numeric parameters keyed by the service input names (mean, sigma, x,
  /// lower, upper, n, p, k, lambda, sampleStd, successes, confidence).
  final Map<String, double> fields;
  final ConfidenceIntervalKind? intervalKind;
  final double? confidenceLevel;
}

/// Restore parsing for statistics records. Distribution records need the
/// v2 `operation` key to disambiguate ≤ / ≥ / = variants, with one legacy
/// exception: a normal record carrying lower+upper is unambiguously a
/// "between" query and restores without it. Anything else insufficient
/// returns null and stays result-only.
abstract final class StatisticsSavedAdapter {
  static StatisticsRestore? tryRestore(SavedCalculation item) {
    if (item.module != SavedCalculationModule.statistics) return null;
    final payload = item.fullInputJson;
    switch (item.calculationType) {
      case 'descriptive':
        final rawValues = payload['values'];
        if (rawValues is! List ||
            rawValues.isEmpty ||
            rawValues.length > StatisticsLimits.maxDatasetSize) {
          return null;
        }
        final values = <double>[];
        for (final value in rawValues) {
          if (value is! num || !value.isFinite) return null;
          values.add(value.toDouble());
        }
        return StatisticsRestore.descriptive(values: values);
      case 'normal':
        final mean = _finite(payload['mean']);
        final sigma = _finite(payload['sigma']);
        if (mean == null || sigma == null || sigma <= 0) return null;
        final lower = _finite(payload['lower']);
        final upper = _finite(payload['upper']);
        final x = _finite(payload['x']);
        final operation = switch (payload['operation']) {
          'statsOpLessOrEqual' => NormalOperation.lessOrEqual,
          'statsOpGreaterOrEqual' => NormalOperation.greaterOrEqual,
          'statsOpBetween' => NormalOperation.between,
          // Legacy records lack the operation key; lower+upper is
          // unambiguously "between", an x-based record is not (≤ vs ≥).
          null when lower != null && upper != null => NormalOperation.between,
          _ => null,
        };
        if (operation == null) return null;
        if (operation == NormalOperation.between) {
          if (lower == null || upper == null || lower >= upper) return null;
          return StatisticsRestore.distribution(
            distributionKind: DistributionKind.normal,
            normalOperation: operation,
            fields: {
              'mean': mean,
              'sigma': sigma,
              'lower': lower,
              'upper': upper,
            },
          );
        }
        if (x == null) return null;
        return StatisticsRestore.distribution(
          distributionKind: DistributionKind.normal,
          normalOperation: operation,
          fields: {'mean': mean, 'sigma': sigma, 'x': x},
        );
      case 'binomial':
      case 'poisson':
        final operation = switch (payload['operation']) {
          'statsOpEqual' => DiscreteOperation.equal,
          'statsOpLessOrEqual' => DiscreteOperation.lessOrEqual,
          'statsOpGreaterOrEqual' => DiscreteOperation.greaterOrEqual,
          _ => null,
        };
        final k = _finite(payload['k']);
        if (operation == null || k == null || k < 0) return null;
        if (item.calculationType == 'binomial') {
          final n = _finite(payload['n']);
          final p = _finite(payload['p']);
          if (n == null || n <= 0 || p == null || p < 0 || p > 1) return null;
          return StatisticsRestore.distribution(
            distributionKind: DistributionKind.binomial,
            discreteOperation: operation,
            fields: {'n': n, 'p': p, 'k': k},
          );
        }
        final lambda = _finite(payload['lambda']);
        if (lambda == null || lambda <= 0) return null;
        return StatisticsRestore.distribution(
          distributionKind: DistributionKind.poisson,
          discreteOperation: operation,
          fields: {'lambda': lambda, 'k': k},
        );
      case 'knownSigmaMean':
      case 'unknownSigmaMean':
      case 'proportion':
        final kind = ConfidenceIntervalKind.values.firstWhere(
          (value) => value.name == item.calculationType,
          orElse: () => ConfidenceIntervalKind.knownSigmaMean,
        );
        final confidence = _finite(payload['confidence']);
        final n = _finite(payload['n']);
        if (confidence == null || n == null || n <= 0) return null;
        final supportedLevel = _snapConfidence(confidence);
        if (supportedLevel == null) return null;
        final fields = <String, double>{'n': n};
        if (kind == ConfidenceIntervalKind.proportion) {
          final successes = _finite(payload['successes']);
          if (successes == null || successes < 0) return null;
          fields['successes'] = successes;
        } else {
          final mean = _finite(payload['mean']);
          final spread = _finite(
            kind == ConfidenceIntervalKind.knownSigmaMean
                ? payload['sigma']
                : payload['sampleStd'],
          );
          if (mean == null || spread == null || spread <= 0) return null;
          fields['mean'] = mean;
          fields['spread'] = spread;
        }
        return StatisticsRestore.confidenceInterval(
          intervalKind: kind,
          confidenceLevel: supportedLevel,
          fields: fields,
        );
      default:
        return null;
    }
  }

  static double? _finite(Object? value) =>
      value is num && value.isFinite ? value.toDouble() : null;

  static double? _snapConfidence(double confidence) {
    for (final level in StatisticsLimits.supportedConfidenceLevels) {
      if ((level - confidence).abs() < 1e-9) return level;
    }
    return null;
  }
}

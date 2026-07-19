import 'dart:math' as math;

import 'package:calcademy/features/statistics/domain/statistics_limits.dart';
import 'package:calcademy/features/statistics/domain/statistics_result.dart';

class ProbabilityDistributionService {
  const ProbabilityDistributionService();

  DistributionResult normal({
    required double mean,
    required double standardDeviation,
    required NormalOperation operation,
    double? x,
    double? lower,
    double? upper,
  }) {
    if (!mean.isFinite ||
        !standardDeviation.isFinite ||
        standardDeviation <= 0) {
      throw const StatisticsValidationException(
        StatisticsIssue.invalidStandardDeviation,
      );
    }
    late final double probability;
    late final String label;
    late final Map<String, double> inputs;
    switch (operation) {
      case NormalOperation.lessOrEqual:
      case NormalOperation.greaterOrEqual:
        if (x == null || !x.isFinite) {
          throw const StatisticsValidationException(
            StatisticsIssue.invalidNumber,
          );
        }
        final cdf = _normalCdf((x - mean) / standardDeviation);
        probability = operation == NormalOperation.lessOrEqual ? cdf : 1 - cdf;
        label = operation == NormalOperation.lessOrEqual
            ? 'statsOpLessOrEqual'
            : 'statsOpGreaterOrEqual';
        inputs = {'mean': mean, 'sigma': standardDeviation, 'x': x};
      case NormalOperation.between:
        if (lower == null ||
            upper == null ||
            !lower.isFinite ||
            !upper.isFinite ||
            lower >= upper) {
          throw const StatisticsValidationException(
            StatisticsIssue.calculationRange,
          );
        }
        probability =
            _normalCdf((upper - mean) / standardDeviation) -
            _normalCdf((lower - mean) / standardDeviation);
        label = 'statsOpBetween';
        inputs = {
          'mean': mean,
          'sigma': standardDeviation,
          'lower': lower,
          'upper': upper,
        };
    }
    return _distributionResult(
      kind: DistributionKind.normal,
      operationLabel: label,
      probability: probability,
      methodKey: 'statsMethodNormalErf',
      inputs: inputs,
      warning: StatisticsWarning.normalAssumption,
    );
  }

  DistributionResult binomial({
    required int n,
    required double probabilityOfSuccess,
    required int k,
    required DiscreteOperation operation,
  }) {
    if (n <= 0 || n > StatisticsLimits.maxBinomialN) {
      throw const StatisticsValidationException(StatisticsIssue.invalidN);
    }
    if (!probabilityOfSuccess.isFinite ||
        probabilityOfSuccess < 0 ||
        probabilityOfSuccess > 1) {
      throw const StatisticsValidationException(
        StatisticsIssue.invalidProbability,
      );
    }
    if (k < 0) {
      throw const StatisticsValidationException(StatisticsIssue.invalidK);
    }
    if (k > n) {
      throw const StatisticsValidationException(StatisticsIssue.kGreaterThanN);
    }
    final indexes = switch (operation) {
      DiscreteOperation.equal => [k],
      DiscreteOperation.lessOrEqual => [for (var i = 0; i <= k; i++) i],
      DiscreteOperation.greaterOrEqual => [for (var i = k; i <= n; i++) i],
    };
    final logs = [
      for (final value in indexes)
        _logBinomialProbability(n, value, probabilityOfSuccess),
    ];
    return _distributionResult(
      kind: DistributionKind.binomial,
      operationLabel: _discreteLabel(operation),
      probability: _expLogSum(logs),
      methodKey: 'statsMethodBinomialLogSum',
      inputs: {'n': n.toDouble(), 'p': probabilityOfSuccess, 'k': k.toDouble()},
      warning: StatisticsWarning.independentTrialsAssumption,
    );
  }

  DistributionResult poisson({
    required double lambda,
    required int k,
    required DiscreteOperation operation,
  }) {
    if (!lambda.isFinite ||
        lambda <= 0 ||
        lambda > StatisticsLimits.maxPoissonLambda) {
      throw const StatisticsValidationException(StatisticsIssue.invalidLambda);
    }
    if (k < 0 || k > StatisticsLimits.maxPoissonK) {
      throw const StatisticsValidationException(StatisticsIssue.invalidK);
    }
    late final List<double> logs;
    switch (operation) {
      case DiscreteOperation.equal:
        logs = [_logPoisson(lambda, k)];
      case DiscreteOperation.lessOrEqual:
        logs = _poissonLogRange(lambda, 0, k);
      case DiscreteOperation.greaterOrEqual:
        final safeUpper = math.max(
          k,
          (lambda + 16 * math.sqrt(lambda) + 64).ceil(),
        );
        logs = _poissonLogRange(lambda, k, safeUpper);
    }
    return _distributionResult(
      kind: DistributionKind.poisson,
      operationLabel: _discreteLabel(operation),
      probability: _expLogSum(logs),
      methodKey: 'statsMethodPoissonLogSum',
      inputs: {'lambda': lambda, 'k': k.toDouble()},
      warning: StatisticsWarning.poissonAssumption,
    );
  }

  static DistributionResult _distributionResult({
    required DistributionKind kind,
    required String operationLabel,
    required double probability,
    required String methodKey,
    required Map<String, double> inputs,
    required StatisticsWarning warning,
  }) {
    if (!probability.isFinite ||
        probability < -StatisticsLimits.decimalTolerance ||
        probability > 1 + StatisticsLimits.decimalTolerance) {
      throw const StatisticsValidationException(
        StatisticsIssue.calculationRange,
      );
    }
    final safeProbability = probability < 0
        ? 0.0
        : probability > 1
        ? 1.0
        : probability;
    return DistributionResult(
      kind: kind,
      operationLabel: operationLabel,
      probability: safeProbability,
      methodKey: methodKey,
      inputs: Map.unmodifiable(inputs),
      diagnostics: const ['statsDiagnosticNumericalApproximation'],
      warnings: [StatisticsWarning.approximateProbability, warning],
    );
  }

  static String _discreteLabel(DiscreteOperation operation) =>
      switch (operation) {
        DiscreteOperation.equal => 'statsOpEqual',
        DiscreteOperation.lessOrEqual => 'statsOpLessOrEqual',
        DiscreteOperation.greaterOrEqual => 'statsOpGreaterOrEqual',
      };

  static double _normalCdf(double z) {
    if (z <= -8) return 0;
    if (z >= 8) return 1;
    return 0.5 * (1 + _erf(z / math.sqrt2));
  }

  // Abramowitz-Stegun 7.1.26; maximum absolute error is about 1.5e-7.
  static double _erf(double value) {
    final sign = value < 0 ? -1.0 : 1.0;
    final x = value.abs();
    final t = 1 / (1 + 0.3275911 * x);
    final polynomial =
        (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t -
                    0.284496736) *
                t +
            0.254829592) *
        t;
    return sign * (1 - polynomial * math.exp(-x * x));
  }

  static double _logBinomialProbability(int n, int k, double p) {
    if (p == 0) return k == 0 ? 0 : double.negativeInfinity;
    if (p == 1) return k == n ? 0 : double.negativeInfinity;
    var logCombination = 0.0;
    final shorter = math.min(k, n - k);
    for (var i = 1; i <= shorter; i++) {
      logCombination += math.log(n - shorter + i) - math.log(i);
    }
    return logCombination + k * math.log(p) + (n - k) * math.log(1 - p);
  }

  static double _logPoisson(double lambda, int k) {
    var logFactorial = 0.0;
    for (var i = 2; i <= k; i++) {
      logFactorial += math.log(i);
    }
    return -lambda + k * math.log(lambda) - logFactorial;
  }

  static List<double> _poissonLogRange(double lambda, int start, int end) {
    if (end < start) return const [];
    final logs = <double>[];
    var current = _logPoisson(lambda, start);
    logs.add(current);
    final logLambda = math.log(lambda);
    for (var value = start + 1; value <= end; value++) {
      current += logLambda - math.log(value);
      logs.add(current);
    }
    return logs;
  }

  static double _expLogSum(List<double> logs) {
    if (logs.isEmpty) return 0;
    final maximum = logs.reduce(math.max);
    if (maximum == double.negativeInfinity) return 0;
    var sum = 0.0;
    for (final value in logs) {
      sum += math.exp(value - maximum);
    }
    return math.exp(maximum) * sum;
  }
}

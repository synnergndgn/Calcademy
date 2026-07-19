import 'package:calcademy/features/statistics/application/probability_distribution_service.dart';
import 'package:calcademy/features/statistics/domain/statistics_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = ProbabilityDistributionService();

  test('normal CDF matches known values for lower, upper, and between', () {
    final lower = service.normal(
      mean: 0,
      standardDeviation: 1,
      x: 1,
      operation: NormalOperation.lessOrEqual,
    );
    final upper = service.normal(
      mean: 0,
      standardDeviation: 1,
      x: 1,
      operation: NormalOperation.greaterOrEqual,
    );
    final between = service.normal(
      mean: 0,
      standardDeviation: 1,
      lower: -1,
      upper: 1,
      operation: NormalOperation.between,
    );

    expect(lower.probability, closeTo(0.841344746, 2e-7));
    expect(upper.probability, closeTo(0.158655254, 2e-7));
    expect(between.probability, closeTo(0.682689492, 3e-7));
  });

  test('binomial exact and cumulative probabilities are stable', () {
    final exact = service.binomial(
      n: 10,
      probabilityOfSuccess: 0.5,
      k: 3,
      operation: DiscreteOperation.equal,
    );
    final cumulative = service.binomial(
      n: 10,
      probabilityOfSuccess: 0.5,
      k: 3,
      operation: DiscreteOperation.lessOrEqual,
    );
    final edge = service.binomial(
      n: 1000,
      probabilityOfSuccess: 0.001,
      k: 0,
      operation: DiscreteOperation.equal,
    );

    expect(exact.probability, closeTo(0.1171875, 1e-12));
    expect(cumulative.probability, closeTo(0.171875, 1e-12));
    expect(edge.probability, closeTo(0.367695425, 1e-9));
  });

  test('poisson exact and cumulative probabilities match known values', () {
    final exact = service.poisson(
      lambda: 3,
      k: 2,
      operation: DiscreteOperation.equal,
    );
    final lower = service.poisson(
      lambda: 3,
      k: 2,
      operation: DiscreteOperation.lessOrEqual,
    );
    final upper = service.poisson(
      lambda: 3,
      k: 2,
      operation: DiscreteOperation.greaterOrEqual,
    );

    expect(exact.probability, closeTo(0.2240418077, 1e-10));
    expect(lower.probability, closeTo(0.4231900811, 1e-10));
    expect(upper.probability, closeTo(0.8008517265, 1e-10));
  });

  test('poisson cumulative edge stays finite at the configured k limit', () {
    final result = service.poisson(
      lambda: 1000,
      k: 10000,
      operation: DiscreteOperation.lessOrEqual,
    );

    expect(result.probability, closeTo(1, 1e-12));
  });

  test('rejects invalid distribution parameters', () {
    expect(
      () => service.normal(
        mean: 0,
        standardDeviation: 0,
        x: 0,
        operation: NormalOperation.lessOrEqual,
      ),
      throwsA(isA<StatisticsValidationException>()),
    );
    expect(
      () => service.binomial(
        n: 3,
        probabilityOfSuccess: 1.2,
        k: 1,
        operation: DiscreteOperation.equal,
      ),
      throwsA(isA<StatisticsValidationException>()),
    );
    expect(
      () =>
          service.poisson(lambda: -1, k: 1, operation: DiscreteOperation.equal),
      throwsA(isA<StatisticsValidationException>()),
    );
  });
}

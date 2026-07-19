import 'package:calcademy/features/statistics/application/confidence_interval_service.dart';
import 'package:calcademy/features/statistics/domain/statistics_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = ConfidenceIntervalService();

  test('known sigma mean uses the two-sided z interval', () {
    final result = service.knownSigmaMean(
      sampleMean: 10,
      sigma: 2,
      sampleSize: 25,
      confidenceLevel: 0.95,
    );

    expect(result.lowerBound, closeTo(9.216014406, 1e-9));
    expect(result.upperBound, closeTo(10.783985594, 1e-9));
    expect(result.marginOfError, closeTo(0.783985594, 1e-9));
  });

  test('unknown sigma mean uses the verified t critical table', () {
    final result = service.unknownSigmaMean(
      sampleMean: 10,
      sampleStandardDeviation: 2,
      sampleSize: 10,
      confidenceLevel: 0.95,
    );

    expect(result.marginOfError, closeTo(1.430713709, 1e-9));
    expect(result.lowerBound, closeTo(8.569286291, 1e-9));
    expect(result.upperBound, closeTo(11.430713709, 1e-9));
  });

  test('proportion uses the Wilson interval', () {
    final result = service.proportion(
      successes: 40,
      sampleSize: 100,
      confidenceLevel: 0.95,
    );

    expect(result.lowerBound, closeTo(0.309401, 1e-6));
    expect(result.upperBound, closeTo(0.497997413, 1e-9));
    expect(result.methodKey, 'statsMethodWilsonInterval');
  });

  test('rejects invalid confidence and sample data', () {
    expect(
      () => service.knownSigmaMean(
        sampleMean: 1,
        sigma: 1,
        sampleSize: 0,
        confidenceLevel: 0.95,
      ),
      throwsA(isA<StatisticsValidationException>()),
    );
    expect(
      () => service.proportion(
        successes: 11,
        sampleSize: 10,
        confidenceLevel: 0.95,
      ),
      throwsA(
        isA<StatisticsValidationException>().having(
          (error) => error.issue,
          'issue',
          StatisticsIssue.successesGreaterThanN,
        ),
      ),
    );
    expect(
      () => service.knownSigmaMean(
        sampleMean: 1,
        sigma: 1,
        sampleSize: 10,
        confidenceLevel: 0.92,
      ),
      throwsA(
        isA<StatisticsValidationException>().having(
          (error) => error.issue,
          'issue',
          StatisticsIssue.unsupportedConfidenceLevel,
        ),
      ),
    );
  });
}

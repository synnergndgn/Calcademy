import 'package:calcademy/features/statistics/application/descriptive_statistics_service.dart';
import 'package:calcademy/features/statistics/domain/statistics_data_parser.dart';
import 'package:calcademy/features/statistics/domain/statistics_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = StatisticsDataParser();
  const service = DescriptiveStatisticsService();

  group('dataset parsing', () {
    test('supports comma separated values', () {
      expect(parser.parse('1,2,3,4,5'), [1, 2, 3, 4, 5]);
    });

    test('supports whitespace, semicolon, and newline separators', () {
      expect(parser.parse('1 2 3'), [1, 2, 3]);
      expect(parser.parse('1;2;3'), [1, 2, 3]);
      expect(parser.parse('1\n2\n3'), [1, 2, 3]);
    });

    test('supports decimal comma with an explicit separator', () {
      expect(parser.parse('1,5; 2,5'), [1.5, 2.5]);
    });

    test('rejects an ambiguous single comma', () {
      expect(
        () => parser.parse('1,5'),
        throwsA(
          isA<StatisticsValidationException>().having(
            (error) => error.issue,
            'issue',
            StatisticsIssue.ambiguousSeparator,
          ),
        ),
      );
    });
  });

  test('calculates central tendency, modes, and spread', () {
    final result = service.calculate('1,2,2,4,6');

    expect(result.count, 5);
    expect(result.sum, 15);
    expect(result.mean, 3);
    expect(result.median, 2);
    expect(result.modes, [2]);
    expect(result.populationVariance, closeTo(3.2, 1e-12));
    expect(result.sampleVariance, closeTo(4, 1e-12));
    expect(result.populationStandardDeviation, closeTo(1.7888543819, 1e-10));
    expect(result.sampleStandardDeviation, 2);
  });

  test('calculates quartiles, IQR, and outliers', () {
    final result = service.calculate('1,2,3,4,5,6,7,8,30');

    expect(result.q1, 2.5);
    expect(result.q3, 7.5);
    expect(result.iqr, 5);
    expect(result.outliers, [30]);
  });

  test('handles a single element without invalid sample statistics', () {
    final result = service.calculate('7');

    expect(result.mean, 7);
    expect(result.q1, 7);
    expect(result.q3, 7);
    expect(result.sampleVariance, isNull);
    expect(
      result.warnings,
      contains(StatisticsWarning.sampleVarianceUnavailable),
    );
  });
}

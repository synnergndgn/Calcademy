import 'dart:math' as math;

import 'package:calcademy/features/statistics/domain/statistics_data_parser.dart';
import 'package:calcademy/features/statistics/domain/statistics_result.dart';

class DescriptiveStatisticsService {
  const DescriptiveStatisticsService({
    this.parser = const StatisticsDataParser(),
  });

  final StatisticsDataParser parser;

  DescriptiveStatisticsResult calculate(String input) {
    final values = parser.parse(input);
    final sorted = [...values]..sort();
    final sum = _compensatedSum(sorted);
    final mean = sum / sorted.length;
    final squaredDeviations = _compensatedSum([
      for (final value in sorted) math.pow(value - mean, 2).toDouble(),
    ]);
    final populationVariance = squaredDeviations / sorted.length;
    final sampleVariance = sorted.length > 1
        ? squaredDeviations / (sorted.length - 1)
        : null;
    final q1 = _median(sorted.sublist(0, sorted.length ~/ 2));
    final upperStart = (sorted.length + 1) ~/ 2;
    final q3 = _median(sorted.sublist(upperStart));
    final effectiveQ1 = q1 ?? sorted.first;
    final effectiveQ3 = q3 ?? sorted.last;
    final iqr = effectiveQ3 - effectiveQ1;
    final lowerFence = effectiveQ1 - 1.5 * iqr;
    final upperFence = effectiveQ3 + 1.5 * iqr;
    final modes = _modes(sorted);

    return DescriptiveStatisticsResult(
      values: List.unmodifiable(sorted),
      count: sorted.length,
      sum: sum,
      mean: mean,
      median: _median(sorted)!,
      modes: modes,
      minimum: sorted.first,
      maximum: sorted.last,
      range: sorted.last - sorted.first,
      populationVariance: populationVariance,
      sampleVariance: sampleVariance,
      populationStandardDeviation: math.sqrt(populationVariance),
      sampleStandardDeviation: sampleVariance == null
          ? null
          : math.sqrt(sampleVariance),
      q1: effectiveQ1,
      q3: effectiveQ3,
      iqr: iqr,
      outliers: List.unmodifiable(
        sorted.where((value) => value < lowerFence || value > upperFence),
      ),
      warnings: [
        if (sorted.length == 1) StatisticsWarning.sampleVarianceUnavailable,
        if (sorted.length < 4) StatisticsWarning.quartilesLimited,
      ],
    );
  }

  static double _compensatedSum(Iterable<double> values) {
    var sum = 0.0;
    var correction = 0.0;
    for (final value in values) {
      final adjusted = value - correction;
      final next = sum + adjusted;
      correction = (next - sum) - adjusted;
      sum = next;
    }
    return sum;
  }

  static double? _median(List<double> values) {
    if (values.isEmpty) return null;
    final middle = values.length ~/ 2;
    return values.length.isOdd
        ? values[middle]
        : (values[middle - 1] + values[middle]) / 2;
  }

  static List<double> _modes(List<double> sorted) {
    var bestCount = 1;
    var currentCount = 1;
    final counts = <double, int>{};
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] == sorted[i - 1]) {
        currentCount++;
      } else {
        currentCount = 1;
      }
      counts[sorted[i]] = currentCount;
      bestCount = math.max(bestCount, currentCount);
    }
    if (bestCount == 1) return const [];
    return List.unmodifiable(
      counts.entries
          .where((entry) => entry.value == bestCount)
          .map((entry) => entry.key),
    );
  }
}

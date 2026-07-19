import 'dart:math' as math;

/// A readable chart scale whose labels sit inside slightly expanded chart
/// bounds. Keeping the visible bounds separate from the labelled bounds avoids
/// placing text directly on the chart border.
class CalculusAxisScale {
  const CalculusAxisScale({
    required this.min,
    required this.max,
    required this.interval,
    required this.firstLabel,
    required this.lastLabel,
    required this.labelCount,
  });

  final double min;
  final double max;
  final double interval;
  final double firstLabel;
  final double lastLabel;
  final int labelCount;

  static CalculusAxisScale calculate(
    double rawMin,
    double rawMax, {
    int maxLabels = 6,
  }) {
    assert(maxLabels >= 2);
    var lower = rawMin;
    var upper = rawMax;
    if (!lower.isFinite || !upper.isFinite || lower >= upper) {
      lower = -1;
      upper = 1;
    }

    final rawSpan = upper - lower;
    final paddedMin = lower - rawSpan * 0.06;
    final paddedMax = upper + rawSpan * 0.06;
    var interval = _niceCeiling(
      (paddedMax - paddedMin) / math.max(1, maxLabels - 1),
    );
    var first = (paddedMin / interval).ceilToDouble() * interval;
    var last = (paddedMax / interval).floorToDouble() * interval;
    var count = _count(first, last, interval);

    while (count > maxLabels) {
      interval = _nextNice(interval);
      first = (paddedMin / interval).ceilToDouble() * interval;
      last = (paddedMax / interval).floorToDouble() * interval;
      count = _count(first, last, interval);
    }

    if (count < 2) {
      first = (lower / interval).floorToDouble() * interval;
      last = (upper / interval).ceilToDouble() * interval;
      count = _count(first, last, interval);
    }

    final edgeRoom = interval * 0.22;
    return CalculusAxisScale(
      min: math.min(lower, first) - edgeRoom,
      max: math.max(upper, last) + edgeRoom,
      interval: interval,
      firstLabel: first,
      lastLabel: last,
      labelCount: count,
    );
  }

  bool shows(double value) {
    final tolerance = interval * 1e-6;
    return value >= firstLabel - tolerance && value <= lastLabel + tolerance;
  }

  static int _count(double first, double last, double interval) {
    if (last < first) return 0;
    return ((last - first) / interval).round() + 1;
  }

  static double _niceCeiling(double value) {
    if (!value.isFinite || value <= 0) return 1;
    final exponent = math
        .pow(10, (math.log(value) / math.ln10).floor())
        .toDouble();
    final fraction = value / exponent;
    final niceFraction = switch (fraction) {
      <= 1 => 1,
      <= 2 => 2,
      <= 2.5 => 2.5,
      <= 5 => 5,
      _ => 10,
    };
    return niceFraction * exponent;
  }

  static double _nextNice(double value) => _niceCeiling(value * 1.01);
}

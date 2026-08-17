class GraphRange {
  const GraphRange({this.min = defaultMin, this.max = defaultMax});

  static const defaultMin = -10.0;
  static const defaultMax = 10.0;
  static const lowerLimit = -1000.0;
  static const upperLimit = 1000.0;
  static const minimumSpan = 1e-6;

  final double min;
  final double max;

  double get span => max - min;

  static bool isValid(double min, double max) {
    return min.isFinite &&
        max.isFinite &&
        min >= lowerLimit &&
        max <= upperLimit &&
        max - min >= minimumSpan;
  }

  Map<String, Object?> toJson() => {'min': min, 'max': max};

  factory GraphRange.fromJson(Map<String, Object?> json) {
    final min = (json['min'] as num?)?.toDouble() ?? defaultMin;
    final max = (json['max'] as num?)?.toDouble() ?? defaultMax;
    return isValid(min, max)
        ? GraphRange(min: min, max: max)
        : const GraphRange();
  }
}

class GraphYRange {
  const GraphYRange(this.min, this.max);

  static const lowerLimit = -1e12;
  static const upperLimit = 1e12;
  static const minimumSpan = 1e-9;

  final double min;
  final double max;

  double get span => max - min;

  static bool isFiniteAndOrdered(double min, double max) =>
      min.isFinite && max.isFinite && min < max;

  static bool isWithinLimits(double min, double max) =>
      min >= lowerLimit && max <= upperLimit;

  static bool hasSafeSpan(double min, double max) {
    if (!isFiniteAndOrdered(min, max)) return false;
    final scale = min.abs() > max.abs() ? min.abs() : max.abs();
    final relativeMinimum = scale * 1e-12;
    return max - min >=
        (relativeMinimum > minimumSpan ? relativeMinimum : minimumSpan);
  }

  static bool isValid(double min, double max) =>
      isFiniteAndOrdered(min, max) &&
      isWithinLimits(min, max) &&
      hasSafeSpan(min, max);
}

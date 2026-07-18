class GraphRange {
  const GraphRange({this.min = defaultMin, this.max = defaultMax});

  static const defaultMin = -10.0;
  static const defaultMax = 10.0;
  static const lowerLimit = -1000.0;
  static const upperLimit = 1000.0;

  final double min;
  final double max;

  double get span => max - min;

  static bool isValid(double min, double max) {
    return min.isFinite &&
        max.isFinite &&
        min >= lowerLimit &&
        max <= upperLimit &&
        min < max;
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

  final double min;
  final double max;
}

class GraphPoint {
  const GraphPoint(this.x, this.y);

  final double x;
  final double y;
}

class GraphSegment {
  const GraphSegment(this.points);

  final List<GraphPoint> points;
}

class GraphSeries {
  const GraphSeries({
    required this.functionId,
    required this.segments,
    this.stats = const GraphSamplingStats(),
  });

  final String functionId;
  final List<GraphSegment> segments;
  final GraphSamplingStats stats;

  int get pointCount =>
      segments.fold(0, (total, segment) => total + segment.points.length);

  GraphSeries asCacheHit(String nextFunctionId) => GraphSeries(
    functionId: nextFunctionId,
    segments: segments,
    stats: stats.copyWith(fromCache: true, evaluationCount: 0),
  );
}

class GraphSamplingStats {
  const GraphSamplingStats({
    this.evaluationCount = 0,
    this.generatedPointCount = 0,
    this.maxDepthReached = 0,
    this.fromCache = false,
  });

  final int evaluationCount;
  final int generatedPointCount;
  final int maxDepthReached;
  final bool fromCache;

  GraphSamplingStats copyWith({
    int? evaluationCount,
    int? generatedPointCount,
    int? maxDepthReached,
    bool? fromCache,
  }) => GraphSamplingStats(
    evaluationCount: evaluationCount ?? this.evaluationCount,
    generatedPointCount: generatedPointCount ?? this.generatedPointCount,
    maxDepthReached: maxDepthReached ?? this.maxDepthReached,
    fromCache: fromCache ?? this.fromCache,
  );
}

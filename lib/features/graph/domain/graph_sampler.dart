import 'dart:collection';
import 'dart:math' as math;

import 'package:calcademy/features/graph/domain/graph_expression.dart';
import 'package:calcademy/features/graph/domain/graph_point.dart';
import 'package:calcademy/features/graph/domain/graph_range.dart';

class GraphSampler {
  GraphSampler({
    this.minInitialSegments = 80,
    this.maxInitialSegments = 160,
    this.maxDepth = 9,
    this.maxPoints = 3200,
    this.maxEvaluations = 6400,
    this.pixelErrorTolerance = 0.75,
    this.cacheCapacity = 24,
  });

  final int minInitialSegments;
  final int maxInitialSegments;
  final int maxDepth;
  final int maxPoints;
  final int maxEvaluations;
  final double pixelErrorTolerance;
  final int cacheCapacity;
  final LinkedHashMap<String, GraphSeries> _cache = LinkedHashMap();

  GraphSeries sample({
    required String functionId,
    required GraphEvaluator evaluator,
    required GraphRange range,
    GraphAngleMode angleMode = GraphAngleMode.radians,
    String? expressionKey,
    double viewportWidth = 720,
    double viewportHeight = 390,
  }) {
    final cacheKey = expressionKey == null
        ? null
        : _cacheKey(
            expressionKey,
            range,
            angleMode,
            viewportWidth,
            viewportHeight,
          );
    if (cacheKey != null) {
      final cached = _cache.remove(cacheKey);
      if (cached != null) {
        _cache[cacheKey] = cached;
        return cached.asCacheHit(functionId);
      }
    }

    final evaluationCache = <double, double?>{};
    var evaluationCount = 0;
    double? evaluate(double x) {
      if (evaluationCache.containsKey(x)) return evaluationCache[x];
      if (evaluationCount >= maxEvaluations) return null;
      evaluationCount++;
      final value = evaluator.evaluate(x, angleMode: angleMode);
      final result = value.isFinite && value.abs() <= 1e12 ? value : null;
      evaluationCache[x] = result;
      return result;
    }

    final initialSegments = (viewportWidth / 6).round().clamp(
      minInitialSegments,
      maxInitialSegments,
    );
    final initial = <_SampleNode>[
      for (var index = 0; index <= initialSegments; index++)
        _SampleNode(range.min + range.span * index / initialSegments, null),
    ];
    for (var index = 0; index < initial.length; index++) {
      final node = initial[index];
      initial[index] = _SampleNode(node.x, evaluate(node.x));
    }
    final initialValues = initial
        .map((item) => item.y)
        .whereType<double>()
        .toList();
    final robustSpan = _robustSpan(initialValues);
    final errorTolerance = math.max(
      1e-9,
      robustSpan / math.max(120, viewportHeight) * pixelErrorTolerance,
    );
    final minimumXStep = math.max(1e-12, range.span / 1000000);
    final raw = <_SampleNode>[initial.first];
    var maxDepthReached = 0;

    void addNode(_SampleNode node) {
      if (raw.length >= maxPoints) return;
      if (raw.isNotEmpty && raw.last.x == node.x) return;
      raw.add(node);
    }

    void refine(_SampleNode left, _SampleNode right, int depth) {
      if (raw.length >= maxPoints || evaluationCount >= maxEvaluations) {
        addNode(right);
        return;
      }
      maxDepthReached = math.max(maxDepthReached, depth);
      final midX = (left.x + right.x) / 2;
      final middle = _SampleNode(midX, evaluate(midX));
      final mixedValidity =
          (left.y == null || right.y == null || middle.y == null) &&
          !(left.y == null && right.y == null && middle.y == null);
      final interpolationError = switch ((left.y, middle.y, right.y)) {
        (final double y0, final double ym, final double y1) =>
          (ym - (y0 + y1) / 2).abs(),
        _ => 0.0,
      };
      final signChangeNearPole = switch ((left.y, right.y)) {
        (final double y0, final double y1) =>
          y0.sign != y1.sign &&
              math.min(y0.abs(), y1.abs()) > math.max(8, robustSpan * 2),
        _ => false,
      };
      final sharpJump = switch ((left.y, right.y)) {
        (final double y0, final double y1) =>
          (y1 - y0).abs() > math.max(20, robustSpan * 3.5),
        _ => false,
      };
      final shouldRefine =
          mixedValidity ||
          signChangeNearPole ||
          sharpJump ||
          interpolationError > errorTolerance;
      if (shouldRefine &&
          depth < maxDepth &&
          right.x - left.x > minimumXStep &&
          raw.length + 2 < maxPoints) {
        refine(left, middle, depth + 1);
        refine(middle, right, depth + 1);
      } else {
        if (middle.y == null) addNode(middle);
        addNode(right);
      }
    }

    for (var index = 0; index < initial.length - 1; index++) {
      refine(initial[index], initial[index + 1], 0);
      if (raw.length >= maxPoints) break;
    }

    final finiteY = raw.map((item) => item.y).whereType<double>().toList();
    final finalRobustSpan = _robustSpan(finiteY);
    final jumpThreshold = math.max(20.0, finalRobustSpan * 3.5);
    final segments = <GraphSegment>[];
    var current = <GraphPoint>[];
    GraphPoint? previous;
    void flush() {
      if (current.length >= 2) segments.add(GraphSegment(current));
      current = <GraphPoint>[];
      previous = null;
    }

    for (final node in raw) {
      if (node.y == null) {
        flush();
        continue;
      }
      final point = GraphPoint(node.x, node.y!);
      if (previous != null) {
        final midX = (previous!.x + point.x) / 2;
        final midY = evaluationCache[midX];
        final signChangeNearPole =
            previous!.y.sign != point.y.sign &&
            math.min(previous!.y.abs(), point.y.abs()) >
                math.max(8, finalRobustSpan * 2);
        final midpointDeviation = midY == null
            ? double.infinity
            : (midY - (previous!.y + point.y) / 2).abs();
        if ((point.y - previous!.y).abs() > jumpThreshold ||
            signChangeNearPole ||
            midpointDeviation > jumpThreshold) {
          flush();
        }
      }
      current.add(point);
      previous = point;
    }
    flush();
    final result = GraphSeries(
      functionId: functionId,
      segments: List.unmodifiable(segments),
      stats: GraphSamplingStats(
        evaluationCount: evaluationCount,
        generatedPointCount: raw.length,
        maxDepthReached: maxDepthReached,
      ),
    );
    if (cacheKey != null) {
      _cache[cacheKey] = result;
      while (_cache.length > cacheCapacity) {
        _cache.remove(_cache.keys.first);
      }
    }
    return result;
  }

  GraphYRange autoYRange(Iterable<GraphSeries> series) {
    final values = <double>[
      for (final item in series)
        for (final segment in item.segments)
          for (final point in segment.points) point.y,
    ]..sort();
    if (values.isEmpty) return const GraphYRange(-10, 10);
    var low = _percentile(values, 0.02);
    var high = _percentile(values, 0.98);
    if ((high - low).abs() < 1e-9) {
      final padding = math.max(1.0, high.abs() * 0.2);
      low -= padding;
      high += padding;
    } else {
      final padding = (high - low) * 0.12;
      low -= padding;
      high += padding;
    }
    return GraphYRange(low, high);
  }

  double _robustSpan(List<double> values) {
    if (values.length < 4) return 1;
    values.sort();
    return math.max(
      1e-9,
      (_percentile(values, 0.95) - _percentile(values, 0.05)).abs(),
    );
  }

  double _percentile(List<double> sorted, double percentile) {
    final index = ((sorted.length - 1) * percentile).round();
    return sorted[index.clamp(0, sorted.length - 1)];
  }

  String _cacheKey(
    String expression,
    GraphRange range,
    GraphAngleMode angleMode,
    double width,
    double height,
  ) =>
      '${expression.trim()}|${range.min}|${range.max}|${angleMode.name}|'
      '${width.round()}|${height.round()}';
}

class _SampleNode {
  const _SampleNode(this.x, this.y);

  final double x;
  final double? y;
}

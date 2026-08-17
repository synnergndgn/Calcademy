import 'package:calcademy/features/graph/domain/graph_point.dart';
import 'package:calcademy/features/graph/domain/graph_range.dart';

/// Converts sampled math coordinates into a renderer-safe polyline set.
///
/// Canvas clipping alone is too late: chart libraries first transform every
/// input coordinate to pixels, and a finite value such as `1e12` can still
/// create an impractically large path when the visible Y range is small.
class GraphViewportClipper {
  const GraphViewportClipper({
    this.overscanRatio = 0.08,
    this.maxPoints = 4000,
  });

  final double overscanRatio;
  final int maxPoints;

  GraphSeries clip({
    required GraphSeries series,
    required GraphRange xRange,
    required GraphYRange yRange,
  }) {
    if (!GraphRange.isValid(xRange.min, xRange.max) ||
        !GraphYRange.isFiniteAndOrdered(yRange.min, yRange.max)) {
      return GraphSeries(functionId: series.functionId, segments: const []);
    }
    final xPadding = xRange.span * overscanRatio;
    final yPadding = yRange.span * overscanRatio;
    final bounds = _ClipBounds(
      left: xRange.min - xPadding,
      right: xRange.max + xPadding,
      bottom: yRange.min - yPadding,
      top: yRange.max + yPadding,
    );
    if (!bounds.isFinite) {
      return GraphSeries(functionId: series.functionId, segments: const []);
    }

    final output = <GraphSegment>[];
    var pointCount = 0;
    for (final segment in series.segments) {
      if (pointCount >= maxPoints || segment.points.length < 2) break;
      var current = <GraphPoint>[];
      void flush() {
        if (current.length >= 2) {
          output.add(GraphSegment(List.unmodifiable(current)));
          pointCount += current.length;
        }
        current = <GraphPoint>[];
      }

      for (var index = 1; index < segment.points.length; index++) {
        if (pointCount + current.length >= maxPoints) break;
        final clipped = _clipLine(
          segment.points[index - 1],
          segment.points[index],
          bounds,
        );
        if (clipped == null) {
          flush();
          continue;
        }
        final (start, end) = clipped;
        if (current.isEmpty) {
          current.add(start);
        } else if (!_samePoint(current.last, start, bounds)) {
          flush();
          current.add(start);
        }
        if (current.length < maxPoints - pointCount) current.add(end);
      }
      flush();
    }
    return GraphSeries(
      functionId: series.functionId,
      segments: List.unmodifiable(output),
      stats: series.stats,
    );
  }

  (GraphPoint, GraphPoint)? _clipLine(
    GraphPoint start,
    GraphPoint end,
    _ClipBounds bounds,
  ) {
    if (!start.x.isFinite ||
        !start.y.isFinite ||
        !end.x.isFinite ||
        !end.y.isFinite) {
      return null;
    }
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    if (!dx.isFinite || !dy.isFinite) return null;
    var entering = 0.0;
    var leaving = 1.0;
    final p = [-dx, dx, -dy, dy];
    final q = [
      start.x - bounds.left,
      bounds.right - start.x,
      start.y - bounds.bottom,
      bounds.top - start.y,
    ];
    for (var index = 0; index < p.length; index++) {
      if (p[index] == 0) {
        if (q[index] < 0) return null;
        continue;
      }
      final ratio = q[index] / p[index];
      if (p[index] < 0) {
        if (ratio > leaving) return null;
        if (ratio > entering) entering = ratio;
      } else {
        if (ratio < entering) return null;
        if (ratio < leaving) leaving = ratio;
      }
    }
    final clippedStart = GraphPoint(
      start.x + entering * dx,
      start.y + entering * dy,
    );
    final clippedEnd = GraphPoint(
      start.x + leaving * dx,
      start.y + leaving * dy,
    );
    if (!clippedStart.x.isFinite ||
        !clippedStart.y.isFinite ||
        !clippedEnd.x.isFinite ||
        !clippedEnd.y.isFinite) {
      return null;
    }
    return (clippedStart, clippedEnd);
  }

  bool _samePoint(GraphPoint left, GraphPoint right, _ClipBounds bounds) {
    final xTolerance = (bounds.right - bounds.left) * 1e-12;
    final yTolerance = (bounds.top - bounds.bottom) * 1e-12;
    return (left.x - right.x).abs() <= xTolerance &&
        (left.y - right.y).abs() <= yTolerance;
  }
}

class _ClipBounds {
  const _ClipBounds({
    required this.left,
    required this.right,
    required this.bottom,
    required this.top,
  });

  final double left;
  final double right;
  final double bottom;
  final double top;

  bool get isFinite =>
      left.isFinite && right.isFinite && bottom.isFinite && top.isFinite;
}

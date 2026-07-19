import 'dart:math' as math;

import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/calculus/presentation/calculus_axis_scale.dart';
import 'package:calcademy/features/graph/domain/graph_expression.dart';
import 'package:calcademy/features/graph/domain/graph_range.dart';
import 'package:calcademy/features/graph/domain/graph_sampler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A tangent overlay: the line through (point, f(point)) with the computed
/// derivative as its slope.
class TangentOverlay {
  const TangentOverlay({
    required this.point,
    required this.valueAtPoint,
    required this.slope,
  });

  final double point;
  final double valueAtPoint;
  final double slope;
}

/// A shaded-integral overlay over [lower, upper].
class IntegralOverlay {
  const IntegralOverlay({required this.lower, required this.upper});

  final double lower;
  final double upper;
}

/// Renders a function curve with an optional tangent line or shaded
/// integral area. This deliberately reuses the existing graph
/// infrastructure end to end - the graph module's [GraphSampler] produces
/// the curve segments (with its pole/discontinuity handling) and fl_chart
/// (the app's existing chart dependency) draws them - rather than
/// introducing a second plotting engine.
class CalculusGraphView extends StatelessWidget {
  const CalculusGraphView({
    super.key,
    required this.evaluator,
    required this.range,
    this.tangent,
    this.integral,
  });

  final GraphEvaluator evaluator;
  final GraphRange range;
  final TangentOverlay? tangent;
  final IntegralOverlay? integral;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final series = GraphSampler(
      maxPoints: 800,
      maxEvaluations: 1600,
    ).sample(functionId: 'calculus', evaluator: evaluator, range: range);
    final yRange = GraphSampler().autoYRange([series]);
    final xScale = CalculusAxisScale.calculate(
      range.min,
      range.max,
      maxLabels: 7,
    );
    final yScale = CalculusAxisScale.calculate(yRange.min, yRange.max);

    final curveBars = <LineChartBarData>[
      for (final segment in series.segments)
        LineChartBarData(
          spots: [for (final point in segment.points) FlSpot(point.x, point.y)],
          isCurved: false,
          color: colors.primary,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
    ];

    final overlayBars = <LineChartBarData>[];
    final currentTangent = tangent;
    if (currentTangent != null) {
      double tangentY(double x) =>
          currentTangent.valueAtPoint +
          currentTangent.slope * (x - currentTangent.point);
      overlayBars.add(
        LineChartBarData(
          spots: [
            FlSpot(range.min, tangentY(range.min)),
            FlSpot(range.max, tangentY(range.max)),
          ],
          color: colors.tertiary,
          barWidth: 2,
          dashArray: const [6, 4],
          dotData: const FlDotData(show: false),
        ),
      );
      overlayBars.add(
        LineChartBarData(
          spots: [FlSpot(currentTangent.point, currentTangent.valueAtPoint)],
          color: colors.tertiary,
          barWidth: 0,
          dotData: const FlDotData(show: true),
        ),
      );
    }

    final currentIntegral = integral;
    if (currentIntegral != null) {
      // Shade the area under the curve inside [lower, upper]: reuse the
      // sampled curve points restricted to the interval so the shading
      // follows exactly the drawn curve.
      final shadeSpots = <FlSpot>[
        for (final segment in series.segments)
          for (final point in segment.points)
            if (point.x >= currentIntegral.lower &&
                point.x <= currentIntegral.upper)
              FlSpot(point.x, point.y),
      ];
      if (shadeSpots.length >= 2) {
        overlayBars.add(
          LineChartBarData(
            spots: shadeSpots,
            isCurved: false,
            color: colors.tertiary,
            barWidth: 1,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colors.tertiary.withValues(alpha: 0.25),
            ),
            aboveBarData: BarAreaData(show: false),
          ),
        );
      }
    }

    if (curveBars.isEmpty) return const SizedBox.shrink();
    final labelHeight = MediaQuery.textScalerOf(context).scale(12);
    final leftReservedSize = (46 + (labelHeight - 12).clamp(0, 20)).toDouble();
    final bottomReservedSize = (30 + (labelHeight - 12).clamp(0, 18))
        .toDouble();
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    return Padding(
      key: const Key('calculus-graph-padding'),
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: (constraints.maxWidth / 1.5 + labelHeight).clamp(220, 420),
          child: LineChart(
            LineChartData(
              minX: xScale.min,
              maxX: xScale.max,
              minY: yScale.min,
              maxY: yScale.max,
              lineBarsData: [...curveBars, ...overlayBars],
              lineTouchData: const LineTouchData(enabled: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: yScale.interval,
                    reservedSize: leftReservedSize,
                    minIncluded: false,
                    maxIncluded: false,
                    getTitlesWidget: (value, meta) {
                      if (!yScale.shows(value)) return const SizedBox.shrink();
                      return SideTitleWidget(
                        meta: meta,
                        space: AppSpacing.xs,
                        child: Text(
                          _formatAxis(value, yScale.interval),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: labelStyle,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: xScale.interval,
                    reservedSize: bottomReservedSize,
                    minIncluded: false,
                    maxIncluded: false,
                    getTitlesWidget: (value, meta) {
                      if (!xScale.shows(value)) return const SizedBox.shrink();
                      return SideTitleWidget(
                        meta: meta,
                        space: AppSpacing.xs,
                        child: Text(
                          _formatAxis(value, xScale.interval),
                          maxLines: 1,
                          style: labelStyle,
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: colors.outlineVariant, strokeWidth: 0.5),
                getDrawingVerticalLine: (value) =>
                    FlLine(color: colors.outlineVariant, strokeWidth: 0.5),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: colors.outlineVariant),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatAxis(double value, double interval) {
    if (value.abs() < interval * 1e-8) return '0';
    final magnitude = value.abs();
    if (magnitude >= 100000 || magnitude < 0.0001) {
      return value.toStringAsExponential(1);
    }
    final decimals = interval >= 1
        ? 0
        : ((-math.log(interval) / math.ln10).ceil() + 1).clamp(0, 6);
    return value.toStringAsFixed(decimals).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

import 'dart:math' as math;

import 'package:calcademy/app/theme/app_radius.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/empty_state.dart';
import 'package:calcademy/features/graph/domain/graph_function.dart';
import 'package:calcademy/features/graph/domain/graph_point.dart';
import 'package:calcademy/features/graph/domain/graph_range.dart';
import 'package:calcademy/features/graph/domain/graph_sampler.dart';
import 'package:calcademy/features/graph/presentation/graph_controller.dart';
import 'package:calcademy/features/graph/presentation/graph_palette.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GraphCanvas extends ConsumerStatefulWidget {
  const GraphCanvas({super.key, this.repaintBoundaryKey});

  final GlobalKey? repaintBoundaryKey;

  @override
  ConsumerState<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends ConsumerState<GraphCanvas> {
  final _transformationController = TransformationController();
  int _lastResetRevision = -1;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renderState = ref.watch(
      graphProvider.select(
        (state) => (
          series: state.series,
          visibility: state.functions
              .map((item) => '${item.id}:${item.isVisible}:${item.visualIndex}')
              .join('|'),
          range: state.range,
          autoY: state.autoY,
          manualYMin: state.manualYMin,
          manualYMax: state.manualYMax,
          resetRevision: state.viewResetRevision,
          isSampling: state.isSampling,
        ),
      ),
    );
    if (_lastResetRevision != renderState.resetRevision) {
      _lastResetRevision = renderState.resetRevision;
      _transformationController.value = Matrix4.identity();
    }
    final functions = ref.read(graphProvider).functions;
    final visibleFunctions = {
      for (final function in functions)
        if (function.isVisible) function.id: function,
    };
    final visibleSeries = renderState.series.values
        .where(
          (series) =>
              visibleFunctions.containsKey(series.functionId) &&
              series.pointCount > 0,
        )
        .toList();
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: visibleSeries.isEmpty
          ? Stack(
              children: [
                EmptyState(
                  icon: Icons.show_chart_rounded,
                  title: context.l10n.t('graphEmptyTitle'),
                  body: context.l10n.t('graphEmptyBody'),
                ),
                if (renderState.isSampling)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            )
          : SizedBox(
              height: MediaQuery.sizeOf(context).width >= 700 ? 520 : 390,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    ref
                        .read(graphProvider.notifier)
                        .setViewportSize(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                  });
                  final yRange = renderState.autoY
                      ? GraphSampler().autoYRange(visibleSeries)
                      : GraphYRange(
                          renderState.manualYMin,
                          renderState.manualYMax,
                        );
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: RepaintBoundary(
                          key: widget.repaintBoundaryKey,
                          child: ColoredBox(
                            color: colors.surface,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 20, 12, 8),
                              child: Stack(
                                children: [
                                  MediaQuery.withClampedTextScaling(
                                    maxScaleFactor: 1.3,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onDoubleTap: _resetTransformation,
                                      child: LineChart(
                                        _chartData(
                                          context,
                                          visibleSeries,
                                          visibleFunctions,
                                          renderState.range.min,
                                          renderState.range.max,
                                          yRange,
                                        ),
                                        transformationConfig:
                                            FlTransformationConfig(
                                              scaleAxis: FlScaleAxis.free,
                                              minScale: 1,
                                              maxScale: 5,
                                              panEnabled: true,
                                              scaleEnabled: true,
                                              transformationController:
                                                  _transformationController,
                                            ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    left: 52,
                                    right: 62,
                                    child: MediaQuery.withClampedTextScaling(
                                      maxScaleFactor: 1.3,
                                      child: _GraphLegend(
                                        functions: visibleFunctions.values
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 4,
                                    bottom: 2,
                                    child: Text(
                                      context.l10n.t('appName'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: colors.primary.withValues(
                                              alpha: 0.72,
                                            ),
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surface.withValues(alpha: 0.9),
                            borderRadius: AppRadius.control,
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                key: const Key('graph-zoom-in'),
                                tooltip: context.l10n.t('graphZoomIn'),
                                onPressed: () => _zoom(1.25),
                                icon: const Icon(Icons.add_rounded),
                              ),
                              IconButton(
                                key: const Key('graph-zoom-out'),
                                tooltip: context.l10n.t('graphZoomOut'),
                                onPressed: () => _zoom(0.8),
                                icon: const Icon(Icons.remove_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (renderState.isSampling)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  LineChartData _chartData(
    BuildContext context,
    List<GraphSeries> series,
    Map<String, GraphFunction> functions,
    double minX,
    double maxX,
    GraphYRange yRange,
  ) {
    final colors = Theme.of(context).colorScheme;
    final xInterval = _interval(maxX - minX);
    final yInterval = _interval(yRange.max - yRange.min);
    return LineChartData(
      minX: minX,
      maxX: maxX,
      minY: yRange.min,
      maxY: yRange.max,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        horizontalInterval: yInterval,
        verticalInterval: xInterval,
        getDrawingHorizontalLine: (_) => FlLine(
          color: colors.outlineVariant.withValues(alpha: 0.55),
          strokeWidth: 0.8,
        ),
        getDrawingVerticalLine: (_) => FlLine(
          color: colors.outlineVariant.withValues(alpha: 0.55),
          strokeWidth: 0.8,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: colors.outlineVariant),
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          if (yRange.min <= 0 && yRange.max >= 0)
            HorizontalLine(y: 0, color: colors.outline, strokeWidth: 1.2),
        ],
        verticalLines: [
          if (minX <= 0 && maxX >= 0)
            VerticalLine(x: 0, color: colors.outline, strokeWidth: 1.2),
        ],
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: xInterval,
            reservedSize: 30,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              meta: meta,
              space: 4,
              child: Text(
                _formatAxis(value),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: yInterval,
            reservedSize: 44,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              meta: meta,
              space: 4,
              child: Text(
                _formatAxis(value),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: true,
        touchSpotThreshold: 18,
        touchCallback: (event, response) {
          if (event is FlTapUpEvent || event is FlPanUpdateEvent) {
            final spots = response?.lineBarSpots;
            if (spots != null && spots.isNotEmpty) {
              ref.read(graphProvider.notifier).inspectAt(spots.first.x);
            }
          }
        },
      ),
      lineBarsData: [
        for (final item in series)
          for (final segment in item.segments)
            LineChartBarData(
              spots: [
                for (final point in segment.points) FlSpot(point.x, point.y),
              ],
              color: GraphPalette.colorFor(
                context,
                functions[item.functionId]!.visualIndex,
              ),
              barWidth: 2.2,
              isCurved: false,
              dotData: const FlDotData(show: false),
            ),
      ],
    );
  }

  double _interval(double span) {
    if (!span.isFinite || span <= 0) return 1;
    final rough = span / 5;
    final magnitude = math.pow(10, (math.log(rough) / math.ln10).floor());
    final normalized = rough / magnitude;
    final step = normalized < 2
        ? 1
        : normalized < 5
        ? 2
        : 5;
    return (step * magnitude).toDouble();
  }

  String _formatAxis(double value) {
    if (value.abs() >= 1000 || (value != 0 && value.abs() < 0.01)) {
      return value.toStringAsExponential(1);
    }
    return value.toStringAsFixed(value.abs() < 10 ? 1 : 0);
  }

  void _zoom(double factor) {
    final matrix = _transformationController.value;
    final current = matrix.getMaxScaleOnAxis();
    final next = (current * factor).clamp(1.0, 5.0);
    if (next == current) return;
    final ratio = next / current;
    _transformationController.value = Matrix4.copy(matrix)
      ..multiply(Matrix4.diagonal3Values(ratio, ratio, 1));
  }

  void _resetTransformation() {
    _transformationController.value = Matrix4.identity();
  }
}

class GraphInspectionPanel extends ConsumerWidget {
  const GraphInspectionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspection = ref.watch(
      graphProvider.select(
        (state) => (
          x: state.inspectedX,
          values: state.inspectedValues,
          labels: state.functions
              .map((item) => '${item.id}:${item.visualIndex}')
              .join('|'),
        ),
      ),
    );
    if (inspection.x == null) return const SizedBox.shrink();
    final functions = {
      for (final item in ref.read(graphProvider).functions) item.id: item,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            Text(
              '${context.l10n.t('graphApproxX')} ${_format(inspection.x!)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final entry in inspection.values.entries)
              if (functions[entry.key] case final function?)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: GraphPalette.colorFor(
                          context,
                          function.visualIndex,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 9),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      entry.value == null
                          ? 'f${function.visualIndex + 1}(x): '
                                '${context.l10n.t('graphUndefined')}'
                          : 'f${function.visualIndex + 1}(x) ≈ '
                                '${_format(entry.value!)}',
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  static String _format(double value) => value.toStringAsPrecision(5);
}

class _GraphLegend extends StatelessWidget {
  const _GraphLegend({required this.functions});

  final List<GraphFunction> functions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('graph-legend-scroll'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < functions.length; index++) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: GraphPalette.colorFor(
                        context,
                        functions[index].visualIndex,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: 7),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'f${_subscript(functions[index].visualIndex + 1)}: '
                      '${functions[index].expression.trim()}',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
            if (index < functions.length - 1)
              const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  static String _subscript(int value) => switch (value) {
    1 => '₁',
    2 => '₂',
    3 => '₃',
    4 => '₄',
    5 => '₅',
    _ => value.toString(),
  };
}

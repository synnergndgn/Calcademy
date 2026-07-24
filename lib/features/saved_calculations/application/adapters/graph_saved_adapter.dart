import 'package:calcademy/features/graph/domain/graph_expression.dart';
import 'package:calcademy/features/graph/domain/graph_function.dart';
import 'package:calcademy/features/graph/domain/graph_range.dart';
import 'package:calcademy/features/graph/domain/saved_graph.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/saved_adapter_utils.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_limits.dart';

abstract final class GraphSavedAdapter {
  static SavedCalculationDraft? tryBuild({
    required List<GraphFunction> functions,
    required GraphRange xRange,
    required bool autoY,
    required double manualYMin,
    required double manualYMax,
    required GraphAngleMode angleMode,
    String? title,
  }) {
    final fullExpressions = functions
        .map((function) => function.expression.trim())
        .where((expression) => expression.isNotEmpty)
        .take(SavedCalculationsLimits.maxGraphExpressionCount)
        .toList();
    final expressions = fullExpressions
        .map(
          (expression) => truncateSavedText(
            expression,
            SavedCalculationsLimits.maxExpressionSummaryLength,
          ),
        )
        .toList();
    if (expressions.isEmpty) return null;
    requireFinite([
      xRange.min,
      xRange.max,
      if (!autoY) manualYMin,
      if (!autoY) manualYMax,
    ]);
    final expressionSummary = expressions.join('; ');
    return SavedCalculationDraft(
      title: truncateSavedText(
        title?.trim().isNotEmpty == true ? title!.trim() : expressionSummary,
        SavedCalculationsLimits.maxTitleLength,
      ),
      module: SavedCalculationModule.graphPlotter,
      calculationType: 'graphConfiguration',
      inputSummary:
          '$expressionSummary · x:[${xRange.min}, ${xRange.max}] · ${autoY ? 'auto y' : 'y:[$manualYMin, $manualYMax]'}',
      resultSummary:
          '${expressions.length} function${expressions.length == 1 ? '' : 's'} · ${angleMode.name}',
      fullInputJson: {
        'expressions': fullExpressions,
        'functionCount': fullExpressions.length,
        'xRange': {'min': xRange.min, 'max': xRange.max},
        'autoY': autoY,
        if (!autoY) 'yRange': {'min': manualYMin, 'max': manualYMax},
        'angleMode': angleMode.name,
      },
      resultJson: const {'kind': 'configuration'},
    );
  }

  static SavedGraph? tryRestore(SavedCalculation item) {
    if (item.module != SavedCalculationModule.graphPlotter) return null;
    try {
      final payload = item.fullInputJson;
      final rawExpressions = payload['expressions'];
      final rawRange = payload['xRange'];
      if (rawExpressions is! List<Object?> || rawRange is! Map) return null;
      final expressions = rawExpressions
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .take(SavedCalculationsLimits.maxGraphExpressionCount)
          .toList(growable: false);
      if (expressions.isEmpty) return null;
      final rangeJson = Map<String, Object?>.from(rawRange);
      final min = (rangeJson['min'] as num?)?.toDouble();
      final max = (rangeJson['max'] as num?)?.toDouble();
      if (min == null || max == null || !GraphRange.isValid(min, max)) {
        return null;
      }
      final autoY = payload['autoY'];
      if (autoY is! bool) return null;
      var manualYMin = -10.0;
      var manualYMax = 10.0;
      if (!autoY) {
        final rawYRange = payload['yRange'];
        if (rawYRange is! Map) return null;
        final yRange = Map<String, Object?>.from(rawYRange);
        final yMin = (yRange['min'] as num?)?.toDouble();
        final yMax = (yRange['max'] as num?)?.toDouble();
        if (yMin == null ||
            yMax == null ||
            !yMin.isFinite ||
            !yMax.isFinite ||
            yMin >= yMax) {
          return null;
        }
        manualYMin = yMin;
        manualYMax = yMax;
      }
      final angleMode = payload['angleMode'] == GraphAngleMode.degrees.name
          ? GraphAngleMode.degrees
          : GraphAngleMode.radians;
      return SavedGraph(
        id: item.id,
        title: item.title,
        functions: [
          for (var index = 0; index < expressions.length; index++)
            GraphFunction(
              id: 'saved-${item.id}-$index',
              expression: expressions[index],
              visualIndex: index,
            ),
        ],
        range: GraphRange(min: min, max: max),
        autoY: autoY,
        manualYMin: manualYMin,
        manualYMax: manualYMax,
        angleMode: angleMode,
        createdAt: item.createdAt,
      );
    } on Object {
      return null;
    }
  }
}

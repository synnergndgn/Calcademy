import 'package:calcademy/features/graph/domain/graph_expression.dart';
import 'package:calcademy/features/graph/domain/graph_function.dart';
import 'package:calcademy/features/graph/domain/graph_range.dart';
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
    final expressions = functions
        .map((function) => function.expression.trim())
        .where((expression) => expression.isNotEmpty)
        .take(SavedCalculationsLimits.maxGraphExpressionCount)
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
        'expressions': expressions,
        'functionCount': expressions.length,
        'xRange': {'min': xRange.min, 'max': xRange.max},
        'autoY': autoY,
        if (!autoY) 'yRange': {'min': manualYMin, 'max': manualYMax},
        'angleMode': angleMode.name,
      },
      resultJson: const {'kind': 'configuration'},
    );
  }
}

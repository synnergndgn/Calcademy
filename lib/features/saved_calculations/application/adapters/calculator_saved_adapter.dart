import 'package:calcademy/features/history/domain/calculation_record.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/saved_adapter_utils.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_limits.dart';

abstract final class CalculatorSavedAdapter {
  static SavedCalculationDraft fromRecord(CalculationRecord record) {
    requireSavedText(record.expression);
    requireSavedText(record.result);
    final expression = truncateSavedText(
      record.expression,
      SavedCalculationsLimits.maxExpressionSummaryLength,
    );
    final result = truncateSavedText(
      record.result,
      SavedCalculationsLimits.maxExpressionSummaryLength,
    );
    return SavedCalculationDraft(
      title: truncateSavedText(
        expression,
        SavedCalculationsLimits.maxTitleLength,
      ),
      module: SavedCalculationModule.scientificCalculator,
      calculationType: 'expression',
      inputSummary: '$expression · ${record.angleMode.name}',
      resultSummary: '$expression = $result',
      fullInputJson: {
        'expression': expression,
        'angleMode': record.angleMode.name,
        'timestamp': record.createdAt.toUtc().toIso8601String(),
      },
      resultJson: {'result': result},
    );
  }
}

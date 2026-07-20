import 'package:calcademy/features/financial_calculator/domain/financial_result.dart';

class BreakEvenService {
  const BreakEvenService();

  BreakEvenResult calculate({
    required BreakEvenOperation operation,
    required double fixedCost,
    required double unitPrice,
    required double variableCostPerUnit,
    double targetProfit = 0,
    double actualSalesQuantity = 0,
  }) {
    if (![
      fixedCost,
      unitPrice,
      variableCostPerUnit,
      targetProfit,
      actualSalesQuantity,
    ].every((value) => value.isFinite)) {
      throw const FinancialValidationException(FinancialIssue.invalidNumber);
    }
    if (fixedCost < 0) {
      throw const FinancialValidationException(
        FinancialIssue.negativeFixedCost,
      );
    }
    final contribution = unitPrice - variableCostPerUnit;
    if (unitPrice <= 0 || variableCostPerUnit < 0 || contribution <= 0) {
      throw const FinancialValidationException(
        FinancialIssue.invalidContributionMargin,
      );
    }
    if (targetProfit < 0) {
      throw const FinancialValidationException(
        FinancialIssue.invalidTargetProfit,
      );
    }
    if (actualSalesQuantity < 0) {
      throw const FinancialValidationException(
        FinancialIssue.invalidActualSales,
      );
    }
    final breakEvenQuantity = fixedCost / contribution;
    final marginQuantity = actualSalesQuantity - breakEvenQuantity;
    return BreakEvenResult(
      operation: operation,
      breakEvenQuantity: breakEvenQuantity,
      breakEvenRevenue: breakEvenQuantity * unitPrice,
      contributionMargin: contribution,
      targetQuantity: operation == BreakEvenOperation.targetProfit
          ? (fixedCost + targetProfit) / contribution
          : null,
      marginOfSafetyQuantity: operation == BreakEvenOperation.marginOfSafety
          ? marginQuantity
          : null,
      marginOfSafetyPercent:
          operation == BreakEvenOperation.marginOfSafety &&
              actualSalesQuantity > 0
          ? marginQuantity / actualSalesQuantity * 100
          : null,
      inputs: {
        'fixedCost': fixedCost,
        'unitPrice': unitPrice,
        'variableCost': variableCostPerUnit,
        if (operation == BreakEvenOperation.targetProfit)
          'targetProfit': targetProfit,
        if (operation == BreakEvenOperation.marginOfSafety)
          'actualSalesQuantity': actualSalesQuantity,
      },
    );
  }
}

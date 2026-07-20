import 'package:calcademy/features/financial_calculator/application/break_even_service.dart';
import 'package:calcademy/features/financial_calculator/domain/financial_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = BreakEvenService();

  test('calculates break-even quantity and revenue', () {
    final result = service.calculate(
      operation: BreakEvenOperation.breakEven,
      fixedCost: 10000,
      unitPrice: 50,
      variableCostPerUnit: 30,
    );
    expect(result.breakEvenQuantity, 500);
    expect(result.breakEvenRevenue, 25000);
    expect(result.contributionMargin, 20);
  });

  test('calculates target-profit quantity and margin of safety', () {
    final target = service.calculate(
      operation: BreakEvenOperation.targetProfit,
      fixedCost: 10000,
      unitPrice: 50,
      variableCostPerUnit: 30,
      targetProfit: 5000,
    );
    final safety = service.calculate(
      operation: BreakEvenOperation.marginOfSafety,
      fixedCost: 10000,
      unitPrice: 50,
      variableCostPerUnit: 30,
      actualSalesQuantity: 750,
    );
    expect(target.targetQuantity, 750);
    expect(safety.marginOfSafetyQuantity, 250);
    expect(safety.marginOfSafetyPercent, closeTo(33.33333333, 1e-8));
  });

  test('rejects invalid contribution margin and negative fixed cost', () {
    expect(
      () => service.calculate(
        operation: BreakEvenOperation.breakEven,
        fixedCost: 10,
        unitPrice: 20,
        variableCostPerUnit: 20,
      ),
      throwsA(isA<FinancialValidationException>()),
    );
    expect(
      () => service.calculate(
        operation: BreakEvenOperation.breakEven,
        fixedCost: -1,
        unitPrice: 20,
        variableCostPerUnit: 10,
      ),
      throwsA(
        isA<FinancialValidationException>().having(
          (error) => error.issue,
          'issue',
          FinancialIssue.negativeFixedCost,
        ),
      ),
    );
  });
}

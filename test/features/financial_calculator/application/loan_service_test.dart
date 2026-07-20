import 'package:calcademy/features/financial_calculator/application/loan_service.dart';
import 'package:calcademy/features/financial_calculator/domain/financial_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = LoanService();

  test('fixed payment and first amortization row match known values', () {
    final result = service.fixedPaymentLoan(
      principal: 10000,
      annualRatePercent: 12,
      termYears: 2,
      paymentsPerYear: 12,
    );
    expect(result.periodicPayment, closeTo(470.7347222, 1e-7));
    expect(result.schedule.first.interest, closeTo(100, 1e-10));
    expect(result.schedule.first.principal, closeTo(370.7347222, 1e-7));
    expect(result.totalInterest, closeTo(1297.633333, 1e-5));
    expect(result.schedule.last.remainingBalance, 0);
  });

  test('zero-interest loan divides principal evenly and closes balance', () {
    final result = service.fixedPaymentLoan(
      principal: 1200,
      annualRatePercent: 0,
      termYears: 1,
      paymentsPerYear: 12,
    );
    expect(result.periodicPayment, 100);
    expect(result.totalInterest, closeTo(0, 1e-10));
    expect(result.schedule.last.remainingBalance, 0);
  });

  test('schedule period limit produces a typed validation failure', () {
    expect(
      () => service.fixedPaymentLoan(
        principal: 1000,
        annualRatePercent: 5,
        termYears: 51,
        paymentsPerYear: 12,
      ),
      throwsA(
        isA<FinancialValidationException>().having(
          (error) => error.issue,
          'issue',
          FinancialIssue.scheduleLimitExceeded,
        ),
      ),
    );
  });
}

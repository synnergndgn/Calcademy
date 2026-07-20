import 'package:calcademy/features/financial_calculator/application/tvm_service.dart';
import 'package:calcademy/features/financial_calculator/domain/financial_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = TvmService();

  test('present and future value match known annual values', () {
    final pv = service.presentValue(
      futureValue: 1000,
      annualRatePercent: 10,
      periodCount: 5,
    );
    final fv = service.futureValue(
      presentValue: 1000,
      annualRatePercent: 10,
      periodCount: 5,
    );
    expect(pv.value, closeTo(620.9213231, 1e-7));
    expect(fv.value, closeTo(1610.51, 1e-9));
  });

  test('annuity values and beginning-of-period adjustment are correct', () {
    final pv = service.annuityPresentValue(
      payment: 100,
      annualRatePercent: 10,
      periodCount: 5,
      timing: PaymentTiming.endOfPeriod,
    );
    final fv = service.annuityFutureValue(
      payment: 100,
      annualRatePercent: 10,
      periodCount: 5,
      timing: PaymentTiming.endOfPeriod,
    );
    final due = service.annuityFutureValue(
      payment: 100,
      annualRatePercent: 10,
      periodCount: 5,
      timing: PaymentTiming.beginningOfPeriod,
    );
    expect(pv.value, closeTo(379.0786769, 1e-7));
    expect(fv.value, closeTo(610.51, 1e-9));
    expect(due.value, closeTo(fv.value * 1.1, 1e-9));
  });

  test('effective annual rate and zero-rate annuity are safe', () {
    final ear = service.effectiveAnnualRate(
      nominalAnnualRatePercent: 12,
      compoundingFrequency: 12,
    );
    final zero = service.annuityPresentValue(
      payment: 100,
      annualRatePercent: 0,
      periodCount: 5,
      timing: PaymentTiming.endOfPeriod,
    );
    expect(ear.value, closeTo(12.68250301, 1e-8));
    expect(zero.value, 500);
  });

  test('invalid rate and period are typed failures', () {
    expect(
      () => service.futureValue(
        presentValue: 1,
        annualRatePercent: -100,
        periodCount: 1,
      ),
      throwsA(isA<FinancialValidationException>()),
    );
    expect(
      () => service.futureValue(
        presentValue: 1,
        annualRatePercent: 5,
        periodCount: 0,
      ),
      throwsA(isA<FinancialValidationException>()),
    );
  });
}

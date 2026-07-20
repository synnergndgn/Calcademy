import 'dart:math' as math;

import 'package:calcademy/features/financial_calculator/domain/financial_limits.dart';
import 'package:calcademy/features/financial_calculator/domain/financial_result.dart';

class LoanService {
  const LoanService();

  LoanResult fixedPaymentLoan({
    required double principal,
    required double annualRatePercent,
    required int termYears,
    required int paymentsPerYear,
  }) {
    if (!principal.isFinite || principal <= 0) {
      throw const FinancialValidationException(FinancialIssue.invalidPrincipal);
    }
    if (!annualRatePercent.isFinite ||
        annualRatePercent < 0 ||
        annualRatePercent > FinancialLimits.maxInterestRatePercent) {
      throw const FinancialValidationException(FinancialIssue.invalidRate);
    }
    if (termYears <= 0) {
      throw const FinancialValidationException(FinancialIssue.invalidLoanTerm);
    }
    if (paymentsPerYear < FinancialLimits.minPaymentsPerYear ||
        paymentsPerYear > FinancialLimits.maxPaymentsPerYear) {
      throw const FinancialValidationException(
        FinancialIssue.invalidPaymentFrequency,
      );
    }
    final periods = termYears * paymentsPerYear;
    if (periods > FinancialLimits.maxLoanSchedulePeriods) {
      throw const FinancialValidationException(
        FinancialIssue.scheduleLimitExceeded,
      );
    }
    final rate = annualRatePercent / 100 / paymentsPerYear;
    final regularPayment = rate.abs() <= FinancialLimits.calculationTolerance
        ? principal / periods
        : principal * rate / (1 - math.pow(1 + rate, -periods));
    if (!regularPayment.isFinite) {
      throw const FinancialValidationException(FinancialIssue.calculationRange);
    }

    var balance = principal;
    var totalPayment = 0.0;
    final schedule = <AmortizationRow>[];
    for (var period = 1; period <= periods; period++) {
      final interest = balance * rate;
      final isLast = period == periods;
      final principalPaid = isLast ? balance : regularPayment - interest;
      final payment = principalPaid + interest;
      balance = isLast ? 0 : balance - principalPaid;
      if (balance.abs() <= FinancialLimits.calculationTolerance) balance = 0;
      schedule.add(
        AmortizationRow(
          period: period,
          payment: payment,
          interest: interest,
          principal: principalPaid,
          remainingBalance: balance,
        ),
      );
      totalPayment += payment;
    }
    return LoanResult(
      periodicPayment: regularPayment.toDouble(),
      totalPayment: totalPayment,
      totalInterest: totalPayment - principal,
      schedule: List.unmodifiable(schedule),
      inputs: {
        'principal': principal,
        'annualRatePercent': annualRatePercent,
        'termYears': termYears.toDouble(),
        'paymentsPerYear': paymentsPerYear.toDouble(),
      },
    );
  }
}

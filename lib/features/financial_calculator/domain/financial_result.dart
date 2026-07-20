enum FinancialIssue {
  emptyInput,
  invalidNumber,
  invalidRate,
  invalidPeriod,
  invalidCompoundingFrequency,
  invalidPaymentFrequency,
  emptyCashFlows,
  ambiguousSeparator,
  tooManyCashFlows,
  invalidCashFlowPattern,
  irrNoSignChange,
  irrNonConvergence,
  invalidPrincipal,
  invalidLoanTerm,
  scheduleLimitExceeded,
  invalidContributionMargin,
  negativeFixedCost,
  invalidTargetProfit,
  invalidActualSales,
  calculationRange,
}

enum FinancialWarning {
  approximateIrr,
  multipleIrrPossible,
  paybackNotReached,
  discountedPaybackNotReached,
}

enum TvmOperation {
  presentValue,
  futureValue,
  annuityPresentValue,
  annuityFutureValue,
  effectiveAnnualRate,
}

enum PaymentTiming { endOfPeriod, beginningOfPeriod }

enum CashFlowOperation { npv, irr, payback, discountedPayback }

enum BreakEvenOperation { breakEven, targetProfit, marginOfSafety }

sealed class FinancialResult {
  const FinancialResult({
    required this.methodKey,
    required this.inputs,
    required this.diagnostics,
    required this.warnings,
    required this.approximate,
  });

  final String methodKey;
  final Map<String, double> inputs;
  final List<String> diagnostics;
  final List<FinancialWarning> warnings;
  final bool approximate;
}

class TvmResult extends FinancialResult {
  const TvmResult({
    required this.operation,
    required this.value,
    required this.ratePercent,
    required this.periods,
    required super.methodKey,
    required super.inputs,
    super.diagnostics = const ['finDiagnosticRatePercent'],
    super.warnings = const [],
    super.approximate = false,
  });

  final TvmOperation operation;
  final double value;
  final double ratePercent;
  final int periods;
}

class CashFlowRow {
  const CashFlowRow({
    required this.period,
    required this.cashFlow,
    required this.discountedCashFlow,
    required this.cumulativeCashFlow,
  });

  final int period;
  final double cashFlow;
  final double discountedCashFlow;
  final double cumulativeCashFlow;
}

class CashFlowResult extends FinancialResult {
  const CashFlowResult({
    required this.operation,
    required this.value,
    required this.ratePercent,
    required this.rows,
    this.irrCandidatesPercent = const [],
    required super.methodKey,
    required super.inputs,
    required super.diagnostics,
    required super.warnings,
    required super.approximate,
  });

  final CashFlowOperation operation;
  final double? value;
  final double ratePercent;
  final List<CashFlowRow> rows;
  final List<double> irrCandidatesPercent;
}

class AmortizationRow {
  const AmortizationRow({
    required this.period,
    required this.payment,
    required this.interest,
    required this.principal,
    required this.remainingBalance,
  });

  final int period;
  final double payment;
  final double interest;
  final double principal;
  final double remainingBalance;
}

class LoanResult extends FinancialResult {
  const LoanResult({
    required this.periodicPayment,
    required this.totalPayment,
    required this.totalInterest,
    required this.schedule,
    required super.inputs,
    super.methodKey = 'finMethodFixedPaymentLoan',
    super.diagnostics = const ['finDiagnosticLastBalanceClosed'],
    super.warnings = const [],
    super.approximate = false,
  });

  final double periodicPayment;
  final double totalPayment;
  final double totalInterest;
  final List<AmortizationRow> schedule;
}

class BreakEvenResult extends FinancialResult {
  const BreakEvenResult({
    required this.operation,
    required this.breakEvenQuantity,
    required this.breakEvenRevenue,
    required this.contributionMargin,
    this.targetQuantity,
    this.marginOfSafetyQuantity,
    this.marginOfSafetyPercent,
    required super.inputs,
    super.methodKey = 'finMethodCvp',
    super.diagnostics = const ['finDiagnosticContinuousQuantity'],
    super.warnings = const [],
    super.approximate = false,
  });

  final BreakEvenOperation operation;
  final double breakEvenQuantity;
  final double breakEvenRevenue;
  final double contributionMargin;
  final double? targetQuantity;
  final double? marginOfSafetyQuantity;
  final double? marginOfSafetyPercent;
}

class FinancialFailureResult extends FinancialResult {
  const FinancialFailureResult(this.issue)
    : super(
        methodKey: 'finCalculationFailed',
        inputs: const {},
        diagnostics: const [],
        warnings: const [],
        approximate: false,
      );

  final FinancialIssue issue;
}

class FinancialValidationException implements Exception {
  const FinancialValidationException(this.issue);

  final FinancialIssue issue;
}

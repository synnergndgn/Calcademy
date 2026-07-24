import 'package:calcademy/features/financial_calculator/domain/financial_result.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';

enum FinancialRestoreMode { tvm, cashFlow, loan, breakEven }

/// Editable inputs rebuilt from a saved financial-calculator record.
class FinancialRestore {
  const FinancialRestore.tvm({
    required TvmOperation this.tvmOperation,
    required this.fields,
    this.timing,
  }) : mode = FinancialRestoreMode.tvm,
       cashFlowOperation = null,
       cashFlows = const [],
       breakEvenOperation = null;

  const FinancialRestore.cashFlow({
    required CashFlowOperation this.cashFlowOperation,
    required this.cashFlows,
    required this.fields,
  }) : mode = FinancialRestoreMode.cashFlow,
       tvmOperation = null,
       timing = null,
       breakEvenOperation = null;

  const FinancialRestore.loan({required this.fields})
    : mode = FinancialRestoreMode.loan,
      tvmOperation = null,
      timing = null,
      cashFlowOperation = null,
      cashFlows = const [],
      breakEvenOperation = null;

  const FinancialRestore.breakEven({
    required BreakEvenOperation this.breakEvenOperation,
    required this.fields,
  }) : mode = FinancialRestoreMode.breakEven,
       tvmOperation = null,
       timing = null,
       cashFlowOperation = null,
       cashFlows = const [];

  final FinancialRestoreMode mode;
  final TvmOperation? tvmOperation;
  final PaymentTiming? timing;
  final CashFlowOperation? cashFlowOperation;
  final List<double> cashFlows;
  final BreakEvenOperation? breakEvenOperation;

  /// Numeric parameters keyed by the service input names.
  final Map<String, double> fields;
}

/// Restore parsing for financial records. TVM records need the v2
/// `operation` key (numeric inputs cannot recover present/future/annuity
/// choice); cash-flow records need the v2 `cashFlows` list. Loan and
/// break-even records were always fully described by their inputs.
/// Anything insufficient returns null and stays result-only.
abstract final class FinancialSavedAdapter {
  static FinancialRestore? tryRestore(SavedCalculation item) {
    if (item.module != SavedCalculationModule.financialCalculator) return null;
    final payload = item.fullInputJson;
    final type = item.calculationType;

    if (type == 'tvm') {
      final operation = TvmOperation.values
          .where((value) => value.name == payload['operation'])
          .firstOrNull;
      if (operation == null) return null;
      final rate = _finite(payload['ratePercent']);
      final frequency = _finite(payload['frequency']);
      if (rate == null || frequency == null || frequency < 1) return null;
      final fields = <String, double>{
        'ratePercent': rate,
        'frequency': frequency,
      };
      if (operation == TvmOperation.effectiveAnnualRate) {
        return FinancialRestore.tvm(tvmOperation: operation, fields: fields);
      }
      final periods = _finite(payload['periodCount']);
      if (periods == null || periods < 1) return null;
      fields['periodCount'] = periods;
      final amount = _finite(
        payload['futureValue'] ?? payload['presentValue'] ?? payload['payment'],
      );
      if (amount == null) return null;
      fields['amount'] = amount;
      final timing = switch (payload['timing']) {
        0 => PaymentTiming.endOfPeriod,
        1 => PaymentTiming.beginningOfPeriod,
        _ => null,
      };
      return FinancialRestore.tvm(
        tvmOperation: operation,
        fields: fields,
        timing: timing,
      );
    }

    final cashFlowOperation = CashFlowOperation.values
        .where((value) => value.name == type)
        .firstOrNull;
    if (cashFlowOperation != null) {
      final rawFlows = payload['cashFlows'];
      final initial = _finite(payload['initialInvestment']);
      if (rawFlows is! List || rawFlows.isEmpty || initial == null) return null;
      final flows = <double>[];
      for (final value in rawFlows) {
        final parsed = _finite(value);
        if (parsed == null) return null;
        flows.add(parsed);
      }
      final fields = <String, double>{'initialInvestment': initial};
      final rate = _finite(payload['discountRatePercent']);
      if (rate != null) fields['discountRatePercent'] = rate;
      // NPV and discounted payback need a discount rate to reproduce.
      if ((cashFlowOperation == CashFlowOperation.npv ||
              cashFlowOperation == CashFlowOperation.discountedPayback) &&
          rate == null) {
        return null;
      }
      return FinancialRestore.cashFlow(
        cashFlowOperation: cashFlowOperation,
        cashFlows: flows,
        fields: fields,
      );
    }

    if (type == 'loan') {
      final principal = _finite(payload['principal']);
      final rate = _finite(payload['annualRatePercent']);
      final term = _finite(payload['termYears']);
      final paymentsPerYear = _finite(payload['paymentsPerYear']);
      if (principal == null ||
          rate == null ||
          term == null ||
          term < 1 ||
          paymentsPerYear == null ||
          paymentsPerYear < 1) {
        return null;
      }
      return FinancialRestore.loan(
        fields: {
          'principal': principal,
          'annualRatePercent': rate,
          'termYears': term,
          'paymentsPerYear': paymentsPerYear,
        },
      );
    }

    final breakEvenOperation = BreakEvenOperation.values
        .where((value) => value.name == type)
        .firstOrNull;
    if (breakEvenOperation != null) {
      final fixedCost = _finite(payload['fixedCost']);
      final unitPrice = _finite(payload['unitPrice']);
      final variableCost = _finite(payload['variableCost']);
      if (fixedCost == null || unitPrice == null || variableCost == null) {
        return null;
      }
      final fields = <String, double>{
        'fixedCost': fixedCost,
        'unitPrice': unitPrice,
        'variableCost': variableCost,
      };
      if (breakEvenOperation == BreakEvenOperation.targetProfit) {
        final target = _finite(payload['targetProfit']);
        if (target == null) return null;
        fields['targetProfit'] = target;
      }
      if (breakEvenOperation == BreakEvenOperation.marginOfSafety) {
        final actual = _finite(payload['actualSalesQuantity']);
        if (actual == null) return null;
        fields['actualSalesQuantity'] = actual;
      }
      return FinancialRestore.breakEven(
        breakEvenOperation: breakEvenOperation,
        fields: fields,
      );
    }

    return null;
  }

  static double? _finite(Object? value) =>
      value is num && value.isFinite ? value.toDouble() : null;
}

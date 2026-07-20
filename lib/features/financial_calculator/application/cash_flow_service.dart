import 'dart:math' as math;

import 'package:calcademy/features/financial_calculator/domain/cash_flow_parser.dart';
import 'package:calcademy/features/financial_calculator/domain/financial_limits.dart';
import 'package:calcademy/features/financial_calculator/domain/financial_result.dart';

class CashFlowService {
  const CashFlowService({this.parser = const CashFlowParser()});

  final CashFlowParser parser;

  CashFlowResult npv({
    required double discountRatePercent,
    required double initialInvestment,
    required String cashFlowInput,
  }) {
    final values = _validatedInputs(initialInvestment, cashFlowInput);
    final rate = _validateRate(discountRatePercent);
    var total = -initialInvestment;
    final rows = <CashFlowRow>[
      CashFlowRow(
        period: 0,
        cashFlow: -initialInvestment,
        discountedCashFlow: -initialInvestment,
        cumulativeCashFlow: -initialInvestment,
      ),
    ];
    for (var index = 0; index < values.length; index++) {
      final period = index + 1;
      final discounted = values[index] / math.pow(1 + rate, period);
      total += discounted;
      rows.add(
        CashFlowRow(
          period: period,
          cashFlow: values[index],
          discountedCashFlow: discounted,
          cumulativeCashFlow: total,
        ),
      );
    }
    _ensureFinite(total);
    return CashFlowResult(
      operation: CashFlowOperation.npv,
      value: total,
      ratePercent: discountRatePercent,
      rows: List.unmodifiable(rows),
      methodKey: 'finMethodNpv',
      inputs: {
        'initialInvestment': initialInvestment,
        'discountRatePercent': discountRatePercent,
      },
      diagnostics: const ['finDiagnosticInitialAtZero'],
      warnings: const [],
      approximate: false,
    );
  }

  CashFlowResult irr({
    required double initialInvestment,
    required String cashFlowInput,
  }) {
    final values = _validatedInputs(initialInvestment, cashFlowInput);
    final sequence = [-initialInvestment, ...values];
    final nonZero = sequence
        .where((value) => value.abs() > FinancialLimits.calculationTolerance)
        .toList();
    if (nonZero.length < 2 || !nonZero.any((value) => value > 0)) {
      throw const FinancialValidationException(FinancialIssue.irrNoSignChange);
    }
    var cashFlowSignChanges = 0;
    for (var index = 1; index < nonZero.length; index++) {
      if (nonZero[index].sign != nonZero[index - 1].sign) {
        cashFlowSignChanges++;
      }
    }

    final roots = <double>[];
    final minY = math.log(1 + FinancialLimits.irrRateFloor);
    final maxY = math.log(1 + FinancialLimits.irrRateCeiling);
    var previousRate = math.exp(minY) - 1;
    var previousValue = _npvAtRate(sequence, previousRate);
    for (var step = 1; step <= FinancialLimits.irrScanSteps; step++) {
      final y = minY + (maxY - minY) * step / FinancialLimits.irrScanSteps;
      final rate = math.exp(y) - 1;
      final value = _npvAtRate(sequence, rate);
      if (value.isFinite && previousValue.isFinite) {
        if (value.abs() <= FinancialLimits.calculationTolerance) {
          _addRoot(roots, rate);
        } else if (value.sign != previousValue.sign) {
          _addRoot(roots, _bisect(sequence, previousRate, rate, previousValue));
        }
      }
      previousRate = rate;
      previousValue = value;
    }
    if (roots.isEmpty) {
      throw const FinancialValidationException(
        FinancialIssue.irrNonConvergence,
      );
    }
    roots.sort();
    final candidates = roots.map((rate) => rate * 100).toList(growable: false);
    return CashFlowResult(
      operation: CashFlowOperation.irr,
      value: candidates.first,
      ratePercent: candidates.first,
      rows: const [],
      irrCandidatesPercent: List.unmodifiable(candidates),
      methodKey: 'finMethodIrrBisection',
      inputs: {'initialInvestment': initialInvestment},
      diagnostics: const ['finDiagnosticIrrRange'],
      warnings: [
        FinancialWarning.approximateIrr,
        if (cashFlowSignChanges > 1 || candidates.length > 1)
          FinancialWarning.multipleIrrPossible,
      ],
      approximate: true,
    );
  }

  CashFlowResult payback({
    required double initialInvestment,
    required String cashFlowInput,
    double? discountRatePercent,
  }) {
    final values = _validatedInputs(initialInvestment, cashFlowInput);
    final discounted = discountRatePercent != null;
    final rate = discounted ? _validateRate(discountRatePercent) : 0.0;
    var cumulative = -initialInvestment;
    double? paybackPeriod;
    final rows = <CashFlowRow>[
      CashFlowRow(
        period: 0,
        cashFlow: -initialInvestment,
        discountedCashFlow: -initialInvestment,
        cumulativeCashFlow: cumulative,
      ),
    ];
    for (var index = 0; index < values.length; index++) {
      final period = index + 1;
      final adjusted = discounted
          ? values[index] / math.pow(1 + rate, period)
          : values[index];
      final before = cumulative;
      cumulative += adjusted;
      if (paybackPeriod == null &&
          before < 0 &&
          cumulative >= 0 &&
          adjusted > 0) {
        paybackPeriod = index + (-before / adjusted);
      }
      rows.add(
        CashFlowRow(
          period: period,
          cashFlow: values[index],
          discountedCashFlow: adjusted,
          cumulativeCashFlow: cumulative,
        ),
      );
    }
    return CashFlowResult(
      operation: discounted
          ? CashFlowOperation.discountedPayback
          : CashFlowOperation.payback,
      value: paybackPeriod,
      ratePercent: discountRatePercent ?? 0,
      rows: List.unmodifiable(rows),
      methodKey: discounted ? 'finMethodDiscountedPayback' : 'finMethodPayback',
      inputs: {
        'initialInvestment': initialInvestment,
        if (discounted) 'discountRatePercent': discountRatePercent,
      },
      diagnostics: const ['finDiagnosticFractionalPayback'],
      warnings: [
        if (paybackPeriod == null)
          discounted
              ? FinancialWarning.discountedPaybackNotReached
              : FinancialWarning.paybackNotReached,
      ],
      approximate: false,
    );
  }

  List<double> _validatedInputs(double initialInvestment, String input) {
    if (!initialInvestment.isFinite || initialInvestment <= 0) {
      throw const FinancialValidationException(
        FinancialIssue.invalidCashFlowPattern,
      );
    }
    return parser.parse(input);
  }

  static double _validateRate(double ratePercent) {
    if (!ratePercent.isFinite ||
        ratePercent < FinancialLimits.minInterestRatePercent ||
        ratePercent > FinancialLimits.maxInterestRatePercent) {
      throw const FinancialValidationException(FinancialIssue.invalidRate);
    }
    return ratePercent / 100;
  }

  static double _npvAtRate(List<double> flows, double rate) {
    var total = 0.0;
    for (var period = 0; period < flows.length; period++) {
      total += flows[period] / math.pow(1 + rate, period);
    }
    return total;
  }

  static double _bisect(
    List<double> flows,
    double lower,
    double upper,
    double lowerValue,
  ) {
    var a = lower;
    var b = upper;
    var fa = lowerValue;
    for (
      var iteration = 0;
      iteration < FinancialLimits.irrMaxIterations;
      iteration++
    ) {
      final midpoint = (a + b) / 2;
      final value = _npvAtRate(flows, midpoint);
      if (value.abs() <= FinancialLimits.calculationTolerance ||
          (b - a).abs() <= FinancialLimits.calculationTolerance) {
        return midpoint;
      }
      if (value.sign == fa.sign) {
        a = midpoint;
        fa = value;
      } else {
        b = midpoint;
      }
    }
    final result = (a + b) / 2;
    if (!_npvAtRate(flows, result).isFinite) {
      throw const FinancialValidationException(
        FinancialIssue.irrNonConvergence,
      );
    }
    return result;
  }

  static void _addRoot(List<double> roots, double root) {
    if (roots.every((value) => (value - root).abs() > 1e-6)) roots.add(root);
  }

  static void _ensureFinite(double value) {
    if (!value.isFinite) {
      throw const FinancialValidationException(FinancialIssue.calculationRange);
    }
  }
}

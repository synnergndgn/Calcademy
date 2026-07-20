import 'dart:math' as math;

import 'package:calcademy/features/financial_calculator/domain/financial_limits.dart';
import 'package:calcademy/features/financial_calculator/domain/financial_result.dart';

class TvmService {
  const TvmService();

  TvmResult presentValue({
    required double futureValue,
    required double annualRatePercent,
    required int periodCount,
    int compoundingFrequency = 1,
  }) {
    final terms = _terms(annualRatePercent, periodCount, compoundingFrequency);
    return _result(
      operation: TvmOperation.presentValue,
      value: futureValue / math.pow(1 + terms.rate, terms.periods),
      ratePercent: annualRatePercent,
      periods: terms.periods,
      methodKey: 'finMethodPresentValue',
      inputs: {'futureValue': futureValue, ...terms.inputs},
    );
  }

  TvmResult futureValue({
    required double presentValue,
    required double annualRatePercent,
    required int periodCount,
    int compoundingFrequency = 1,
  }) {
    final terms = _terms(annualRatePercent, periodCount, compoundingFrequency);
    return _result(
      operation: TvmOperation.futureValue,
      value: presentValue * math.pow(1 + terms.rate, terms.periods),
      ratePercent: annualRatePercent,
      periods: terms.periods,
      methodKey: 'finMethodFutureValue',
      inputs: {'presentValue': presentValue, ...terms.inputs},
    );
  }

  TvmResult annuityPresentValue({
    required double payment,
    required double annualRatePercent,
    required int periodCount,
    required PaymentTiming timing,
    int compoundingFrequency = 1,
  }) {
    final terms = _terms(annualRatePercent, periodCount, compoundingFrequency);
    final base = terms.rate.abs() <= FinancialLimits.calculationTolerance
        ? payment * terms.periods
        : payment * (1 - math.pow(1 + terms.rate, -terms.periods)) / terms.rate;
    final value = timing == PaymentTiming.beginningOfPeriod
        ? base * (1 + terms.rate)
        : base;
    return _result(
      operation: TvmOperation.annuityPresentValue,
      value: value,
      ratePercent: annualRatePercent,
      periods: terms.periods,
      methodKey: 'finMethodAnnuityPresentValue',
      inputs: {
        'payment': payment,
        'timing': timing.index.toDouble(),
        ...terms.inputs,
      },
    );
  }

  TvmResult annuityFutureValue({
    required double payment,
    required double annualRatePercent,
    required int periodCount,
    required PaymentTiming timing,
    int compoundingFrequency = 1,
  }) {
    final terms = _terms(annualRatePercent, periodCount, compoundingFrequency);
    final base = terms.rate.abs() <= FinancialLimits.calculationTolerance
        ? payment * terms.periods
        : payment * (math.pow(1 + terms.rate, terms.periods) - 1) / terms.rate;
    final value = timing == PaymentTiming.beginningOfPeriod
        ? base * (1 + terms.rate)
        : base;
    return _result(
      operation: TvmOperation.annuityFutureValue,
      value: value,
      ratePercent: annualRatePercent,
      periods: terms.periods,
      methodKey: 'finMethodAnnuityFutureValue',
      inputs: {
        'payment': payment,
        'timing': timing.index.toDouble(),
        ...terms.inputs,
      },
    );
  }

  TvmResult effectiveAnnualRate({
    required double nominalAnnualRatePercent,
    required int compoundingFrequency,
  }) {
    _validateRate(nominalAnnualRatePercent);
    _validateFrequency(compoundingFrequency);
    final periodic = nominalAnnualRatePercent / 100 / compoundingFrequency;
    final value = (math.pow(1 + periodic, compoundingFrequency) - 1) * 100;
    return _result(
      operation: TvmOperation.effectiveAnnualRate,
      value: value,
      ratePercent: nominalAnnualRatePercent,
      periods: compoundingFrequency,
      methodKey: 'finMethodEffectiveAnnualRate',
      inputs: {
        'nominalRatePercent': nominalAnnualRatePercent,
        'frequency': compoundingFrequency.toDouble(),
      },
    );
  }

  static ({double rate, int periods, Map<String, double> inputs}) _terms(
    double ratePercent,
    int periodCount,
    int frequency,
  ) {
    _validateRate(ratePercent);
    _validatePeriod(periodCount);
    _validateFrequency(frequency);
    final totalPeriods = periodCount * frequency;
    if (totalPeriods > FinancialLimits.maxPeriodCount) {
      throw const FinancialValidationException(FinancialIssue.invalidPeriod);
    }
    return (
      rate: ratePercent / 100 / frequency,
      periods: totalPeriods,
      inputs: {
        'ratePercent': ratePercent,
        'periodCount': periodCount.toDouble(),
        'frequency': frequency.toDouble(),
      },
    );
  }

  static TvmResult _result({
    required TvmOperation operation,
    required num value,
    required double ratePercent,
    required int periods,
    required String methodKey,
    required Map<String, double> inputs,
  }) {
    final result = value.toDouble();
    if (!result.isFinite) {
      throw const FinancialValidationException(FinancialIssue.calculationRange);
    }
    return TvmResult(
      operation: operation,
      value: result,
      ratePercent: ratePercent,
      periods: periods,
      methodKey: methodKey,
      inputs: Map.unmodifiable(inputs),
    );
  }

  static void _validateRate(double rate) {
    if (!rate.isFinite ||
        rate < FinancialLimits.minInterestRatePercent ||
        rate > FinancialLimits.maxInterestRatePercent) {
      throw const FinancialValidationException(FinancialIssue.invalidRate);
    }
  }

  static void _validatePeriod(int period) {
    if (period <= 0 || period > FinancialLimits.maxPeriodCount) {
      throw const FinancialValidationException(FinancialIssue.invalidPeriod);
    }
  }

  static void _validateFrequency(int frequency) {
    if (frequency < FinancialLimits.minCompoundingFrequency ||
        frequency > FinancialLimits.maxCompoundingFrequency) {
      throw const FinancialValidationException(
        FinancialIssue.invalidCompoundingFrequency,
      );
    }
  }
}

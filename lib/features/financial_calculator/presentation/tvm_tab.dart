import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/financial_calculator/domain/financial_result.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_controller.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_result_card.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_widgets.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TvmTab extends ConsumerStatefulWidget {
  const TvmTab({super.key});

  @override
  ConsumerState<TvmTab> createState() => _TvmTabState();
}

class _TvmTabState extends ConsumerState<TvmTab> {
  final _amount = TextEditingController(text: '1000');
  final _rate = TextEditingController(text: '10');
  final _periods = TextEditingController(text: '5');
  final _frequency = TextEditingController(text: '1');
  var _operation = TvmOperation.presentValue;
  var _timing = PaymentTiming.endOfPeriod;

  @override
  void dispose() {
    _amount.dispose();
    _rate.dispose();
    _periods.dispose();
    _frequency.dispose();
    super.dispose();
  }

  void _calculate() {
    ref.read(financialWorkspaceProvider.notifier).calculate(() {
      final service = ref.read(tvmServiceProvider);
      final amount = parseFinancialDouble(_amount.text);
      final rate = parseFinancialDouble(_rate.text);
      final frequency = parseFinancialInt(
        _frequency.text,
        FinancialIssue.invalidCompoundingFrequency,
      );
      if (_operation == TvmOperation.effectiveAnnualRate) {
        return service.effectiveAnnualRate(
          nominalAnnualRatePercent: rate,
          compoundingFrequency: frequency,
        );
      }
      final periods = parseFinancialInt(
        _periods.text,
        FinancialIssue.invalidPeriod,
      );
      return switch (_operation) {
        TvmOperation.presentValue => service.presentValue(
          futureValue: amount,
          annualRatePercent: rate,
          periodCount: periods,
          compoundingFrequency: frequency,
        ),
        TvmOperation.futureValue => service.futureValue(
          presentValue: amount,
          annualRatePercent: rate,
          periodCount: periods,
          compoundingFrequency: frequency,
        ),
        TvmOperation.annuityPresentValue => service.annuityPresentValue(
          payment: amount,
          annualRatePercent: rate,
          periodCount: periods,
          timing: _timing,
          compoundingFrequency: frequency,
        ),
        TvmOperation.annuityFutureValue => service.annuityFutureValue(
          payment: amount,
          annualRatePercent: rate,
          periodCount: periods,
          timing: _timing,
          compoundingFrequency: frequency,
        ),
        TvmOperation.effectiveAnnualRate => throw StateError('handled above'),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = ref.watch(
      financialWorkspaceProvider.select((state) => state.result),
    );
    final isAnnuity =
        _operation == TvmOperation.annuityPresentValue ||
        _operation == TvmOperation.annuityFutureValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<TvmOperation>(
          key: const Key('fin-tvm-operation'),
          initialValue: _operation,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.t('finCalculation')),
          items: [
            for (final operation in TvmOperation.values)
              DropdownMenuItem(
                value: operation,
                child: Text(l10n.t(_operationKey(operation))),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _operation = value);
            ref.read(financialWorkspaceProvider.notifier).clear();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        if (isAnnuity) ...[
          DropdownButtonFormField<PaymentTiming>(
            key: const Key('fin-payment-timing'),
            initialValue: _timing,
            decoration: InputDecoration(labelText: l10n.t('finPaymentTiming')),
            items: [
              DropdownMenuItem(
                value: PaymentTiming.endOfPeriod,
                child: Text(l10n.t('finEndOfPeriod')),
              ),
              DropdownMenuItem(
                value: PaymentTiming.beginningOfPeriod,
                child: Text(l10n.t('finBeginningOfPeriod')),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _timing = value);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        FinancialFieldGrid(
          children: [
            if (_operation != TvmOperation.effectiveAnnualRate)
              financialField(
                'fin-tvm-amount',
                _amount,
                l10n.t(
                  isAnnuity
                      ? 'finPayment'
                      : _operation == TvmOperation.presentValue
                      ? 'finFutureValue'
                      : 'finPresentValue',
                ),
              ),
            financialField(
              'fin-tvm-rate',
              _rate,
              l10n.t(
                _operation == TvmOperation.effectiveAnnualRate
                    ? 'finNominalAnnualRatePercent'
                    : 'finAnnualInterestRatePercent',
              ),
              helperText: l10n.t('finRatePercentHelp'),
            ),
            if (_operation != TvmOperation.effectiveAnnualRate)
              financialField(
                'fin-tvm-periods',
                _periods,
                l10n.t('finPeriodCountYears'),
                decimal: false,
              ),
            financialField(
              'fin-tvm-frequency',
              _frequency,
              l10n.t('finCompoundingFrequency'),
              decimal: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          key: const Key('fin-tvm-calculate'),
          onPressed: _calculate,
          icon: const Icon(Icons.calculate_rounded),
          label: Text(l10n.t('finCalculate')),
        ),
        if (result != null) ...[
          const SizedBox(height: AppSpacing.md),
          FinancialResultCard(result: result),
        ],
      ],
    );
  }

  static String _operationKey(TvmOperation operation) => switch (operation) {
    TvmOperation.presentValue => 'finPresentValue',
    TvmOperation.futureValue => 'finFutureValue',
    TvmOperation.annuityPresentValue => 'finAnnuityPresentValue',
    TvmOperation.annuityFutureValue => 'finAnnuityFutureValue',
    TvmOperation.effectiveAnnualRate => 'finEffectiveAnnualRate',
  };
}

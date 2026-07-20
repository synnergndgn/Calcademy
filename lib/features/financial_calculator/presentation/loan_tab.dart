import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/financial_calculator/domain/financial_result.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_controller.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_result_card.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_widgets.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoanTab extends ConsumerStatefulWidget {
  const LoanTab({super.key});

  @override
  ConsumerState<LoanTab> createState() => _LoanTabState();
}

class _LoanTabState extends ConsumerState<LoanTab> {
  final _principal = TextEditingController(text: '10000');
  final _rate = TextEditingController(text: '12');
  final _term = TextEditingController(text: '2');
  final _paymentsPerYear = TextEditingController(text: '12');

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    _term.dispose();
    _paymentsPerYear.dispose();
    super.dispose();
  }

  void _calculate() {
    ref
        .read(financialWorkspaceProvider.notifier)
        .calculate(
          () => ref
              .read(loanServiceProvider)
              .fixedPaymentLoan(
                principal: parseFinancialDouble(_principal.text),
                annualRatePercent: parseFinancialDouble(_rate.text),
                termYears: parseFinancialInt(
                  _term.text,
                  FinancialIssue.invalidLoanTerm,
                ),
                paymentsPerYear: parseFinancialInt(
                  _paymentsPerYear.text,
                  FinancialIssue.invalidPaymentFrequency,
                ),
              ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = ref.watch(
      financialWorkspaceProvider.select((state) => state.result),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.t('finFixedPaymentLoan'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        FinancialFieldGrid(
          children: [
            financialField(
              'fin-loan-principal',
              _principal,
              l10n.t('finPrincipal'),
            ),
            financialField(
              'fin-loan-rate',
              _rate,
              l10n.t('finAnnualInterestRatePercent'),
              helperText: l10n.t('finRatePercentHelp'),
            ),
            financialField(
              'fin-loan-term',
              _term,
              l10n.t('finTermYears'),
              decimal: false,
            ),
            financialField(
              'fin-payments-per-year',
              _paymentsPerYear,
              l10n.t('finPaymentsPerYear'),
              decimal: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          key: const Key('fin-loan-calculate'),
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
}

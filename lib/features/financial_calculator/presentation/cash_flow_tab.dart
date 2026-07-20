import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/financial_calculator/domain/financial_result.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_controller.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_result_card.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_widgets.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CashFlowTab extends ConsumerStatefulWidget {
  const CashFlowTab({super.key});

  @override
  ConsumerState<CashFlowTab> createState() => _CashFlowTabState();
}

class _CashFlowTabState extends ConsumerState<CashFlowTab> {
  final _initial = TextEditingController(text: '1000');
  final _rate = TextEditingController(text: '10');
  final _cashFlows = TextEditingController(text: '600, 600');
  var _operation = CashFlowOperation.npv;

  @override
  void dispose() {
    _initial.dispose();
    _rate.dispose();
    _cashFlows.dispose();
    super.dispose();
  }

  void _calculate() {
    ref.read(financialWorkspaceProvider.notifier).calculate(() {
      final service = ref.read(cashFlowServiceProvider);
      final initial = parseFinancialDouble(_initial.text);
      return switch (_operation) {
        CashFlowOperation.npv => service.npv(
          discountRatePercent: parseFinancialDouble(_rate.text),
          initialInvestment: initial,
          cashFlowInput: _cashFlows.text,
        ),
        CashFlowOperation.irr => service.irr(
          initialInvestment: initial,
          cashFlowInput: _cashFlows.text,
        ),
        CashFlowOperation.payback => service.payback(
          initialInvestment: initial,
          cashFlowInput: _cashFlows.text,
        ),
        CashFlowOperation.discountedPayback => service.payback(
          initialInvestment: initial,
          cashFlowInput: _cashFlows.text,
          discountRatePercent: parseFinancialDouble(_rate.text),
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = ref.watch(
      financialWorkspaceProvider.select((state) => state.result),
    );
    final needsRate =
        _operation == CashFlowOperation.npv ||
        _operation == CashFlowOperation.discountedPayback;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<CashFlowOperation>(
          key: const Key('fin-cash-operation'),
          initialValue: _operation,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.t('finCalculation')),
          items: [
            for (final operation in CashFlowOperation.values)
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
        FinancialFieldGrid(
          children: [
            financialField(
              'fin-initial-investment',
              _initial,
              l10n.t('finInitialInvestment'),
            ),
            if (needsRate)
              financialField(
                'fin-discount-rate',
                _rate,
                l10n.t('finDiscountRatePercent'),
                helperText: l10n.t('finRatePercentHelp'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const Key('fin-cash-flow-input'),
          controller: _cashFlows,
          minLines: 3,
          maxLines: 7,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: InputDecoration(
            labelText: l10n.t('finCashFlowList'),
            helperText: l10n.t('finCashFlowHelp'),
            helperMaxLines: 3,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          key: const Key('fin-cash-calculate'),
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

  static String _operationKey(CashFlowOperation operation) =>
      switch (operation) {
        CashFlowOperation.npv => 'finNpv',
        CashFlowOperation.irr => 'finIrr',
        CashFlowOperation.payback => 'finPayback',
        CashFlowOperation.discountedPayback => 'finDiscountedPayback',
      };
}

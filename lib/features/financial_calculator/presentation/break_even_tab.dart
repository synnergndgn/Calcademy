import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/financial_calculator/domain/financial_result.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_controller.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_result_card.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_widgets.dart';
import 'package:calcademy/features/matrix/domain/matrix_number_formatter.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/financial_saved_adapter.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BreakEvenTab extends ConsumerStatefulWidget {
  const BreakEvenTab({super.key, this.restore});

  /// Inputs rebuilt from a saved record; seeds the form (still editable)
  /// and recomputes automatically.
  final FinancialRestore? restore;

  @override
  ConsumerState<BreakEvenTab> createState() => _BreakEvenTabState();
}

class _BreakEvenTabState extends ConsumerState<BreakEvenTab> {
  final _fixedCost = TextEditingController(text: '10000');
  final _price = TextEditingController(text: '50');
  final _variableCost = TextEditingController(text: '30');
  final _targetProfit = TextEditingController(text: '5000');
  final _actualQuantity = TextEditingController(text: '750');
  var _operation = BreakEvenOperation.breakEven;

  @override
  void initState() {
    super.initState();
    final restore = widget.restore;
    if (restore == null ||
        restore.mode != FinancialRestoreMode.breakEven ||
        restore.breakEvenOperation == null) {
      return;
    }
    _operation = restore.breakEvenOperation!;
    final fields = restore.fields;
    if (fields['fixedCost'] != null) {
      _fixedCost.text = formatMatrixNumber(fields['fixedCost']!);
    }
    if (fields['unitPrice'] != null) {
      _price.text = formatMatrixNumber(fields['unitPrice']!);
    }
    if (fields['variableCost'] != null) {
      _variableCost.text = formatMatrixNumber(fields['variableCost']!);
    }
    if (fields['targetProfit'] != null) {
      _targetProfit.text = formatMatrixNumber(fields['targetProfit']!);
    }
    if (fields['actualSalesQuantity'] != null) {
      _actualQuantity.text = formatMatrixNumber(fields['actualSalesQuantity']!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _calculate();
    });
  }

  @override
  void dispose() {
    _fixedCost.dispose();
    _price.dispose();
    _variableCost.dispose();
    _targetProfit.dispose();
    _actualQuantity.dispose();
    super.dispose();
  }

  void _calculate() {
    ref
        .read(financialWorkspaceProvider.notifier)
        .calculate(
          () => ref
              .read(breakEvenServiceProvider)
              .calculate(
                operation: _operation,
                fixedCost: parseFinancialDouble(_fixedCost.text),
                unitPrice: parseFinancialDouble(_price.text),
                variableCostPerUnit: parseFinancialDouble(_variableCost.text),
                targetProfit: _operation == BreakEvenOperation.targetProfit
                    ? parseFinancialDouble(_targetProfit.text)
                    : 0,
                actualSalesQuantity:
                    _operation == BreakEvenOperation.marginOfSafety
                    ? parseFinancialDouble(_actualQuantity.text)
                    : 0,
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
        DropdownButtonFormField<BreakEvenOperation>(
          key: const Key('fin-break-even-operation'),
          initialValue: _operation,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.t('finCalculation')),
          items: [
            DropdownMenuItem(
              value: BreakEvenOperation.breakEven,
              child: Text(l10n.t('finBreakEvenQuantityRevenue')),
            ),
            DropdownMenuItem(
              value: BreakEvenOperation.targetProfit,
              child: Text(l10n.t('finTargetProfitQuantity')),
            ),
            DropdownMenuItem(
              value: BreakEvenOperation.marginOfSafety,
              child: Text(l10n.t('finMarginOfSafety')),
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
              'fin-fixed-cost',
              _fixedCost,
              l10n.t('finFixedCost'),
            ),
            financialField('fin-unit-price', _price, l10n.t('finUnitPrice')),
            financialField(
              'fin-variable-cost',
              _variableCost,
              l10n.t('finVariableCostPerUnit'),
            ),
            if (_operation == BreakEvenOperation.targetProfit)
              financialField(
                'fin-target-profit',
                _targetProfit,
                l10n.t('finTargetProfit'),
              ),
            if (_operation == BreakEvenOperation.marginOfSafety)
              financialField(
                'fin-actual-quantity',
                _actualQuantity,
                l10n.t('finActualSalesQuantity'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          key: const Key('fin-break-even-calculate'),
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

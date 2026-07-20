import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/financial_calculator/presentation/break_even_tab.dart';
import 'package:calcademy/features/financial_calculator/presentation/cash_flow_tab.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_controller.dart';
import 'package:calcademy/features/financial_calculator/presentation/loan_tab.dart';
import 'package:calcademy/features/financial_calculator/presentation/tvm_tab.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FinancialMode { tvm, cashFlows, loan, breakEven }

class FinancialCalculatorPage extends ConsumerStatefulWidget {
  const FinancialCalculatorPage({super.key});

  @override
  ConsumerState<FinancialCalculatorPage> createState() =>
      _FinancialCalculatorPageState();
}

class _FinancialCalculatorPageState
    extends ConsumerState<FinancialCalculatorPage> {
  var _mode = FinancialMode.tvm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('financialCalculator'))),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: ListView(
              key: const Key('financial-scroll-view'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.lg + bottomInset,
              ),
              children: [
                Text(
                  l10n.t('finWelcome'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.t('finWelcomeBody')),
                const SizedBox(height: AppSpacing.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<FinancialMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: FinancialMode.tvm,
                        label: Text(l10n.t('finTvm')),
                      ),
                      ButtonSegment(
                        value: FinancialMode.cashFlows,
                        label: Text(l10n.t('finCashFlows')),
                      ),
                      ButtonSegment(
                        value: FinancialMode.loan,
                        label: Text(l10n.t('finLoan')),
                      ),
                      ButtonSegment(
                        value: FinancialMode.breakEven,
                        label: Text(l10n.t('finBreakEven')),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (selection) => setState(() {
                      _mode = selection.first;
                      ref.read(financialWorkspaceProvider.notifier).clear();
                    }),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: switch (_mode) {
                      FinancialMode.tvm => const TvmTab(),
                      FinancialMode.cashFlows => const CashFlowTab(),
                      FinancialMode.loan => const LoanTab(),
                      FinancialMode.breakEven => const BreakEvenTab(),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

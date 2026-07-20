import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/financial_calculator/domain/financial_limits.dart';
import 'package:calcademy/features/financial_calculator/domain/financial_result.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FinancialResultCard extends StatelessWidget {
  const FinancialResultCard({super.key, required this.result});

  final FinancialResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (result case FinancialFailureResult(:final issue)) {
      return Card(
        key: const Key('financial-result-card'),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(l10n.t(_issueKey(issue)))),
            ],
          ),
        ),
      );
    }
    final metrics = _metrics(result, l10n);
    final copyText = metrics
        .map((metric) => '${metric.$1}: ${metric.$2}')
        .join('\n');
    return Card(
      key: const Key('financial-result-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.t('finResult'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (result.approximate)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(l10n.t('finApproximate')),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.t('finMethod')}: ${l10n.t(result.methodKey)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _FinancialMetricGrid(metrics: metrics),
            if (result case CashFlowResult(
              :final rows,
            ) when rows.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _CashFlowTable(rows: rows),
            ],
            if (result case LoanResult(:final schedule)) ...[
              const SizedBox(height: AppSpacing.md),
              _AmortizationTable(rows: schedule),
            ],
            for (final diagnostic in result.diagnostics) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.t(diagnostic),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            for (final warning in result.warnings) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(l10n.t(_warningKey(warning)))),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                key: const Key('fin-copy-result'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: copyText));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.t('copied'))));
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(l10n.t('copyResult')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<(String, String)> _metrics(
    FinancialResult result,
    AppLocalizations l10n,
  ) {
    if (result is TvmResult) {
      return [
        (l10n.t('finValue'), _format(result.value)),
        (l10n.t('finUsedRatePercent'), _format(result.ratePercent)),
        (l10n.t('finTotalPeriods'), '${result.periods}'),
      ];
    }
    if (result is CashFlowResult) {
      return [
        (
          l10n.t(switch (result.operation) {
            CashFlowOperation.npv => 'finNpv',
            CashFlowOperation.irr => 'finIrr',
            CashFlowOperation.payback => 'finPayback',
            CashFlowOperation.discountedPayback => 'finDiscountedPayback',
          }),
          result.value == null
              ? l10n.t('finNotReached')
              : _format(result.value!),
        ),
        if (result.irrCandidatesPercent.length > 1)
          (
            l10n.t('finIrrCandidates'),
            result.irrCandidatesPercent.map(_format).join(', '),
          ),
        if (result.operation == CashFlowOperation.npv ||
            result.operation == CashFlowOperation.discountedPayback)
          (l10n.t('finUsedRatePercent'), _format(result.ratePercent)),
      ];
    }
    if (result is LoanResult) {
      return [
        (l10n.t('finPeriodicPayment'), _format(result.periodicPayment)),
        (l10n.t('finTotalPayment'), _format(result.totalPayment)),
        (l10n.t('finTotalInterest'), _format(result.totalInterest)),
      ];
    }
    if (result is BreakEvenResult) {
      return [
        (l10n.t('finContributionMargin'), _format(result.contributionMargin)),
        (l10n.t('finBreakEvenQuantity'), _format(result.breakEvenQuantity)),
        (l10n.t('finBreakEvenRevenue'), _format(result.breakEvenRevenue)),
        if (result.targetQuantity != null)
          (l10n.t('finTargetQuantity'), _format(result.targetQuantity!)),
        if (result.marginOfSafetyQuantity != null)
          (
            l10n.t('finMarginOfSafetyQuantity'),
            _format(result.marginOfSafetyQuantity!),
          ),
        if (result.marginOfSafetyPercent != null)
          (
            l10n.t('finMarginOfSafetyPercent'),
            _format(result.marginOfSafetyPercent!),
          ),
      ];
    }
    return const [];
  }

  static String _format(double value) {
    if (value == 0) return '0';
    if (value.abs() >= 1e12 || value.abs() < 1e-6) {
      return value.toStringAsExponential(6);
    }
    return value
        .toStringAsFixed(FinancialLimits.displayPrecision)
        .replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static String _warningKey(FinancialWarning warning) => switch (warning) {
    FinancialWarning.approximateIrr => 'finWarningApproximateIrr',
    FinancialWarning.multipleIrrPossible => 'finWarningMultipleIrr',
    FinancialWarning.paybackNotReached => 'finWarningPaybackNotReached',
    FinancialWarning.discountedPaybackNotReached =>
      'finWarningDiscountedPaybackNotReached',
  };

  static String _issueKey(FinancialIssue issue) => switch (issue) {
    FinancialIssue.emptyInput => 'finErrorEmptyInput',
    FinancialIssue.invalidNumber => 'finErrorInvalidNumber',
    FinancialIssue.invalidRate => 'finErrorInvalidRate',
    FinancialIssue.invalidPeriod => 'finErrorInvalidPeriod',
    FinancialIssue.invalidCompoundingFrequency => 'finErrorInvalidCompounding',
    FinancialIssue.invalidPaymentFrequency => 'finErrorInvalidPaymentFrequency',
    FinancialIssue.emptyCashFlows => 'finErrorEmptyCashFlows',
    FinancialIssue.ambiguousSeparator => 'finErrorAmbiguousSeparator',
    FinancialIssue.tooManyCashFlows => 'finErrorTooManyCashFlows',
    FinancialIssue.invalidCashFlowPattern => 'finErrorCashFlowPattern',
    FinancialIssue.irrNoSignChange => 'finErrorIrrNoSignChange',
    FinancialIssue.irrNonConvergence => 'finErrorIrrNonConvergence',
    FinancialIssue.invalidPrincipal => 'finErrorInvalidPrincipal',
    FinancialIssue.invalidLoanTerm => 'finErrorInvalidLoanTerm',
    FinancialIssue.scheduleLimitExceeded => 'finErrorScheduleLimit',
    FinancialIssue.invalidContributionMargin => 'finErrorContributionMargin',
    FinancialIssue.negativeFixedCost => 'finErrorNegativeFixedCost',
    FinancialIssue.invalidTargetProfit => 'finErrorInvalidTargetProfit',
    FinancialIssue.invalidActualSales => 'finErrorInvalidActualSales',
    FinancialIssue.calculationRange => 'finErrorCalculationRange',
  };
}

class _FinancialMetricGrid extends StatelessWidget {
  const _FinancialMetricGrid({required this.metrics});
  final List<(String, String)> metrics;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 640
          ? 3
          : constraints.maxWidth >= 360
          ? 2
          : 1;
      final width =
          (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final metric in metrics)
            SizedBox(
              width: width,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric.$1,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SelectableText(
                        metric.$2,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _CashFlowTable extends StatelessWidget {
  const _CashFlowTable({required this.rows});
  final List<CashFlowRow> rows;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const Key('fin-cash-flow-table'),
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: [
        DataColumn(label: Text(context.l10n.t('finPeriod'))),
        DataColumn(label: Text(context.l10n.t('finCashFlow'))),
        DataColumn(label: Text(context.l10n.t('finDiscountedCashFlow'))),
        DataColumn(label: Text(context.l10n.t('finCumulative'))),
      ],
      rows: [
        for (final row in rows)
          DataRow(
            cells: [
              DataCell(Text('${row.period}')),
              DataCell(Text(FinancialResultCard._format(row.cashFlow))),
              DataCell(
                Text(FinancialResultCard._format(row.discountedCashFlow)),
              ),
              DataCell(
                Text(FinancialResultCard._format(row.cumulativeCashFlow)),
              ),
            ],
          ),
      ],
    ),
  );
}

class _AmortizationTable extends StatelessWidget {
  const _AmortizationTable({required this.rows});
  final List<AmortizationRow> rows;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const Key('fin-amortization-table'),
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: [
        DataColumn(label: Text(context.l10n.t('finPeriod'))),
        DataColumn(label: Text(context.l10n.t('finPayment'))),
        DataColumn(label: Text(context.l10n.t('finInterest'))),
        DataColumn(label: Text(context.l10n.t('finPrincipalPart'))),
        DataColumn(label: Text(context.l10n.t('finRemainingBalance'))),
      ],
      rows: [
        for (final row in rows)
          DataRow(
            cells: [
              DataCell(Text('${row.period}')),
              DataCell(Text(FinancialResultCard._format(row.payment))),
              DataCell(Text(FinancialResultCard._format(row.interest))),
              DataCell(Text(FinancialResultCard._format(row.principal))),
              DataCell(Text(FinancialResultCard._format(row.remainingBalance))),
            ],
          ),
      ],
    ),
  );
}

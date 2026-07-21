import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart'
    show formatLpNumber;
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/operations_research_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/presentation/save_result_action.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GoalProgrammingResultBody extends StatelessWidget {
  const GoalProgrammingResultBody({super.key, required this.result});

  final GoalProgrammingResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final copyText = [
      '${l10n.t('orGoalProgramming')} · ${result.methodName}',
      '${l10n.t('orTotalWeightedDeviation')}: ${formatLpNumber(result.totalWeightedDeviation)}',
      for (final entry in result.decisionVariables.entries)
        '${entry.key} = ${formatLpNumber(entry.value)}',
    ].join('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.t('orGoalProgrammingResult'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          l10n.t('orOptimalSolution'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text('${l10n.t('orMethodUsed')}: ${result.methodName}'),
        Text('${l10n.t('orIterations')}: ${result.iterations}'),
        const Divider(),
        Text(
          '${l10n.t('orTotalWeightedDeviation')}: ${formatLpNumber(result.totalWeightedDeviation)}',
          key: const Key('or-goal-total-deviation'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final entry in result.decisionVariables.entries)
              Chip(
                label: Text('${entry.key} = ${formatLpNumber(entry.value)}'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.t('orGoalStatusTable'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SingleChildScrollView(
          key: const Key('or-goal-result-scroll'),
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text(l10n.t('orGoal'))),
              const DataColumn(label: Text('d−')),
              const DataColumn(label: Text('d+')),
              DataColumn(label: Text(l10n.t('orWeightedDeviation'))),
              DataColumn(label: Text(l10n.t('orSatisfied'))),
            ],
            rows: [
              for (final deviation in result.deviations)
                DataRow(
                  cells: [
                    DataCell(Text('G${deviation.goalIndex + 1}')),
                    DataCell(Text(formatLpNumber(deviation.under))),
                    DataCell(Text(formatLpNumber(deviation.over))),
                    DataCell(
                      Text(formatLpNumber(deviation.weightedContribution)),
                    ),
                    DataCell(
                      Icon(
                        deviation.satisfied
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        semanticLabel: deviation.satisfied
                            ? l10n.t('orSatisfied')
                            : l10n.t('orNotSatisfied'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        for (final warning in result.warnings) _Warning(text: l10n.t(warning)),
        _Actions(
          copyText: copyText,
          draft: OperationsResearchSavedAdapter.goalProgramming(result),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.copyText, required this.draft});

  final String copyText;
  final SavedCalculationDraft draft;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        TextButton.icon(
          key: const Key('or-copy-result'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: copyText));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(context.l10n.t('copied'))));
            }
          },
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: Text(context.l10n.t('copyResult')),
        ),
        SaveResultAction(buttonKey: const Key('or-save-result'), draft: draft),
      ],
    ),
  );
}

class _Warning extends StatelessWidget {
  const _Warning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: AppSpacing.xs),
    padding: const EdgeInsets.all(AppSpacing.xs),
    color: Theme.of(context).colorScheme.tertiaryContainer,
    child: Text(text),
  );
}

import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart'
    show formatLpNumber;
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';
import 'package:calcademy/features/operations_research/domain/project_network_problem.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/operations_research_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/presentation/save_result_action.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CpmPertResultBody extends StatelessWidget {
  const CpmPertResultBody({super.key, required this.result});

  final CpmPertResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pathText = result.criticalPaths.isEmpty
        ? result.criticalActivities.join(', ')
        : result.criticalPaths.map((path) => path.join(' → ')).join(' | ');
    final copyText = [
      '${result.methodName} · ${l10n.t('orProjectDuration')}: ${formatLpNumber(result.projectDuration)}',
      '${l10n.t('orCriticalPath')}: $pathText',
      if (result.projectStandardDeviation != null)
        '${l10n.t('orProjectStandardDeviation')}: ${formatLpNumber(result.projectStandardDeviation!)}',
    ].join('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.t('orCpmPertResult'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text('${l10n.t('orMethodUsed')}: ${result.methodName}'),
        const Divider(),
        Text(
          '${l10n.t('orProjectDuration')}: ${formatLpNumber(result.projectDuration)}',
          key: const Key('or-network-project-duration'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('${l10n.t('orCriticalPath')}: $pathText'),
        if (result.mode == ProjectScheduleMode.pert) ...[
          Text(
            '${l10n.t('orProjectVariance')}: ${formatLpNumber(result.projectVariance!)}',
          ),
          Text(
            '${l10n.t('orProjectStandardDeviation')}: ${formatLpNumber(result.projectStandardDeviation!)}',
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          key: const Key('or-network-result-scroll'),
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text(l10n.t('orActivity'))),
              DataColumn(
                label: Text(
                  result.mode == ProjectScheduleMode.pert
                      ? l10n.t('orExpectedTime')
                      : l10n.t('orDuration'),
                ),
              ),
              const DataColumn(label: Text('ES')),
              const DataColumn(label: Text('EF')),
              const DataColumn(label: Text('LS')),
              const DataColumn(label: Text('LF')),
              DataColumn(label: Text(l10n.t('orSlack'))),
              DataColumn(label: Text(l10n.t('orFreeFloat'))),
              if (result.mode == ProjectScheduleMode.pert)
                DataColumn(label: Text(l10n.t('orVariance'))),
              DataColumn(label: Text(l10n.t('orCritical'))),
            ],
            rows: [
              for (final row in result.activities)
                DataRow(
                  cells: [
                    DataCell(Text(row.id)),
                    DataCell(Text(formatLpNumber(row.duration))),
                    DataCell(Text(formatLpNumber(row.earliestStart))),
                    DataCell(Text(formatLpNumber(row.earliestFinish))),
                    DataCell(Text(formatLpNumber(row.latestStart))),
                    DataCell(Text(formatLpNumber(row.latestFinish))),
                    DataCell(Text(formatLpNumber(row.totalFloat))),
                    DataCell(Text(formatLpNumber(row.freeFloat))),
                    if (result.mode == ProjectScheduleMode.pert)
                      DataCell(Text(formatLpNumber(row.variance))),
                    DataCell(
                      Icon(
                        row.critical
                            ? Icons.check_circle_outline
                            : Icons.remove_circle_outline,
                        semanticLabel: row.critical
                            ? l10n.t('orCritical')
                            : l10n.t('orNotCritical'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        for (final warning in result.warnings)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.xs),
            padding: const EdgeInsets.all(AppSpacing.xs),
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Text(l10n.t(warning)),
          ),
        _Actions(
          copyText: copyText,
          draft: OperationsResearchSavedAdapter.cpmPert(result),
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

import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/integer_programming/domain/branch_node.dart';
import 'package:calcademy/features/integer_programming/domain/branching_strategy.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program.dart';
import 'package:calcademy/features/integer_programming/domain/mip_result.dart';
import 'package:calcademy/features/integer_programming/domain/node_selection_strategy.dart';
import 'package:calcademy/features/integer_programming/domain/saved_integer_program.dart';
import 'package:calcademy/features/integer_programming/presentation/branch_tree_page.dart';
import 'package:calcademy/features/integer_programming/presentation/integer_program_controller.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String pruneReasonLabel(AppLocalizations l10n, PruneReason reason) =>
    l10n.t(switch (reason) {
      PruneReason.bound => 'mipPruneBound',
      PruneReason.infeasible => 'mipPruneInfeasible',
      PruneReason.integral => 'mipPruneIntegral',
      PruneReason.depthLimit => 'mipPruneDepthLimit',
      PruneReason.unbounded => 'mipPruneUnbounded',
      PruneReason.error => 'mipPruneError',
    });

/// The result report (section 26 of the module spec): status, objective,
/// search statistics, and the actions to inspect the branch tree, save,
/// copy, or start over. Shows an indeterminate spinner while the solve
/// runs on the background isolate - see [IntegerProgramWorkspaceController]
/// for why a real percentage isn't attempted.
class IntegerSolutionPanel extends ConsumerWidget {
  const IntegerSolutionPanel({
    super.key,
    required this.dirty,
    required this.activeSavedId,
    required this.onSave,
    required this.onNew,
  });

  final bool dirty;
  final String? activeSavedId;
  final Future<void> Function(IntegerProgram, MipResult, {bool copy}) onSave;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final loading = ref.watch(
      integerProgramWorkspaceProvider.select((state) => state.loading),
    );
    final result = ref.watch(
      integerProgramWorkspaceProvider.select((state) => state.result),
    );
    final program = ref.watch(
      integerProgramWorkspaceProvider.select((state) => state.program),
    );
    final error = ref.watch(
      integerProgramWorkspaceProvider.select((state) => state.error),
    );

    if (loading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.t('mipSolving')),
            ],
          ),
        ),
      );
    }
    if (error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(l10n.t('mipNumericError')),
        ),
      );
    }
    if (result == null || program == null) return const SizedBox.shrink();
    if (dirty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(l10n.t('mipResultStale')),
        ),
      );
    }

    final summary = MipResultSummary.fromResult(result);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.t('mipResult'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              l10n.t(summary.statusKey),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (summary.limitReasonKey != null)
              Text(l10n.t(summary.limitReasonKey!)),
            if (result.rootRelaxationObjective != null)
              Text(
                '${l10n.t('mipRootRelaxation')}: '
                '${formatLpNumber(result.rootRelaxationObjective!)}',
              ),
            Text(
              '${l10n.t('mipBranchingStrategy')}: '
              '${l10n.t(result.branchingStrategy == BranchingStrategy.mostFractional ? 'mipMostFractional' : 'mipFirstFractional')}',
            ),
            Text(
              '${l10n.t('mipNodeStrategy')}: '
              '${l10n.t(result.nodeSelectionStrategy == NodeSelectionStrategy.depthFirst ? 'mipDepthFirst' : 'mipBestBound')}',
            ),
            Text('${l10n.t('mipNodesSolved')}: ${result.nodesSolved}'),
            Text('${l10n.t('mipMaxDepth')}: ${result.maxDepthReached}'),
            for (final reason in PruneReason.values)
              if (result.pruneCounts[reason] != null)
                Text(
                  '${pruneReasonLabel(l10n, reason)}: ${result.pruneCounts[reason]}',
                ),
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              for (final warning in result.warnings.toSet())
                Text(
                  l10n.t(warning),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
            if (summary.objectiveValue != null) ...[
              const Divider(),
              Text(
                'Z = ${formatLpNumber(summary.objectiveValue!)}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              for (final entry in summary.variableValues.entries)
                Text('${entry.key} = ${formatLpNumber(entry.value)}'),
              if (summary.bestBound != null)
                Text(
                  '${l10n.t('mipBestBound')}: '
                  '${formatLpNumber(summary.bestBound!)}',
                ),
              if (summary.relativeGap != null)
                Text(
                  '${l10n.t('mipOptimalityGap')}: '
                  '${(summary.relativeGap! * 100).toStringAsFixed(2)}%',
                ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BranchTreePage(result: result, program: program),
                    ),
                  ),
                  icon: const Icon(Icons.account_tree_outlined),
                  label: Text(l10n.t('mipBranchTree')),
                ),
                OutlinedButton.icon(
                  onPressed: () => onSave(program, result),
                  icon: const Icon(Icons.save),
                  label: Text(
                    l10n.t(
                      activeSavedId == null ? 'lpSaveModel' : 'lpSaveChanges',
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => onSave(program, result, copy: true),
                  icon: const Icon(Icons.copy_all),
                  label: Text(l10n.t('lpSaveCopy')),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: _copyText(l10n, program, result, summary),
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(l10n.t('copied'))));
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(l10n.t('lpCopyResult')),
                ),
                OutlinedButton.icon(
                  onPressed: onNew,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.t('lpNewModel')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _copyText(
    AppLocalizations l10n,
    IntegerProgram program,
    MipResult result,
    MipResultSummary summary,
  ) {
    final model = program.linearModel;
    final sign = model.direction == ObjectiveDirection.maximize ? 'Max' : 'Min';
    final objective = [
      for (var index = 0; index < model.objective.length; index++)
        '${formatLpNumber(model.objective[index])}${model.variables[index].name}',
    ].join('+');
    final buffer = StringBuffer('$sign Z = $objective\n');
    for (final constraint in model.constraints) {
      final symbol = switch (constraint.relation) {
        ConstraintRelation.lessOrEqual => '<=',
        ConstraintRelation.greaterOrEqual => '>=',
        ConstraintRelation.equal => '=',
      };
      final terms = [
        for (var index = 0; index < constraint.coefficients.length; index++)
          if (constraint.coefficients[index] != 0)
            '${formatLpNumber(constraint.coefficients[index])}${model.variables[index].name}',
      ].join('+');
      buffer.write('$terms $symbol ${formatLpNumber(constraint.rhs)}\n');
    }
    buffer.write('\n${l10n.t(summary.statusKey)}\n');
    if (summary.objectiveValue != null) {
      for (final entry in summary.variableValues.entries) {
        buffer.write('${entry.key} = ${formatLpNumber(entry.value)}\n');
      }
      buffer.write('Z = ${formatLpNumber(summary.objectiveValue!)}\n');
    }
    buffer.write('\n${l10n.t('mipNodesSolved')}: ${result.nodesSolved}\n');
    if (summary.relativeGap != null) {
      buffer.write(
        '${l10n.t('mipOptimalityGap')}: '
        '${(summary.relativeGap! * 100).toStringAsFixed(2)}%\n',
      );
    }
    return buffer.toString();
  }
}

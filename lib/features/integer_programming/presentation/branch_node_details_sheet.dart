import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/integer_programming/domain/branch_node.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// A node's status shown as icon + text + tonal background - never colour
/// alone, per the module's accessibility notes.
(IconData, Color Function(ColorScheme)) nodeStatusVisual(
  NodeStatus status,
) => switch (status) {
  NodeStatus.pending => (Icons.hourglass_empty, (c) => c.surfaceContainerHigh),
  NodeStatus.solving => (Icons.autorenew, (c) => c.secondaryContainer),
  NodeStatus.fractional => (
    Icons.pending_outlined,
    (c) => c.surfaceContainerHigh,
  ),
  NodeStatus.integerFeasible => (Icons.emoji_events, (c) => c.primaryContainer),
  NodeStatus.prunedByBound => (
    Icons.content_cut,
    (c) => c.surfaceContainerHigh,
  ),
  NodeStatus.prunedInfeasible => (Icons.block, (c) => c.errorContainer),
  NodeStatus.prunedIntegral => (
    Icons.check_circle_outline,
    (c) => c.secondaryContainer,
  ),
  NodeStatus.unbounded => (Icons.open_in_full, (c) => c.errorContainer),
  NodeStatus.error => (Icons.error_outline, (c) => c.errorContainer),
};

String nodeStatusLabel(AppLocalizations l10n, NodeStatus status) =>
    l10n.t('mipNodeStatus${status.name}');

class BranchNodeDetailsSheet extends StatelessWidget {
  const BranchNodeDetailsSheet({
    super.key,
    required this.node,
    required this.program,
  });

  final BranchNode node;
  final IntegerProgram program;

  static Future<void> show(
    BuildContext context, {
    required BranchNode node,
    required IntegerProgram program,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BranchNodeDetailsSheet(node: node, program: program),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final (icon, background) = nodeStatusVisual(node.status);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.3,
      builder: (context, controller) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ListView(
          controller: controller,
          children: [
            Text(
              '${l10n.t('mipNodeDetails')} · ${node.id}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: background(theme.colorScheme),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(nodeStatusLabel(l10n, node.status)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('${l10n.t('mipDepth')}: ${node.depth}'),
            Text(
              '${l10n.t('mipParentNode')}: ${node.parentId ?? l10n.t('mipRootNode')}',
            ),
            const Divider(height: AppSpacing.lg),
            Text(
              l10n.t('mipBranchConstraints'),
              style: theme.textTheme.titleMedium,
            ),
            if (node.additionalConstraints.isEmpty)
              Text(l10n.t('mipRootNode'))
            else
              for (final constraint in node.additionalConstraints)
                Text('• ${constraint.describe()}'),
            if (node.relaxationObjective != null) ...[
              const Divider(height: AppSpacing.lg),
              Text(
                '${l10n.t('mipRelaxationObjective')}: '
                '${formatLpNumber(node.relaxationObjective!)}',
                style: theme.textTheme.titleMedium,
              ),
            ],
            if (node.relaxationValues != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.t('mipRelaxationValues'),
                style: theme.textTheme.titleSmall,
              ),
              for (final entry in node.relaxationValues!.entries)
                Builder(
                  builder: (context) {
                    final variable = program.linearModel.variables
                        .where((item) => item.name == entry.key)
                        .firstOrNull;
                    final isFractionalVar =
                        variable != null &&
                        program.isIntegerOrBinary(variable.id) &&
                        node.status == NodeStatus.fractional &&
                        (entry.value - entry.value.roundToDouble()).abs() >
                            1e-7;
                    return Text(
                      '${entry.key} = ${formatLpNumber(entry.value)}'
                      '${isFractionalVar ? ' (${l10n.t('mipFractional')})' : ''}',
                    );
                  },
                ),
            ],
            if (node.branchDecision != null) ...[
              const Divider(height: AppSpacing.lg),
              Text(
                l10n.t('mipBranchVariable'),
                style: theme.textTheme.titleMedium,
              ),
              Text(
                '${node.branchDecision!.variableName} = '
                '${formatLpNumber(node.branchDecision!.fractionalValue)}',
              ),
              Text(
                '${l10n.t('mipLowerBranch')}: '
                '${node.branchDecision!.lowerBranchConstraint.describe()}',
              ),
              Text(
                '${l10n.t('mipUpperBranch')}: '
                '${node.branchDecision!.upperBranchConstraint.describe()}',
              ),
            ],
            if (node.pruneReason != null) ...[
              const Divider(height: AppSpacing.lg),
              Text(
                '${l10n.t('mipPruneReason')}: ${l10n.t(node.pruneReason!)}',
                style: theme.textTheme.titleMedium,
              ),
            ],
            if (node.isIncumbent) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(l10n.t('mipIncumbent')),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

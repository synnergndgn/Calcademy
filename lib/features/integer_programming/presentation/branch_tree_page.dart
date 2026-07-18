import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/empty_state.dart';
import 'package:calcademy/features/integer_programming/domain/branch_node.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program.dart';
import 'package:calcademy/features/integer_programming/domain/mip_result.dart';
import 'package:calcademy/features/integer_programming/presentation/branch_node_details_sheet.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Shows the whole Branch-and-Bound search as a depth-indented,
/// collapsible list rather than a free-form canvas tree: a canvas layout
/// would need custom hit-testing and layout for up to
/// [MipConstants.maxNodes] nodes, which is both slower and harder to read
/// on a phone than a plain, scrollable list. The full node list is
/// flattened into a single pass per build (cheap even at 5000 nodes);
/// [ListView.builder] then only builds the rows currently on screen.
class BranchTreePage extends StatefulWidget {
  const BranchTreePage({
    super.key,
    required this.result,
    required this.program,
  });

  final MipResult result;
  final IntegerProgram program;

  @override
  State<BranchTreePage> createState() => _BranchTreePageState();
}

class _BranchTreePageState extends State<BranchTreePage> {
  late final Map<String?, List<BranchNode>> _childrenByParent;
  final _collapsed = <String>{};

  @override
  void initState() {
    super.initState();
    _childrenByParent = <String?, List<BranchNode>>{};
    for (final node in widget.result.branchTree) {
      _childrenByParent.putIfAbsent(node.parentId, () => []).add(node);
    }
  }

  List<BranchNode> _visibleNodes() {
    final visible = <BranchNode>[];
    void visit(BranchNode node) {
      visible.add(node);
      if (_collapsed.contains(node.id)) return;
      for (final child in _childrenByParent[node.id] ?? const <BranchNode>[]) {
        visit(child);
      }
    }

    for (final root in _childrenByParent[null] ?? const <BranchNode>[]) {
      visit(root);
    }
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = widget.result;
    final visible = _visibleNodes();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('mipBranchTree'))),
      body: result.branchTree.isEmpty
          ? EmptyState(
              icon: Icons.account_tree_outlined,
              title: l10n.t('mipNoNodes'),
              body: l10n.t('mipNoNodesBody'),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (result.rootRelaxationObjective != null)
                        Text(
                          '${l10n.t('mipRootRelaxation')}: '
                          '${formatLpNumber(result.rootRelaxationObjective!)}',
                        ),
                      Text(
                        '${l10n.t('mipNodesSolved')}: ${result.nodesSolved}',
                      ),
                      Text('${l10n.t('mipOpenNodes')}: ${result.openNodes}'),
                      Text(
                        '${l10n.t('mipMaxDepth')}: ${result.maxDepthReached}',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final node = visible[index];
                      final children =
                          _childrenByParent[node.id] ?? const <BranchNode>[];
                      final hasChildren = children.isNotEmpty;
                      final collapsed = _collapsed.contains(node.id);
                      final (icon, background) = nodeStatusVisual(node.status);
                      final theme = Theme.of(context);
                      // Indentation is visually capped: with a depth limit
                      // of 50, an uncapped `depth * 16` would push deep
                      // node cards 800px off a phone screen. Past the cap
                      // the depth is written in the subtitle instead (see
                      // _subtitle), so the hierarchy stays readable.
                      final indent =
                          node.depth.clamp(0, _maxIndentLevels) * 16.0;
                      return Padding(
                        padding: EdgeInsets.only(
                          left: indent,
                          right: AppSpacing.md,
                          bottom: AppSpacing.xs,
                        ),
                        child: Card(
                          color: background(theme.colorScheme),
                          child: ListTile(
                            onTap: () => BranchNodeDetailsSheet.show(
                              context,
                              node: node,
                              program: widget.program,
                            ),
                            leading: hasChildren
                                ? IconButton(
                                    tooltip: collapsed
                                        ? l10n.t('mipExpand')
                                        : l10n.t('mipCollapse'),
                                    icon: Icon(
                                      collapsed
                                          ? Icons.expand_more
                                          : Icons.expand_less,
                                    ),
                                    onPressed: () => setState(() {
                                      if (collapsed) {
                                        _collapsed.remove(node.id);
                                      } else {
                                        _collapsed.add(node.id);
                                      }
                                    }),
                                  )
                                : Icon(icon),
                            title: Text(
                              '${l10n.t('mipNode')} ${node.id}'
                              '${node.isIncumbent ? '  ★' : ''}',
                            ),
                            subtitle: Text(_subtitle(l10n, node)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  static const _maxIndentLevels = 8;

  String _subtitle(AppLocalizations l10n, BranchNode node) {
    final parts = <String>[
      if (node.depth > _maxIndentLevels) '${l10n.t('mipDepth')} ${node.depth}',
      nodeStatusLabel(l10n, node.status),
    ];
    if (node.relaxationObjective != null) {
      parts.add(
        '${l10n.t('mipRelaxationObjective')} '
        '${formatLpNumber(node.relaxationObjective!)}',
      );
    }
    if (node.branchDecision != null) {
      parts.add(
        '${node.branchDecision!.variableName} = '
        '${formatLpNumber(node.branchDecision!.fractionalValue)}',
      );
    }
    if (node.pruneReason != null) parts.add(l10n.t(node.pruneReason!));
    return parts.join(' · ');
  }
}

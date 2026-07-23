import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/empty_state.dart';
import 'package:calcademy/features/graph/data/graph_export_service.dart';
import 'package:calcademy/features/graph/data/graph_repository.dart';
import 'package:calcademy/features/graph/presentation/graph_canvas.dart';
import 'package:calcademy/features/graph/presentation/graph_controller.dart';
import 'package:calcademy/features/graph/presentation/graph_function_card.dart';
import 'package:calcademy/features/graph/presentation/graph_settings_sheet.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/graph_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/presentation/save_result_action.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class GraphPage extends ConsumerStatefulWidget {
  const GraphPage({super.key, this.savedGraphId, this.shareOnOpen = false});

  final String? savedGraphId;
  final bool shareOnOpen;

  @override
  ConsumerState<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends ConsumerState<GraphPage> {
  final _exportBoundaryKey = GlobalKey();
  var _didLoadRoute = false;
  var _pendingShare = false;

  @override
  void initState() {
    super.initState();
    _pendingShare = widget.shareOnOpen;
  }

  @override
  Widget build(BuildContext context) {
    if (!_didLoadRoute) {
      _didLoadRoute = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final id = widget.savedGraphId;
        if (id != null) ref.read(graphProvider.notifier).loadSaved(id);
      });
    }
    ref.listen(
      graphProvider.select(
        (state) =>
            (state.activeGraphId, state.isSampling, state.series.isNotEmpty),
      ),
      (_, next) {
        if (_pendingShare &&
            next.$1 == widget.savedGraphId &&
            !next.$2 &&
            next.$3) {
          _pendingShare = false;
          WidgetsBinding.instance.addPostFrameCallback((_) => _shareGraph());
        }
      },
    );
    final workspace = ref.watch(
      graphProvider.select(
        (state) => (
          title: state.activeTitle,
          isDirty: state.isDirty,
          isSaved: state.isSavedWorkspace,
          isSampling: state.isSampling,
          mode: state.angleMode,
        ),
      ),
    );
    final useCompactTitle =
        MediaQuery.textScalerOf(context).scale(1) >= 1.6 ||
        MediaQuery.sizeOf(context).width < 360;
    return Scaffold(
      appBar: AppBar(
        title: useCompactTitle
            ? Text(
                context.l10n.t('graphing'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workspace.title ?? context.l10n.t('graphing'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    [
                      workspace.mode.name == 'radians' ? 'RAD' : 'DEG',
                      if (workspace.isDirty) context.l10n.t('graphModified'),
                      if (workspace.isSampling) context.l10n.t('graphUpdating'),
                    ].join(' | '),
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: context.l10n.t('graphShare'),
            onPressed: _shareGraph,
            icon: const Icon(Icons.ios_share_rounded),
          ),
          PopupMenuButton<_GraphMenuAction>(
            tooltip: context.l10n.t('moreActions'),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _GraphMenuAction.newGraph,
                child: _MenuLabel(
                  icon: Icons.add_chart_rounded,
                  text: context.l10n.t('graphNew'),
                ),
              ),
              PopupMenuItem(
                value: _GraphMenuAction.save,
                child: _MenuLabel(
                  icon: Icons.save_outlined,
                  text: context.l10n.t(
                    workspace.isSaved ? 'graphSaveChanges' : 'graphSave',
                  ),
                ),
              ),
              if (workspace.isSaved) ...[
                PopupMenuItem(
                  value: _GraphMenuAction.saveCopy,
                  child: _MenuLabel(
                    icon: Icons.copy_rounded,
                    text: context.l10n.t('graphSaveCopy'),
                  ),
                ),
                PopupMenuItem(
                  value: _GraphMenuAction.rename,
                  child: _MenuLabel(
                    icon: Icons.drive_file_rename_outline_rounded,
                    text: context.l10n.t('graphRename'),
                  ),
                ),
                PopupMenuItem(
                  value: _GraphMenuAction.delete,
                  child: _MenuLabel(
                    icon: Icons.delete_outline_rounded,
                    text: context.l10n.t('delete'),
                  ),
                ),
              ],
              PopupMenuItem(
                value: _GraphMenuAction.savedGraphs,
                child: _MenuLabel(
                  icon: Icons.folder_outlined,
                  text: context.l10n.t('graphSavedGraphs'),
                ),
              ),
              PopupMenuItem(
                value: _GraphMenuAction.resetView,
                child: _MenuLabel(
                  icon: Icons.restart_alt_rounded,
                  text: context.l10n.t('graphReset'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              children: [
                const GraphFunctionList(),
                const SizedBox(height: AppSpacing.md),
                GraphCanvas(repaintBoundaryKey: _exportBoundaryKey),
                const GraphInspectionPanel(),
                const SizedBox(height: AppSpacing.md),
                const Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _GraphSavedCalculationAction(),
                ),
                const SizedBox(height: AppSpacing.xs),
                const GraphSettingsPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(_GraphMenuAction action) async {
    switch (action) {
      case _GraphMenuAction.newGraph:
        ref.read(graphProvider.notifier).newGraph();
      case _GraphMenuAction.save:
        final state = ref.read(graphProvider);
        if (state.isSavedWorkspace) {
          final saved = await ref.read(graphProvider.notifier).saveChanges();
          if (mounted) _showSaveResult(saved);
        } else {
          await _saveWithTitle();
        }
      case _GraphMenuAction.saveCopy:
        await _saveWithTitle(asCopy: true);
      case _GraphMenuAction.rename:
        await _saveWithTitle(rename: true);
      case _GraphMenuAction.delete:
        await _deleteCurrent();
      case _GraphMenuAction.savedGraphs:
        if (mounted) _showSavedGraphs();
      case _GraphMenuAction.resetView:
        ref.read(graphProvider.notifier).resetView();
    }
  }

  Future<void> _saveWithTitle({
    bool asCopy = false,
    bool rename = false,
  }) async {
    final state = ref.read(graphProvider);
    final initial = rename || asCopy ? state.activeTitle ?? '' : '';
    final title = await _askForTitle(initial);
    if (title == null || !mounted) return;
    final saved = await ref
        .read(graphProvider.notifier)
        .saveCurrent(title, asCopy: asCopy);
    if (mounted) _showSaveResult(saved);
  }

  Future<String?> _askForTitle(String initial) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('graphSave')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: context.l10n.t('graphTitle')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.t('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    return result?.trim().isEmpty == true ? null : result;
  }

  void _showSaveResult(bool saved) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.t(saved ? 'graphSaved' : 'graphNothingToSave'),
        ),
      ),
    );
  }

  Future<void> _shareGraph() async {
    if (!mounted) return;
    final state = ref.read(graphProvider);
    if (state.series.isEmpty || state.isSampling) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('graphNothingToShare'))),
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.t('graphPngCreating'))));
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    try {
      final box = context.findRenderObject() as RenderBox?;
      await ref
          .read(graphExportServiceProvider)
          .exportAndShare(
            boundaryKey: _exportBoundaryKey,
            title: state.activeTitle ?? context.l10n.t('graphing'),
            devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
            sharePositionOrigin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          );
    } on GraphExportException catch (error) {
      debugPrint('Graph export failed: ${error.failure.name}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.t('graphShareFailed'))),
        );
      }
    }
  }

  Future<void> _deleteCurrent() async {
    final confirmed = await _confirmDelete();
    if (confirmed == true) {
      await ref.read(graphProvider.notifier).deleteActive();
    }
  }

  Future<bool?> _confirmDelete() => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.t('graphDeleteQuestion')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.l10n.t('delete')),
        ),
      ],
    ),
  );

  void _showSavedGraphs() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _SavedGraphsSheet(),
    );
  }
}

class _GraphSavedCalculationAction extends ConsumerWidget {
  const _GraphSavedCalculationAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      graphProvider.select(
        (state) => (
          functions: state.functions,
          range: state.range,
          autoY: state.autoY,
          manualYMin: state.manualYMin,
          manualYMax: state.manualYMax,
          angleMode: state.angleMode,
          title: state.activeTitle,
        ),
      ),
    );
    final draft = GraphSavedAdapter.tryBuild(
      functions: state.functions,
      xRange: state.range,
      autoY: state.autoY,
      manualYMin: state.manualYMin,
      manualYMax: state.manualYMax,
      angleMode: state.angleMode,
      title: state.title,
    );
    if (draft == null) return const SizedBox.shrink();
    return SaveResultAction(
      buttonKey: const Key('graph-save-calculation'),
      draft: draft,
    );
  }
}

enum _GraphMenuAction {
  newGraph,
  save,
  saveCopy,
  rename,
  delete,
  savedGraphs,
  resetView,
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon),
      const SizedBox(width: AppSpacing.sm),
      Flexible(child: Text(text)),
    ],
  );
}

class _SavedGraphsSheet extends ConsumerWidget {
  const _SavedGraphsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedGraphsProvider);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: saved.isEmpty
            ? EmptyState(
                icon: Icons.folder_open_rounded,
                title: context.l10n.t('graphNoSaved'),
                body: context.l10n.t('graphNoSavedBody'),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                children: [
                  Text(
                    context.l10n.t('graphSavedGraphs'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final graph in saved)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.show_chart_rounded),
                        title: Text(graph.title),
                        subtitle: Text(
                          '${graph.functions.length} '
                          '${context.l10n.t('graphFunctions').toLowerCase()} | '
                          '${DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(graph.createdAt)}',
                        ),
                        onTap: () {
                          ref.read(graphProvider.notifier).loadSaved(graph.id);
                          Navigator.pop(context);
                        },
                        trailing: IconButton(
                          tooltip: context.l10n.t('delete'),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  context.l10n.t('graphDeleteQuestion'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(context.l10n.t('cancel')),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(context.l10n.t('delete')),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              final deletingActive =
                                  ref.read(graphProvider).activeGraphId ==
                                  graph.id;
                              await ref
                                  .read(savedGraphsProvider.notifier)
                                  .delete(graph.id);
                              if (deletingActive) {
                                ref.read(graphProvider.notifier).newGraph();
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

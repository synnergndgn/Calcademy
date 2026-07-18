import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/empty_state.dart';
import 'package:calcademy/features/graph/data/graph_repository.dart';
import 'package:calcademy/features/graph/domain/saved_graph.dart';
import 'package:calcademy/features/history/domain/saved_calculation.dart';
import 'package:calcademy/features/matrix/data/matrix_repository.dart';
import 'package:calcademy/features/matrix/domain/linear_system_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_number_formatter.dart';
import 'package:calcademy/features/matrix/domain/matrix_operation.dart';
import 'package:calcademy/features/matrix/domain/matrix_result.dart';
import 'package:calcademy/features/matrix/domain/saved_matrix_operation.dart';
import 'package:calcademy/features/linear_programming/data/linear_program_repository.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/features/linear_programming/domain/saved_linear_program.dart';
import 'package:calcademy/features/integer_programming/data/integer_program_repository.dart';
import 'package:calcademy/features/integer_programming/domain/saved_integer_program.dart';
import 'package:calcademy/features/saved/presentation/saved_controller.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.t('saved')),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: context.l10n.t('savedCalculations')),
              Tab(text: context.l10n.t('savedGraphs')),
              Tab(text: context.l10n.t('savedMatrices')),
              Tab(text: context.l10n.t('savedOptimizations')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SavedCalculationsTab(),
            _SavedGraphsTab(),
            _SavedMatricesTab(),
            _SavedOptimizationsTab(),
          ],
        ),
      ),
    );
  }
}

/// Both optimization modules share one "Optimization" tab (section 34 of
/// the integer programming module spec): a fifth top-level saved-items tab
/// would duplicate this list's job, so linear and integer program saves
/// are merged here and sorted together, with each card's icon/badge making
/// the model type explicit.
class _SavedOptimizationsTab extends ConsumerWidget {
  const _SavedOptimizationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lpModels = ref.watch(savedLinearProgramsProvider);
    final ipModels = ref.watch(savedIntegerProgramsProvider);
    final items = <Object>[...lpModels, ...ipModels]
      ..sort((a, b) => _updatedAt(b).compareTo(_updatedAt(a)));
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.polyline_rounded,
        title: context.l10n.t('lpNoSaved'),
        body: context.l10n.t('lpNoSavedBody'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return item is SavedLinearProgram
            ? _SavedOptimizationCard(model: item)
            : _SavedIntegerProgramCard(model: item as SavedIntegerProgram);
      },
    );
  }

  DateTime _updatedAt(Object item) => switch (item) {
    SavedLinearProgram(:final updatedAt) => updatedAt,
    SavedIntegerProgram(:final updatedAt) => updatedAt,
    _ => DateTime.fromMillisecondsSinceEpoch(0),
  };
}

class _SavedIntegerProgramCard extends ConsumerWidget {
  const _SavedIntegerProgramCard({required this.model});
  final SavedIntegerProgram model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri =
        '/integer-programming?savedId=${Uri.encodeQueryComponent(model.id)}';
    final result = model.result;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => context.push(uri),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.scatter_plot_rounded),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      model.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.t('lpSaveCopy'),
                    onPressed: () {
                      final now = DateTime.now();
                      ref
                          .read(savedIntegerProgramsProvider.notifier)
                          .upsert(
                            model.copyWith(
                              id: now.microsecondsSinceEpoch.toString(),
                              title:
                                  '${model.title} (${context.l10n.t('lpSaveCopy')})',
                              createdAt: now,
                            ),
                          );
                    },
                    icon: const Icon(Icons.copy),
                  ),
                  IconButton(
                    tooltip: context.l10n.t('delete'),
                    onPressed: () => _delete(context, ref),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              Text(
                '${context.l10n.t('integerProgramming')} · '
                '${model.program.linearModel.variables.length} '
                '${context.l10n.t('lpVariables').toLowerCase()} · '
                '${model.program.integerVariableCount} '
                '${context.l10n.t('mipIntegerBinaryCount')} · '
                '${model.program.linearModel.constraints.length} '
                '${context.l10n.t('lpConstraints').toLowerCase()}',
              ),
              Text(
                result == null
                    ? context.l10n.t('mipNotSolvedYet')
                    : context.l10n.t(result.statusKey),
              ),
              if (result?.objectiveValue != null)
                Text('z = ${formatLpNumber(result!.objectiveValue!)}'),
              if (result?.relativeGap != null)
                Text(
                  '${context.l10n.t('mipOptimalityGap')}: '
                  '${(result!.relativeGap! * 100).toStringAsFixed(2)}%',
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat.yMMMd(
                        Localizations.localeOf(context).toLanguageTag(),
                      ).add_Hm().format(model.updatedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(uri),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(context.l10n.t('lpOpenModel')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('mipDeleteQuestion')),
        content: Text(model.title),
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
    if (confirmed == true) {
      await ref.read(savedIntegerProgramsProvider.notifier).delete(model.id);
    }
  }
}

class _SavedOptimizationCard extends ConsumerWidget {
  const _SavedOptimizationCard({required this.model});
  final SavedLinearProgram model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri =
        '/linear-programming?savedId=${Uri.encodeQueryComponent(model.id)}';
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => context.push(uri),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.polyline_rounded),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      model.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.t('lpSaveCopy'),
                    onPressed: () {
                      final now = DateTime.now();
                      ref
                          .read(savedLinearProgramsProvider.notifier)
                          .upsert(
                            model.copyWith(
                              id: now.microsecondsSinceEpoch.toString(),
                              title:
                                  '${model.title} (${context.l10n.t('lpSaveCopy')})',
                              createdAt: now,
                            ),
                          );
                    },
                    icon: const Icon(Icons.copy),
                  ),
                  IconButton(
                    tooltip: context.l10n.t('delete'),
                    onPressed: () => _delete(context, ref),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              Text(
                '${model.program.direction == ObjectiveDirection.maximize ? context.l10n.t('lpMaximize') : context.l10n.t('lpMinimize')} · ${model.program.variables.length} ${context.l10n.t('lpVariables').toLowerCase()} · ${model.program.constraints.length} ${context.l10n.t('lpConstraints').toLowerCase()}',
              ),
              Text(context.l10n.t('lpStatus${model.status.name}')),
              if (model.objectiveValue != null)
                Text('z = ${model.objectiveValue}'),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat.yMMMd(
                        Localizations.localeOf(context).toLanguageTag(),
                      ).add_Hm().format(model.updatedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(uri),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(context.l10n.t('lpOpenModel')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('lpDeleteQuestion')),
        content: Text(model.title),
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
    if (confirmed == true) {
      await ref.read(savedLinearProgramsProvider.notifier).delete(model.id);
    }
  }
}

class _SavedMatricesTab extends ConsumerWidget {
  const _SavedMatricesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operations = ref.watch(savedMatricesProvider);
    return operations.isEmpty
        ? EmptyState(
            icon: Icons.grid_on_rounded,
            title: context.l10n.t('matrixNoSaved'),
            body: context.l10n.t('matrixNoSavedBody'),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: operations.length,
            itemBuilder: (context, index) => _SavedMatrixCard(
              operation: operations[index],
              onDelete: () => _deleteMatrix(context, ref, operations[index]),
            ),
          );
  }

  Future<void> _deleteMatrix(
    BuildContext context,
    WidgetRef ref,
    SavedMatrixOperation operation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('matrixDeleteQuestion')),
        content: Text(operation.title),
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
    if (confirmed == true) {
      await ref.read(savedMatricesProvider.notifier).delete(operation.id);
    }
  }
}

class _SavedMatrixCard extends StatelessWidget {
  const _SavedMatrixCard({required this.operation, required this.onDelete});

  final SavedMatrixOperation operation;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final inputSizes = operation.inputs
        .map((matrix) => '${matrix.rows}\u00d7${matrix.columns}')
        .join(' \u00b7 ');
    final resultSize = switch (operation.result) {
      MatrixResultValue(:final value) =>
        ' \u2192 ${value.rows}\u00d7${value.columns}',
      ScalarMatrixResult() => '',
      LinearSystemMatrixResult() => '',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => context.push(
          '/matrix?savedId=${Uri.encodeQueryComponent(operation.id)}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.grid_on_rounded),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          operation.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          context.l10n.t(operation.type.localizationKey),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.t('matrixCopyResult'),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: _savedMatrixResultText(operation)),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l10n.t('copied'))),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                  ),
                  IconButton(
                    tooltip: context.l10n.t('delete'),
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${operation.type.notation}  $inputSizes$resultSize',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _savedMatrixResultSummary(context, operation),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat.yMMMd(
                        Localizations.localeOf(context).toLanguageTag(),
                      ).add_Hm().format(operation.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(
                      '/matrix?savedId=${Uri.encodeQueryComponent(operation.id)}',
                    ),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(context.l10n.t('open')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _savedMatrixResultText(SavedMatrixOperation operation) =>
    switch (operation.result) {
      MatrixResultValue(:final value) => matrixToPlainText(value),
      ScalarMatrixResult(:final value) =>
        '${operation.type.notation} = ${formatMatrixNumber(value)}',
      LinearSystemMatrixResult(:final value) => matrixToPlainText(
        value.reducedMatrix,
      ),
    };

String _savedMatrixResultSummary(
  BuildContext context,
  SavedMatrixOperation operation,
) => switch (operation.result) {
  MatrixResultValue(:final value) => matrixToBracketText(value),
  ScalarMatrixResult(:final value) =>
    '${operation.type.notation} = ${formatMatrixNumber(value)}',
  LinearSystemMatrixResult(:final value) => switch (value) {
    UniqueSolution() => context.l10n.t('matrixUniqueSolution'),
    InfiniteSolutions() => context.l10n.t('matrixInfiniteSolutions'),
    NoSolution() => context.l10n.t('matrixNoSolution'),
  },
};

class _SavedCalculationsTab extends ConsumerWidget {
  const _SavedCalculationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(savedProvider);
    return items.isEmpty
        ? EmptyState(
            icon: Icons.bookmark_border_rounded,
            title: context.l10n.t('noSaved'),
            body: context.l10n.t('noSavedBody'),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: items.length,
            itemBuilder: (context, index) => _SavedCard(item: items[index]),
          );
  }
}

class _SavedGraphsTab extends ConsumerWidget {
  const _SavedGraphsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graphs = ref.watch(savedGraphsProvider);
    return graphs.isEmpty
        ? EmptyState(
            icon: Icons.show_chart_rounded,
            title: context.l10n.t('graphNoSaved'),
            body: context.l10n.t('graphNoSavedBody'),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: graphs.length,
            itemBuilder: (context, index) => _SavedGraphCard(
              graph: graphs[index],
              onDelete: () => _deleteGraph(context, ref, graphs[index]),
            ),
          );
  }

  Future<void> _deleteGraph(
    BuildContext context,
    WidgetRef ref,
    SavedGraph graph,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('graphDeleteQuestion')),
        content: Text(graph.title),
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
    if (confirmed == true) {
      await ref.read(savedGraphsProvider.notifier).delete(graph.id);
    }
  }
}

class _SavedGraphCard extends StatelessWidget {
  const _SavedGraphCard({required this.graph, required this.onDelete});

  final SavedGraph graph;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final expressions = graph.functions
        .map((item) => item.expression.trim())
        .where((item) => item.isNotEmpty)
        .join(' | ');
    final graphUri = '/graph?graphId=${Uri.encodeQueryComponent(graph.id)}';
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(graphUri),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.show_chart_rounded),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          graph.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${graph.functions.length} '
                          '${context.l10n.t('graphFunctions').toLowerCase()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.t('edit'),
                    onPressed: () => context.push(graphUri),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: context.l10n.t('graphShare'),
                    onPressed: () => context.push('$graphUri&share=1'),
                    icon: const Icon(Icons.ios_share_rounded),
                  ),
                  IconButton(
                    tooltip: context.l10n.t('delete'),
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              if (expressions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(expressions, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${context.l10n.t('graphRange')}: '
                '${_number(graph.range.min)} ... ${_number(graph.range.max)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat.yMMMd(locale).add_Hm().format(graph.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(graphUri),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(context.l10n.t('open')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsPrecision(4);
}

class _SavedCard extends ConsumerWidget {
  const _SavedCard({required this.item});
  final SavedCalculation item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.t('edit'),
                  onPressed: () => _edit(context, ref),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: context.l10n.t('delete'),
                  onPressed: () =>
                      ref.read(savedProvider.notifier).remove(item.id),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            Text(item.expression),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '= ${item.result}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (item.note?.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(item.note!),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat.yMMMd(
                      Localizations.localeOf(context).toLanguageTag(),
                    ).add_Hm().format(item.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push(
                    '/calculator?expression='
                    '${Uri.encodeQueryComponent(item.expression)}',
                  ),
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(context.l10n.t('reuse')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController(text: item.title);
    final note = TextEditingController(text: item.note);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('editSaved')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: InputDecoration(labelText: context.l10n.t('title')),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: note,
              decoration: InputDecoration(labelText: context.l10n.t('note')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.t('save')),
          ),
        ],
      ),
    );
    if (confirmed == true && title.text.trim().isNotEmpty) {
      await ref
          .read(savedProvider.notifier)
          .update(item.id, title.text, note.text);
    }
    title.dispose();
    note.dispose();
  }
}

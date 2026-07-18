import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/graph/presentation/graph_controller.dart';
import 'package:calcademy/features/graph/presentation/graph_palette.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GraphFunctionList extends ConsumerWidget {
  const GraphFunctionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idKey = ref.watch(
      graphProvider.select(
        (state) => state.functions.map((item) => item.id).join('|'),
      ),
    );
    final ids = idKey.isEmpty ? const <String>[] : idKey.split('|');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.t('graphFunctions'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text('${ids.length}/${GraphController.maxFunctions}'),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final id in ids) ...[
          GraphFunctionCard(functionId: id),
          const SizedBox(height: AppSpacing.sm),
        ],
        OutlinedButton.icon(
          key: const Key('addGraphFunction'),
          onPressed: ids.length >= GraphController.maxFunctions
              ? null
              : () => ref.read(graphProvider.notifier).addFunction(),
          icon: const Icon(Icons.add_rounded),
          label: Text(context.l10n.t('graphAddFunction')),
        ),
      ],
    );
  }
}

class GraphFunctionCard extends ConsumerStatefulWidget {
  const GraphFunctionCard({required this.functionId, super.key});

  final String functionId;

  @override
  ConsumerState<GraphFunctionCard> createState() => _GraphFunctionCardState();
}

class _GraphFunctionCardState extends ConsumerState<GraphFunctionCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final function = ref.watch(
      graphProvider.select(
        (state) => state.functions
            .where((item) => item.id == widget.functionId)
            .firstOrNull,
      ),
    );
    final errorKey = ref.watch(
      graphProvider.select((state) => state.functionErrors[widget.functionId]),
    );
    final isSampling = ref.watch(
      graphProvider.select(
        (state) => state.samplingIds.contains(widget.functionId),
      ),
    );
    if (function == null) return const SizedBox.shrink();
    if (_controller.text != function.expression) {
      _controller.value = TextEditingValue(
        text: function.expression,
        selection: TextSelection.collapsed(offset: function.expression.length),
      );
    }
    final label = 'f${_subscript(function.visualIndex + 1)}';
    final color = GraphPalette.colorFor(context, function.visualIndex);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(dimension: 12),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                if (isSampling) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
                const Spacer(),
                IconButton(
                  tooltip: context.l10n.t(
                    function.isVisible
                        ? 'graphHideFunction'
                        : 'graphShowFunction',
                  ),
                  onPressed: () => ref
                      .read(graphProvider.notifier)
                      .toggleVisibility(function.id),
                  icon: Icon(
                    function.isVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.t('graphDeleteFunction'),
                  onPressed: () => ref
                      .read(graphProvider.notifier)
                      .removeFunction(function.id),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              key: Key('graphExpression-${function.id}'),
              controller: _controller,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: context.l10n.t('graphFunctionExpression'),
                hintText: context.l10n.t('graphFunctionHint'),
                prefixText: '$label(x) = ',
                errorText: errorKey == null ? null : context.l10n.t(errorKey),
              ),
              onChanged: (value) => ref
                  .read(graphProvider.notifier)
                  .updateExpression(function.id, value),
            ),
          ],
        ),
      ),
    );
  }

  String _subscript(int value) => const ['₁', '₂', '₃', '₄', '₅'][value - 1];
}

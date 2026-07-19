import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/calculus/domain/calculus_limits.dart';
import 'package:calcademy/features/calculus/domain/calculus_result.dart';
import 'package:calcademy/features/calculus/presentation/calculus_controller.dart';
import 'package:calcademy/features/calculus/presentation/calculus_graph_view.dart';
import 'package:calcademy/features/calculus/presentation/calculus_result_card.dart';
import 'package:calcademy/features/graph/domain/graph_expression.dart';
import 'package:calcademy/features/graph/domain/graph_range.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart'
    show parseLpNumber;
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Numerical integration workflow: inputs, method selector, result card,
/// and the function curve with the integrated interval shaded.
class IntegrationTab extends ConsumerStatefulWidget {
  const IntegrationTab({super.key});

  @override
  ConsumerState<IntegrationTab> createState() => _IntegrationTabState();
}

class _IntegrationTabState extends ConsumerState<IntegrationTab> {
  final _function = TextEditingController();
  final _lower = TextEditingController(text: '0');
  final _upper = TextEditingController(text: '1');
  final _subintervals = TextEditingController(
    text: '${CalculusLimits.defaultSubintervals}',
  );
  var _method = IntegrationMethod.simpson13;
  String? _inputError;

  GraphEvaluator? _graphEvaluator;
  IntegralOverlay? _integral;
  GraphRange? _graphRange;

  @override
  void dispose() {
    _function.dispose();
    _lower.dispose();
    _upper.dispose();
    _subintervals.dispose();
    super.dispose();
  }

  Future<void> _solve() async {
    final l10n = context.l10n;
    final double lower;
    final double upper;
    final int subintervals;
    try {
      lower = parseLpNumber(_lower.text);
      upper = parseLpNumber(_upper.text);
      subintervals = int.parse(_subintervals.text.trim());
    } on Object {
      setState(() => _inputError = l10n.t('eqErrorInvalidNumber'));
      return;
    }
    setState(() => _inputError = null);
    final function = _function.text;
    final method = _method;
    await ref.read(calculusWorkspaceProvider.notifier).run(() {
      final result = ref
          .read(integrationServiceProvider)
          .integrate(
            function: function,
            lowerBound: lower,
            upperBound: upper,
            method: method,
            subintervals: subintervals,
          );
      _prepareGraph(function, result);
      return result;
    });
  }

  void _prepareGraph(String function, CalculusResult result) {
    _graphEvaluator = null;
    _integral = null;
    _graphRange = null;
    if (result is! IntegrationSuccess) return;
    try {
      _graphEvaluator = const GraphExpressionCompiler().compile(function);
      _integral = IntegralOverlay(
        lower: result.lowerBound,
        upper: result.upperBound,
      );
      final padding = (result.upperBound - result.lowerBound) * 0.25;
      _graphRange = GraphRange(
        min: result.lowerBound - padding,
        max: result.upperBound + padding,
      );
    } on GraphExpressionException {
      // Parse failure already surfaced by the service.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(calculusWorkspaceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('calc-int-function'),
          controller: _function,
          decoration: InputDecoration(
            labelText: l10n.t('eqFunctionLabel'),
            hintText: 'x^2',
            errorText: _inputError,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<IntegrationMethod>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: IntegrationMethod.trapezoidal,
                label: Text(l10n.t('calcMethodTrapezoidal')),
              ),
              ButtonSegment(
                value: IntegrationMethod.simpson13,
                label: Text(l10n.t('calcMethodSimpson')),
              ),
            ],
            selected: {_method},
            onSelectionChanged: (selection) =>
                setState(() => _method = selection.first),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('calc-int-lower'),
                controller: _lower,
                decoration: InputDecoration(
                  labelText: l10n.t('eqLowerBound'),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                key: const Key('calc-int-upper'),
                controller: _upper,
                decoration: InputDecoration(
                  labelText: l10n.t('eqUpperBound'),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                key: const Key('calc-int-n'),
                controller: _subintervals,
                decoration: InputDecoration(
                  labelText: l10n.t('calcSubintervals'),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('calc-int-solve'),
                onPressed: state.loading ? null : _solve,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.t('eqSolve')),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton(
              onPressed: () {
                _function.clear();
                setState(() {
                  _inputError = null;
                  _graphEvaluator = null;
                  _integral = null;
                });
                ref.read(calculusWorkspaceProvider.notifier).clear();
              },
              child: Text(l10n.t('eqClear')),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.loading)
          const Center(child: CircularProgressIndicator())
        else ...[
          CalculusResultCard(result: state.result),
          if (state.result is IntegrationSuccess &&
              _graphEvaluator != null &&
              _graphRange != null)
            CalculusGraphView(
              key: const Key('calc-int-graph'),
              evaluator: _graphEvaluator!,
              range: _graphRange!,
              integral: _integral,
            ),
        ],
      ],
    );
  }
}

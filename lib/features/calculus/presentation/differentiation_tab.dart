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

/// Numerical differentiation workflow: inputs, method selector, result
/// card, and the function curve with the tangent line built from the
/// computed derivative. All math lives in the application service; this
/// tab only gathers input, and compiles the expression once per solve for
/// the graph overlay.
class DifferentiationTab extends ConsumerStatefulWidget {
  const DifferentiationTab({super.key});

  @override
  ConsumerState<DifferentiationTab> createState() => _DifferentiationTabState();
}

class _DifferentiationTabState extends ConsumerState<DifferentiationTab> {
  final _function = TextEditingController();
  final _point = TextEditingController(text: '1');
  final _step = TextEditingController(
    text: '${CalculusLimits.defaultStepSize}',
  );
  var _method = DifferentiationMethod.central;
  String? _inputError;

  GraphEvaluator? _graphEvaluator;
  TangentOverlay? _tangent;
  GraphRange? _graphRange;

  @override
  void dispose() {
    _function.dispose();
    _point.dispose();
    _step.dispose();
    super.dispose();
  }

  Future<void> _solve() async {
    final l10n = context.l10n;
    final double point;
    final double step;
    try {
      point = parseLpNumber(_point.text);
      step = double.parse(_step.text.trim());
    } on Object {
      setState(() => _inputError = l10n.t('eqErrorInvalidNumber'));
      return;
    }
    setState(() => _inputError = null);
    final function = _function.text;
    final method = _method;
    await ref.read(calculusWorkspaceProvider.notifier).run(() {
      final result = ref
          .read(differentiationServiceProvider)
          .differentiate(
            function: function,
            point: point,
            method: method,
            stepSize: step,
          );
      _prepareGraph(function, result);
      return result;
    });
  }

  /// Builds the tangent overlay from the *computed* derivative; the
  /// expression is compiled once here and reused by the graph view.
  void _prepareGraph(String function, CalculusResult result) {
    _graphEvaluator = null;
    _tangent = null;
    _graphRange = null;
    if (result is! DifferentiationSuccess) return;
    try {
      final evaluator = const GraphExpressionCompiler().compile(function);
      final valueAtPoint = evaluator.evaluate(result.point);
      if (!valueAtPoint.isFinite) return;
      _graphEvaluator = evaluator;
      _tangent = TangentOverlay(
        point: result.point,
        valueAtPoint: valueAtPoint,
        slope: result.value,
      );
      _graphRange = GraphRange(min: result.point - 5, max: result.point + 5);
    } on GraphExpressionException {
      // The service already surfaced a parse failure; no graph to draw.
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
          key: const Key('calc-diff-function'),
          controller: _function,
          decoration: InputDecoration(
            labelText: l10n.t('eqFunctionLabel'),
            hintText: 'sin(x)',
            errorText: _inputError,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.t('eqSyntaxHelp'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<DifferentiationMethod>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: DifferentiationMethod.forward,
                label: Text(l10n.t('calcMethodForward')),
              ),
              ButtonSegment(
                value: DifferentiationMethod.central,
                label: Text(l10n.t('calcMethodCentral')),
              ),
              ButtonSegment(
                value: DifferentiationMethod.backward,
                label: Text(l10n.t('calcMethodBackward')),
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
                key: const Key('calc-diff-point'),
                controller: _point,
                decoration: InputDecoration(
                  labelText: l10n.t('calcEvaluationPoint'),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                key: const Key('calc-diff-step'),
                controller: _step,
                decoration: InputDecoration(
                  labelText: l10n.t('calcStepSize'),
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
                key: const Key('calc-diff-solve'),
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
                  _tangent = null;
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
          if (state.result is DifferentiationSuccess &&
              _graphEvaluator != null &&
              _graphRange != null)
            CalculusGraphView(
              key: const Key('calc-diff-graph'),
              evaluator: _graphEvaluator!,
              range: _graphRange!,
              tangent: _tangent,
            ),
        ],
      ],
    );
  }
}

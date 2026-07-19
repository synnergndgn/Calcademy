import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/calculus/domain/calculus_limits.dart';
import 'package:calcademy/features/calculus/presentation/calculus_controller.dart';
import 'package:calcademy/features/calculus/presentation/calculus_result_card.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart'
    show parseLpNumber;
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Function analysis workflow: function + editable analysis range, with
/// all outputs explicitly labelled approximate and interval-bound.
class AnalysisTab extends ConsumerStatefulWidget {
  const AnalysisTab({super.key});

  @override
  ConsumerState<AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends ConsumerState<AnalysisTab> {
  final _function = TextEditingController();
  final _rangeMin = TextEditingController(
    text: '${CalculusLimits.defaultAnalysisMin.toInt()}',
  );
  final _rangeMax = TextEditingController(
    text: '${CalculusLimits.defaultAnalysisMax.toInt()}',
  );
  String? _inputError;

  @override
  void dispose() {
    _function.dispose();
    _rangeMin.dispose();
    _rangeMax.dispose();
    super.dispose();
  }

  Future<void> _solve() async {
    final l10n = context.l10n;
    final double min;
    final double max;
    try {
      min = parseLpNumber(_rangeMin.text);
      max = parseLpNumber(_rangeMax.text);
    } on Object {
      setState(() => _inputError = l10n.t('eqErrorInvalidNumber'));
      return;
    }
    setState(() => _inputError = null);
    final function = _function.text;
    await ref
        .read(calculusWorkspaceProvider.notifier)
        .run(
          () => ref
              .read(functionAnalysisServiceProvider)
              .analyze(function: function, rangeMin: min, rangeMax: max),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(calculusWorkspaceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('calc-analysis-function'),
          controller: _function,
          decoration: InputDecoration(
            labelText: l10n.t('eqFunctionLabel'),
            hintText: 'x^3 - 3x',
            errorText: _inputError,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.t('calcAnalysisHint'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('calc-analysis-min'),
                controller: _rangeMin,
                decoration: InputDecoration(
                  labelText: l10n.t('eqScanMin'),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                key: const Key('calc-analysis-max'),
                controller: _rangeMax,
                decoration: InputDecoration(
                  labelText: l10n.t('eqScanMax'),
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
                key: const Key('calc-analysis-solve'),
                onPressed: state.loading ? null : _solve,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.t('calcAnalyze')),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton(
              onPressed: () {
                _function.clear();
                setState(() => _inputError = null);
                ref.read(calculusWorkspaceProvider.notifier).clear();
              },
              child: Text(l10n.t('eqClear')),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.loading)
          const Center(child: CircularProgressIndicator())
        else
          CalculusResultCard(result: state.result),
      ],
    );
  }
}

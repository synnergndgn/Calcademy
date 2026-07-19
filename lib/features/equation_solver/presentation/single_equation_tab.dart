import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/equation_solver/domain/equation_solver_limits.dart';
import 'package:calcademy/features/equation_solver/presentation/equation_result_card.dart';
import 'package:calcademy/features/equation_solver/presentation/equation_solver_controller.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart'
    show parseLpNumber;
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The "single equation" workflow: equation input, optional scan interval,
/// solve/clear, and the typed result card. No math lives here - the tab
/// only gathers input and renders results.
class SingleEquationTab extends ConsumerStatefulWidget {
  const SingleEquationTab({super.key});

  @override
  ConsumerState<SingleEquationTab> createState() => _SingleEquationTabState();
}

class _SingleEquationTabState extends ConsumerState<SingleEquationTab> {
  final _equation = TextEditingController();
  final _scanMin = TextEditingController(
    text: '${EquationSolverLimits.defaultScanMin.toInt()}',
  );
  final _scanMax = TextEditingController(
    text: '${EquationSolverLimits.defaultScanMax.toInt()}',
  );
  String? _inputError;

  @override
  void dispose() {
    _equation.dispose();
    _scanMin.dispose();
    _scanMax.dispose();
    super.dispose();
  }

  void _solve() {
    final l10n = context.l10n;
    double min;
    double max;
    try {
      min = parseLpNumber(_scanMin.text);
      max = parseLpNumber(_scanMax.text);
    } on Object {
      setState(() => _inputError = l10n.t('eqErrorInvalidInterval'));
      return;
    }
    setState(() => _inputError = null);
    ref
        .read(equationWorkspaceProvider.notifier)
        .solveSingle(_equation.text, scanMin: min, scanMax: max);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(equationWorkspaceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('eq-single-input'),
          controller: _equation,
          decoration: InputDecoration(
            labelText: l10n.t('eqEquationLabel'),
            hintText: '2x + 5 = 17',
            errorText: _inputError,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.t('eqSyntaxHelp'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(
            l10n.t('eqScanInterval'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          subtitle: Text(
            l10n.t('eqScanIntervalHint'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('eq-scan-min'),
                    controller: _scanMin,
                    decoration: InputDecoration(
                      labelText: l10n.t('eqScanMin'),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    key: const Key('eq-scan-max'),
                    controller: _scanMax,
                    decoration: InputDecoration(
                      labelText: l10n.t('eqScanMax'),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('eq-single-solve'),
                onPressed: state.loading ? null : _solve,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.t('eqSolve')),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton(
              onPressed: () {
                _equation.clear();
                setState(() => _inputError = null);
                ref.read(equationWorkspaceProvider.notifier).clear();
              },
              child: Text(l10n.t('eqClear')),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.loading)
          const Center(child: CircularProgressIndicator())
        else
          EquationResultCard(single: state.singleResult),
      ],
    );
  }
}

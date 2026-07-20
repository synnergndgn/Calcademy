import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/equation_solver/domain/equation_solver_limits.dart';
import 'package:calcademy/features/equation_solver/presentation/equation_result_card.dart';
import 'package:calcademy/features/equation_solver/presentation/equation_solver_controller.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/equation_solver_saved_adapter.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart'
    show parseLpNumber;
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The n×n linear-system workflow in matrix mode: a size selector, a
/// horizontally scrollable coefficient grid with an RHS column, and the
/// solve/clear actions. Cell state lives in local controllers (the same
/// pattern the matrix and optimization editors use).
class LinearSystemTab extends ConsumerStatefulWidget {
  const LinearSystemTab({super.key});

  @override
  ConsumerState<LinearSystemTab> createState() => _LinearSystemTabState();
}

class _LinearSystemTabState extends ConsumerState<LinearSystemTab> {
  var _size = 2;
  final _cells = <List<TextEditingController>>[];
  final _rhs = <TextEditingController>[];
  String? _inputError;
  int _solvedDimension = 0;

  @override
  void initState() {
    super.initState();
    _resize(_size);
  }

  void _resize(int size) {
    while (_cells.length < size) {
      _cells.add([
        for (var column = 0; column < size; column++)
          TextEditingController(text: '0'),
      ]);
      _rhs.add(TextEditingController(text: '0'));
    }
    while (_cells.length > size) {
      for (final controller in _cells.removeLast()) {
        controller.dispose();
      }
      _rhs.removeLast().dispose();
    }
    for (final row in _cells) {
      while (row.length < size) {
        row.add(TextEditingController(text: '0'));
      }
      while (row.length > size) {
        row.removeLast().dispose();
      }
    }
    _size = size;
  }

  @override
  void dispose() {
    for (final row in _cells) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    for (final controller in _rhs) {
      controller.dispose();
    }
    super.dispose();
  }

  void _solve() {
    final l10n = context.l10n;
    final coefficients = <List<double>>[];
    final rhs = <double>[];
    try {
      for (var row = 0; row < _size; row++) {
        coefficients.add([
          for (var column = 0; column < _size; column++)
            parseLpNumber(_cells[row][column].text),
        ]);
        rhs.add(parseLpNumber(_rhs[row].text));
      }
    } on Object {
      setState(() => _inputError = l10n.t('eqErrorInvalidNumber'));
      return;
    }
    setState(() {
      _inputError = null;
      _solvedDimension = _size;
    });
    ref.read(equationWorkspaceProvider.notifier).solveSystem(coefficients, rhs);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(equationWorkspaceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('${l10n.t('eqSystemSize')}: $_size × $_size')),
            IconButton(
              tooltip: l10n.t('eqDecreaseSize'),
              onPressed: _size <= EquationSolverLimits.minSystemSize
                  ? null
                  : () => setState(() => _resize(_size - 1)),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            IconButton(
              key: const Key('eq-system-grow'),
              tooltip: l10n.t('eqIncreaseSize'),
              onPressed: _size >= EquationSolverLimits.maxSystemSize
                  ? null
                  : () => setState(() => _resize(_size + 1)),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        if (_inputError != null)
          Text(
            _inputError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var row = 0; row < _size; row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      for (var column = 0; column < _size; column++) ...[
                        SizedBox(
                          width: 72,
                          child: TextField(
                            key: Key('eq-cell-$row-$column'),
                            controller: _cells[row][column],
                            textAlign: TextAlign.end,
                            decoration: InputDecoration(
                              labelText: 'a${row + 1}${column + 1}',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                      ],
                      const SizedBox(width: AppSpacing.xs),
                      Text('=', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(width: AppSpacing.xs),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          key: Key('eq-rhs-$row'),
                          controller: _rhs[row],
                          textAlign: TextAlign.end,
                          decoration: InputDecoration(
                            labelText: 'b${row + 1}',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('eq-system-solve'),
                onPressed: state.loading ? null : _solve,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.t('eqSolve')),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton(
              onPressed: () {
                for (final row in _cells) {
                  for (final controller in row) {
                    controller.text = '0';
                  }
                }
                for (final controller in _rhs) {
                  controller.text = '0';
                }
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
          EquationResultCard(
            system: state.systemResult,
            savedDraft: EquationSolverSavedAdapter.tryLinearSystem(
              dimension: _solvedDimension,
              result: state.systemResult,
            ),
          ),
      ],
    );
  }
}

import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/equation_solver/domain/equation_solver_limits.dart';
import 'package:calcademy/features/equation_solver/presentation/equation_result_card.dart';
import 'package:calcademy/features/equation_solver/presentation/equation_solver_controller.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/equation_solver_saved_adapter.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart'
    show parseLpNumber;
import 'package:calcademy/features/matrix/domain/matrix_number_formatter.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Method { bisection, newton, secant }

/// The advanced numerical-methods workflow. The parameter fields change
/// with the selected method - only the inputs that method actually uses
/// are shown (bounds for bisection, one guess for Newton, two for secant).
class NumericalMethodsTab extends ConsumerStatefulWidget {
  const NumericalMethodsTab({super.key, this.restore});

  /// Inputs rebuilt from a saved record; when present they seed the form
  /// (still fully editable) and the method is re-run automatically.
  final EquationSolverRestore? restore;

  @override
  ConsumerState<NumericalMethodsTab> createState() =>
      _NumericalMethodsTabState();
}

class _NumericalMethodsTabState extends ConsumerState<NumericalMethodsTab> {
  var _method = _Method.bisection;
  final _function = TextEditingController();
  final _first = TextEditingController(text: '0');
  final _second = TextEditingController(text: '1');
  final _tolerance = TextEditingController(text: '1e-9');
  final _maxIterations = TextEditingController(
    text: '${EquationSolverLimits.defaultMaxIterations}',
  );
  String? _inputError;
  String _solvedFunction = '';
  List<double> _solvedInitialValues = const [];
  double? _solvedTolerance;
  int? _solvedMaxIterations;

  @override
  void initState() {
    super.initState();
    final restore = widget.restore;
    if (restore != null &&
        restore.mode == EquationSolverRestoreMode.numerical) {
      _function.text = restore.function ?? '';
      _method = switch (restore.method) {
        'newtonRaphson' => _Method.newton,
        'secant' => _Method.secant,
        _ => _Method.bisection,
      };
      if (restore.initialValues.isNotEmpty) {
        _first.text = formatMatrixNumber(restore.initialValues.first);
      }
      if (restore.initialValues.length > 1) {
        _second.text = formatMatrixNumber(restore.initialValues[1]);
      }
      if (restore.tolerance != null) {
        _tolerance.text = '${restore.tolerance}';
      }
      if (restore.maxIterations != null) {
        _maxIterations.text = '${restore.maxIterations}';
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _run();
      });
    }
  }

  @override
  void dispose() {
    _function.dispose();
    _first.dispose();
    _second.dispose();
    _tolerance.dispose();
    _maxIterations.dispose();
    super.dispose();
  }

  void _run() {
    final l10n = context.l10n;
    final double first;
    final double second;
    final double tolerance;
    final int maxIterations;
    try {
      first = parseLpNumber(_first.text);
      second = _method == _Method.newton ? 0 : parseLpNumber(_second.text);
      tolerance = double.parse(_tolerance.text.trim());
      maxIterations = int.parse(_maxIterations.text.trim());
    } on Object {
      setState(() => _inputError = l10n.t('eqErrorInvalidNumber'));
      return;
    }
    final function = _function.text;
    setState(() {
      _inputError = null;
      _solvedFunction = function;
      _solvedInitialValues = _method == _Method.newton
          ? [first]
          : [first, second];
      _solvedTolerance = tolerance;
      _solvedMaxIterations = maxIterations;
    });
    ref
        .read(equationWorkspaceProvider.notifier)
        .runMethod(
          (service) => switch (_method) {
            _Method.bisection => service.bisection(
              function: function,
              lower: first,
              upper: second,
              tolerance: tolerance,
              maxIterations: maxIterations,
            ),
            _Method.newton => service.newtonRaphson(
              function: function,
              initialGuess: first,
              tolerance: tolerance,
              maxIterations: maxIterations,
            ),
            _Method.secant => service.secant(
              function: function,
              firstGuess: first,
              secondGuess: second,
              tolerance: tolerance,
              maxIterations: maxIterations,
            ),
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(equationWorkspaceProvider);
    final firstLabel = switch (_method) {
      _Method.bisection => l10n.t('eqLowerBound'),
      _Method.newton => l10n.t('eqInitialGuess'),
      _Method.secant => l10n.t('eqFirstGuess'),
    };
    final secondLabel = switch (_method) {
      _Method.bisection => l10n.t('eqUpperBound'),
      _Method.newton => null,
      _Method.secant => l10n.t('eqSecondGuess'),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<_Method>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _Method.bisection, label: Text('Bisection')),
              ButtonSegment(
                value: _Method.newton,
                label: Text('Newton-Raphson'),
              ),
              ButtonSegment(value: _Method.secant, label: Text('Secant')),
            ],
            selected: {_method},
            onSelectionChanged: (selection) =>
                setState(() => _method = selection.first),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const Key('eq-method-function'),
          controller: _function,
          decoration: InputDecoration(
            labelText: l10n.t('eqFunctionLabel'),
            hintText: 'x^3 - x - 2',
            errorText: _inputError,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('eq-method-first'),
                controller: _first,
                decoration: InputDecoration(
                  labelText: firstLabel,
                  isDense: true,
                ),
              ),
            ),
            if (secondLabel != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  key: const Key('eq-method-second'),
                  controller: _second,
                  decoration: InputDecoration(
                    labelText: secondLabel,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tolerance,
                decoration: InputDecoration(
                  labelText: l10n.t('eqTolerance'),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _maxIterations,
                decoration: InputDecoration(
                  labelText: l10n.t('eqMaxIterations'),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          key: const Key('eq-method-run'),
          onPressed: state.loading ? null : _run,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(l10n.t('eqSolve')),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.loading)
          const Center(child: CircularProgressIndicator())
        else
          EquationResultCard(
            numeric: state.methodResult,
            savedDraft: EquationSolverSavedAdapter.tryNumerical(
              function: _solvedFunction,
              result: state.methodResult,
              initialValues: _solvedInitialValues,
              tolerance: _solvedTolerance,
              maxIterations: _solvedMaxIterations,
            ),
          ),
      ],
    );
  }
}

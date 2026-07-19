import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/equation_solver/presentation/equation_solver_controller.dart';
import 'package:calcademy/features/equation_solver/presentation/linear_system_tab.dart';
import 'package:calcademy/features/equation_solver/presentation/numerical_methods_tab.dart';
import 'package:calcademy/features/equation_solver/presentation/single_equation_tab.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Mode { single, system, methods }

/// The `/equation-solver` route: three clearly separated workflows
/// (single equation, linear system, numerical methods) behind a segmented
/// selector, inside the same 840px-bounded centred column the other
/// Calcademy workspaces use.
class EquationSolverPage extends ConsumerStatefulWidget {
  const EquationSolverPage({super.key});

  @override
  ConsumerState<EquationSolverPage> createState() => _EquationSolverPageState();
}

class _EquationSolverPageState extends ConsumerState<EquationSolverPage> {
  var _mode = _Mode.single;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('equations'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                l10n.t('eqWelcome'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.t('eqWelcomeBody')),
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<_Mode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: _Mode.single,
                      label: Text(l10n.t('eqModeSingle')),
                    ),
                    ButtonSegment(
                      value: _Mode.system,
                      label: Text(l10n.t('eqModeSystem')),
                    ),
                    ButtonSegment(
                      value: _Mode.methods,
                      label: Text(l10n.t('eqModeMethods')),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) => setState(() {
                    _mode = selection.first;
                    ref.read(equationWorkspaceProvider.notifier).clear();
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: switch (_mode) {
                    _Mode.single => const SingleEquationTab(),
                    _Mode.system => const LinearSystemTab(),
                    _Mode.methods => const NumericalMethodsTab(),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

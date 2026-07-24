import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/calculus/presentation/analysis_tab.dart';
import 'package:calcademy/features/calculus/presentation/calculus_controller.dart';
import 'package:calcademy/features/calculus/presentation/differentiation_tab.dart';
import 'package:calcademy/features/calculus/presentation/integration_tab.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/calculus_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/presentation/saved_calculations_controller.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Mode { differentiation, integration, analysis }

/// The `/calculus` route: three numerical-analysis workflows behind the
/// same segmented selector and 840px-bounded centred column the other
/// Calcademy workspaces use. When opened with a [savedCalculationId], the
/// matching saved record's inputs are restored into the right workflow;
/// an unknown or non-restorable id silently falls back to a fresh page.
class CalculusPage extends ConsumerStatefulWidget {
  const CalculusPage({super.key, this.savedCalculationId});

  final String? savedCalculationId;

  @override
  ConsumerState<CalculusPage> createState() => _CalculusPageState();
}

class _CalculusPageState extends ConsumerState<CalculusPage> {
  var _mode = _Mode.differentiation;
  CalculusRestore? _restore;

  @override
  void initState() {
    super.initState();
    final id = widget.savedCalculationId;
    if (id == null) return;
    for (final item in ref.read(savedCalculationsProvider).items) {
      if (item.id != id) continue;
      final restore = CalculusSavedAdapter.tryRestore(item);
      if (restore != null) {
        _restore = restore;
        _mode = switch (restore.mode) {
          CalculusRestoreMode.differentiation => _Mode.differentiation,
          CalculusRestoreMode.integration => _Mode.integration,
          CalculusRestoreMode.analysis => _Mode.analysis,
        };
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('calculus'))),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: ListView(
              key: const Key('calculus-scroll-view'),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.lg + bottomInset,
              ),
              children: [
                Text(
                  l10n.t('calcWelcome'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.t('calcWelcomeBody')),
                const SizedBox(height: AppSpacing.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<_Mode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: _Mode.differentiation,
                        label: Text(l10n.t('calcModeDifferentiation')),
                      ),
                      ButtonSegment(
                        value: _Mode.integration,
                        label: Text(l10n.t('calcModeIntegration')),
                      ),
                      ButtonSegment(
                        value: _Mode.analysis,
                        label: Text(l10n.t('calcModeAnalysis')),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (selection) => setState(() {
                      _mode = selection.first;
                      ref.read(calculusWorkspaceProvider.notifier).clear();
                    }),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: switch (_mode) {
                      _Mode.differentiation => DifferentiationTab(
                        restore: _restore,
                      ),
                      _Mode.integration => IntegrationTab(restore: _restore),
                      _Mode.analysis => AnalysisTab(restore: _restore),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

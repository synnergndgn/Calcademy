import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/calculus/presentation/analysis_tab.dart';
import 'package:calcademy/features/calculus/presentation/calculus_controller.dart';
import 'package:calcademy/features/calculus/presentation/differentiation_tab.dart';
import 'package:calcademy/features/calculus/presentation/integration_tab.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Mode { differentiation, integration, analysis }

/// The `/calculus` route: three numerical-analysis workflows behind the
/// same segmented selector and 840px-bounded centred column the other
/// Calcademy workspaces use.
class CalculusPage extends ConsumerStatefulWidget {
  const CalculusPage({super.key});

  @override
  ConsumerState<CalculusPage> createState() => _CalculusPageState();
}

class _CalculusPageState extends ConsumerState<CalculusPage> {
  var _mode = _Mode.differentiation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('calculus'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
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
                    _Mode.differentiation => const DifferentiationTab(),
                    _Mode.integration => const IntegrationTab(),
                    _Mode.analysis => const AnalysisTab(),
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

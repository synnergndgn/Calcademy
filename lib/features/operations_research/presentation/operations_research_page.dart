import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/operations_research/presentation/assignment_tab.dart';
import 'package:calcademy/features/operations_research/presentation/cpm_pert_tab.dart';
import 'package:calcademy/features/operations_research/presentation/goal_programming_tab.dart';
import 'package:calcademy/features/operations_research/presentation/operations_research_controller.dart';
import 'package:calcademy/features/operations_research/presentation/transportation_tab.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _OperationsResearchMode {
  transportation,
  assignment,
  goalProgramming,
  cpmPert,
}

class OperationsResearchPage extends ConsumerStatefulWidget {
  const OperationsResearchPage({super.key});

  @override
  ConsumerState<OperationsResearchPage> createState() =>
      _OperationsResearchPageState();
}

class _OperationsResearchPageState
    extends ConsumerState<OperationsResearchPage> {
  var _mode = _OperationsResearchMode.transportation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final useCompactTitle =
        MediaQuery.textScalerOf(context).scale(1) >= 1.6 ||
        MediaQuery.sizeOf(context).width < 360;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.t(useCompactTitle ? 'orShortTitle' : 'operationsResearch'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              key: const Key('or-page-scroll'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxl + bottomInset,
              ),
              children: [
                Text(
                  l10n.t('orWelcome'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.t('orWelcomeBody')),
                const SizedBox(height: AppSpacing.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<_OperationsResearchMode>(
                    key: const Key('or-mode-selector'),
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: _OperationsResearchMode.transportation,
                        label: Text(
                          l10n.t('orTransportation'),
                          key: const Key('or-mode-transportation'),
                        ),
                      ),
                      ButtonSegment(
                        value: _OperationsResearchMode.assignment,
                        label: Text(
                          l10n.t('orAssignment'),
                          key: const Key('or-mode-assignment'),
                        ),
                      ),
                      ButtonSegment(
                        value: _OperationsResearchMode.goalProgramming,
                        label: Text(
                          l10n.t('orGoalProgramming'),
                          key: const Key('or-mode-goal-programming'),
                        ),
                      ),
                      ButtonSegment(
                        value: _OperationsResearchMode.cpmPert,
                        label: Text(
                          l10n.t('orCpmPert'),
                          key: const Key('or-mode-cpm-pert'),
                        ),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (selection) {
                      setState(() => _mode = selection.first);
                      ref.read(operationsResearchProvider.notifier).clear();
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: switch (_mode) {
                      _OperationsResearchMode.transportation =>
                        const TransportationTab(),
                      _OperationsResearchMode.assignment =>
                        const AssignmentTab(),
                      _OperationsResearchMode.goalProgramming =>
                        const GoalProgrammingTab(),
                      _OperationsResearchMode.cpmPert => const CpmPertTab(),
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

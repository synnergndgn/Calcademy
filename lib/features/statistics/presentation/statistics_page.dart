import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/statistics/presentation/confidence_interval_tab.dart';
import 'package:calcademy/features/statistics/presentation/descriptive_statistics_tab.dart';
import 'package:calcademy/features/statistics/presentation/distribution_tab.dart';
import 'package:calcademy/features/statistics/presentation/statistics_controller.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/statistics_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/presentation/saved_calculations_controller.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StatisticsMode { descriptive, distributions, confidenceIntervals }

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key, this.savedCalculationId});

  final String? savedCalculationId;

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  var _mode = StatisticsMode.descriptive;
  StatisticsRestore? _restore;

  @override
  void initState() {
    super.initState();
    final id = widget.savedCalculationId;
    if (id == null) return;
    for (final item in ref.read(savedCalculationsProvider).items) {
      if (item.id != id) continue;
      final restore = StatisticsSavedAdapter.tryRestore(item);
      if (restore != null) {
        _restore = restore;
        _mode = switch (restore.mode) {
          StatisticsRestoreMode.descriptive => StatisticsMode.descriptive,
          StatisticsRestoreMode.distribution => StatisticsMode.distributions,
          StatisticsRestoreMode.confidenceInterval =>
            StatisticsMode.confidenceIntervals,
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
      appBar: AppBar(title: Text(l10n.t('statistics'))),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              key: const Key('statistics-scroll-view'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.lg + bottomInset,
              ),
              children: [
                Text(
                  l10n.t('statsWelcome'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.t('statsWelcomeBody')),
                const SizedBox(height: AppSpacing.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<StatisticsMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: StatisticsMode.descriptive,
                        label: Text(l10n.t('statsDescriptive')),
                      ),
                      ButtonSegment(
                        value: StatisticsMode.distributions,
                        label: Text(l10n.t('statsDistributions')),
                      ),
                      ButtonSegment(
                        value: StatisticsMode.confidenceIntervals,
                        label: Text(l10n.t('statsConfidenceIntervals')),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (selection) => setState(() {
                      _mode = selection.first;
                      ref.read(statisticsWorkspaceProvider.notifier).clear();
                    }),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: switch (_mode) {
                      StatisticsMode.descriptive => DescriptiveStatisticsTab(
                        restore: _restore,
                      ),
                      StatisticsMode.distributions => DistributionTab(
                        restore: _restore,
                      ),
                      StatisticsMode.confidenceIntervals =>
                        ConfidenceIntervalTab(restore: _restore),
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

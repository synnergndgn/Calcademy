import 'package:calcademy/features/statistics/application/confidence_interval_service.dart';
import 'package:calcademy/features/statistics/application/descriptive_statistics_service.dart';
import 'package:calcademy/features/statistics/application/probability_distribution_service.dart';
import 'package:calcademy/features/statistics/domain/statistics_result.dart';
import 'package:calcademy/core/widgets/result_auto_scroll.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final descriptiveStatisticsServiceProvider =
    Provider<DescriptiveStatisticsService>(
      (ref) => const DescriptiveStatisticsService(),
    );
final probabilityDistributionServiceProvider =
    Provider<ProbabilityDistributionService>(
      (ref) => const ProbabilityDistributionService(),
    );
final confidenceIntervalServiceProvider = Provider<ConfidenceIntervalService>(
  (ref) => const ConfidenceIntervalService(),
);

class StatisticsWorkspaceState {
  const StatisticsWorkspaceState({this.result});

  final StatisticsResult? result;
}

final statisticsWorkspaceProvider =
    NotifierProvider.autoDispose<
      StatisticsWorkspaceController,
      StatisticsWorkspaceState
    >(StatisticsWorkspaceController.new);

class StatisticsWorkspaceController extends Notifier<StatisticsWorkspaceState> {
  @override
  StatisticsWorkspaceState build() => const StatisticsWorkspaceState();

  void calculate(StatisticsResult Function() operation) {
    try {
      state = StatisticsWorkspaceState(result: operation());
    } on StatisticsValidationException catch (error) {
      state = StatisticsWorkspaceState(
        result: StatisticsFailureResult(error.issue),
      );
    } on Object {
      state = const StatisticsWorkspaceState(
        result: StatisticsFailureResult(StatisticsIssue.calculationRange),
      );
    }
  }

  void clear() => state = const StatisticsWorkspaceState();
}

/// Scrolls the freshly rendered result into view, but only when the
/// calculation actually succeeded.
///
/// [StatisticsWorkspaceController.calculate] does not throw on bad input - it
/// stores a [StatisticsFailureResult] - so the caller cannot tell success from
/// failure by the absence of an exception. Reading the result back is the only
/// honest signal, and it keeps the "never yank the viewport on a validation
/// error" rule in one place instead of three tabs.
void revealStatisticsResult(WidgetRef ref, GlobalKey resultKey) {
  final result = ref.read(statisticsWorkspaceProvider).result;
  if (result == null || result is StatisticsFailureResult) return;
  scheduleResultAutoScroll(resultKey);
}

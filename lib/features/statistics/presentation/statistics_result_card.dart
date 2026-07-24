import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/result_action_bar.dart';
import 'package:calcademy/features/statistics/domain/statistics_limits.dart';
import 'package:calcademy/features/statistics/domain/statistics_result.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/presentation/save_result_action.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class StatisticsResultCard extends StatelessWidget {
  const StatisticsResultCard({super.key, required this.result});

  final StatisticsResult result;

  /// Above this size, a descriptive dataset is stored count-only (to stay
  /// within the payload budget) and is not restorable.
  static const _maxRestorableDatasetSize = 500;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = result;
    if (current is StatisticsFailureResult) {
      return Card(
        key: const Key('statistics-result-card'),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(l10n.t(_issueKey(current.issue)))),
            ],
          ),
        ),
      );
    }

    final metrics = _metrics(current, l10n);
    final copyText = metrics
        .map((metric) => '${metric.$1}: ${metric.$2}')
        .join('\n');
    return Card(
      key: const Key('statistics-result-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.t('statsResult'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (current.approximate)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(l10n.t('statsApproximate')),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.t('statsMethod')}: ${l10n.t(current.methodKey)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _MetricGrid(metrics: metrics),
            for (final diagnostic in current.diagnostics) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.t(diagnostic),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            for (final warning in current.warnings) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(l10n.t(_warningKey(warning)))),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            ResultActionBar(
              copyText: copyText,
              copyButtonKey: const Key('stats-copy-result'),
              saveAction: SaveResultAction(
                buttonKey: const Key('stats-save-result'),
                draft: _savedDraft(current, copyText, l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<(String, String)> _metrics(
    StatisticsResult result,
    AppLocalizations l10n,
  ) {
    if (result is DescriptiveStatisticsResult) {
      return [
        (l10n.t('statsCount'), '${result.count}'),
        (l10n.t('statsSum'), _format(result.sum)),
        (l10n.t('statsMean'), _format(result.mean)),
        (l10n.t('statsMedian'), _format(result.median)),
        (
          l10n.t('statsMode'),
          result.modes.isEmpty
              ? l10n.t('statsNoMode')
              : result.modes.map(_format).join(', '),
        ),
        (l10n.t('statsMinimum'), _format(result.minimum)),
        (l10n.t('statsMaximum'), _format(result.maximum)),
        (l10n.t('statsRange'), _format(result.range)),
        (l10n.t('statsPopulationVariance'), _format(result.populationVariance)),
        (
          l10n.t('statsSampleVariance'),
          result.sampleVariance == null
              ? l10n.t('statsNotAvailable')
              : _format(result.sampleVariance!),
        ),
        (
          l10n.t('statsPopulationStd'),
          _format(result.populationStandardDeviation),
        ),
        (
          l10n.t('statsSampleStd'),
          result.sampleStandardDeviation == null
              ? l10n.t('statsNotAvailable')
              : _format(result.sampleStandardDeviation!),
        ),
        ('Q1', _format(result.q1)),
        ('Q3', _format(result.q3)),
        ('IQR', _format(result.iqr)),
        (
          l10n.t('statsOutliers'),
          result.outliers.isEmpty
              ? l10n.t('statsNone')
              : result.outliers.map(_format).join(', '),
        ),
      ];
    }
    if (result is DistributionResult) {
      return [
        (l10n.t('statsOperation'), l10n.t(result.operationLabel)),
        (l10n.t('statsProbability'), _format(result.probability)),
      ];
    }
    if (result is ConfidenceIntervalResult) {
      return [
        (l10n.t('statsLowerBound'), _format(result.lowerBound)),
        (l10n.t('statsUpperBound'), _format(result.upperBound)),
        (l10n.t('statsMarginOfError'), _format(result.marginOfError)),
      ];
    }
    return const [];
  }

  static SavedCalculationDraft _savedDraft(
    StatisticsResult result,
    String resultSummary,
    AppLocalizations l10n,
  ) {
    final calculationType = switch (result) {
      DescriptiveStatisticsResult() => 'descriptive',
      DistributionResult(:final kind) => kind.name,
      ConfidenceIntervalResult(:final kind) => kind.name,
      _ => 'statistics',
    };
    final inputSummary = switch (result) {
      DescriptiveStatisticsResult(:final values) =>
        values.map(_format).join(', '),
      _ =>
        result.inputs.entries
            .map((entry) => '${entry.key}: ${_format(entry.value)}')
            .join(', '),
    };
    // Restore payload: descriptive stores the full value list; distribution
    // records also store the operation label (which the numeric inputs
    // alone cannot recover: ≤ vs ≥ vs =). Legacy records lack these keys
    // and stay non-restorable.
    final fullInputJson = switch (result) {
      // Cap the stored value list so a huge dataset never blows the 32KB
      // payload budget and breaks saving; such records keep saving with
      // just the count and remain non-restorable.
      DescriptiveStatisticsResult(:final count, :final values) =>
        <String, Object?>{
          'count': count,
          if (values.length <= _maxRestorableDatasetSize) 'values': values,
        },
      DistributionResult(:final inputs, :final operationLabel) => {
        for (final entry in inputs.entries) entry.key: entry.value,
        'operation': operationLabel,
      },
      _ => result.inputs.map(
        (key, value) => MapEntry<String, Object?>(key, value),
      ),
    };
    return SavedCalculationDraft(
      title: l10n.t(result.methodKey),
      module: SavedCalculationModule.statistics,
      calculationType: calculationType,
      inputSummary: inputSummary,
      resultSummary: resultSummary,
      fullInputJson: fullInputJson,
      resultJson: {
        'methodKey': result.methodKey,
        'approximate': result.approximate,
        'summary': resultSummary,
      },
    );
  }

  static String _format(double value) {
    if (value == 0) return '0';
    if (value.abs() >= 1e9 || value.abs() < 1e-6) {
      return value.toStringAsExponential(6);
    }
    return value
        .toStringAsFixed(StatisticsLimits.displayPrecision)
        .replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static String _issueKey(StatisticsIssue issue) => switch (issue) {
    StatisticsIssue.emptyDataset => 'statsErrorEmptyDataset',
    StatisticsIssue.invalidNumber => 'statsErrorInvalidNumber',
    StatisticsIssue.ambiguousSeparator => 'statsErrorAmbiguousSeparator',
    StatisticsIssue.datasetTooLarge => 'statsErrorDatasetTooLarge',
    StatisticsIssue.insufficientSample => 'statsErrorInsufficientSample',
    StatisticsIssue.invalidStandardDeviation => 'statsErrorInvalidStd',
    StatisticsIssue.invalidProbability => 'statsErrorInvalidProbability',
    StatisticsIssue.invalidN => 'statsErrorInvalidN',
    StatisticsIssue.invalidK => 'statsErrorInvalidK',
    StatisticsIssue.kGreaterThanN => 'statsErrorKGreaterThanN',
    StatisticsIssue.invalidLambda => 'statsErrorInvalidLambda',
    StatisticsIssue.invalidConfidenceLevel => 'statsErrorInvalidConfidence',
    StatisticsIssue.unsupportedConfidenceLevel =>
      'statsErrorUnsupportedConfidence',
    StatisticsIssue.invalidSampleSize => 'statsErrorInvalidSampleSize',
    StatisticsIssue.invalidSuccesses => 'statsErrorInvalidSuccesses',
    StatisticsIssue.successesGreaterThanN => 'statsErrorSuccessesGreaterThanN',
    StatisticsIssue.calculationRange => 'statsErrorCalculationRange',
  };

  static String _warningKey(StatisticsWarning warning) => switch (warning) {
    StatisticsWarning.sampleVarianceUnavailable =>
      'statsWarningSampleUnavailable',
    StatisticsWarning.quartilesLimited => 'statsWarningQuartilesLimited',
    StatisticsWarning.approximateProbability =>
      'statsWarningApproximateProbability',
    StatisticsWarning.normalAssumption => 'statsWarningNormalAssumption',
    StatisticsWarning.independentTrialsAssumption =>
      'statsWarningIndependentTrials',
    StatisticsWarning.poissonAssumption => 'statsWarningPoissonAssumption',
    StatisticsWarning.knownSigmaAssumption => 'statsWarningKnownSigma',
    StatisticsWarning.tPopulationAssumption => 'statsWarningTPopulation',
    StatisticsWarning.wilsonIndependentAssumption =>
      'statsWarningWilsonIndependent',
  };
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<(String, String)> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640
            ? 3
            : constraints.maxWidth >= 360
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.$1,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        SelectableText(
                          metric.$2,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

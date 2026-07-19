import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/calculus/domain/calculus_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_number_formatter.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String calculusFailureKey(CalculusFailure failure) => switch (failure) {
  CalculusFailure.emptyInput => 'eqErrorEmpty',
  CalculusFailure.invalidSyntax => 'eqErrorSyntax',
  CalculusFailure.unbalancedParentheses => 'eqErrorParentheses',
  CalculusFailure.unknownVariable => 'eqErrorUnknownVariable',
  CalculusFailure.unknownFunction => 'eqErrorUnknownFunction',
  CalculusFailure.invalidNumber => 'eqErrorInvalidNumber',
  CalculusFailure.invalidStepSize => 'calcErrorStepSize',
  CalculusFailure.invalidBounds => 'calcErrorBounds',
  CalculusFailure.invalidSubintervalCount => 'calcErrorSubintervals',
  CalculusFailure.oddSimpsonSubintervals => 'calcErrorOddSimpson',
  CalculusFailure.evaluationUndefined => 'calcErrorUndefined',
  CalculusFailure.invalidAnalysisRange => 'calcErrorAnalysisRange',
};

String differentiationMethodKey(DifferentiationMethod method) =>
    switch (method) {
      DifferentiationMethod.forward => 'calcMethodForward',
      DifferentiationMethod.backward => 'calcMethodBackward',
      DifferentiationMethod.central => 'calcMethodCentral',
    };

String integrationMethodKey(IntegrationMethod method) => switch (method) {
  IntegrationMethod.trapezoidal => 'calcMethodTrapezoidal',
  IntegrationMethod.simpson13 => 'calcMethodSimpson',
};

/// Renders any calculus result with the module's shared hierarchy: value,
/// approximate badge, method, parameters, error estimate, warnings, copy.
/// Every numeric result is explicitly badged as approximate - this module
/// never claims exactness.
class CalculusResultCard extends StatelessWidget {
  const CalculusResultCard({super.key, this.result});

  final CalculusResult? result;

  @override
  Widget build(BuildContext context) {
    final current = result;
    if (current == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final lines = <Widget>[];
    String? copyText;

    void title(String text, {bool error = false}) => lines.add(
      Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          color: error ? theme.colorScheme.error : theme.colorScheme.primary,
        ),
      ),
    );

    void small(String text) =>
        lines.add(Text(text, style: theme.textTheme.bodySmall));

    void approximateBadge() => lines.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timeline,
              size: 16,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.t('eqApproximate'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    switch (current) {
      case DifferentiationSuccess():
        title(l10n.t('calcDerivativeResult'));
        approximateBadge();
        lines.add(
          Text(
            "f'(${formatMatrixNumber(current.point)}) ≈ "
            '${formatMatrixNumber(current.value)}',
            style: theme.textTheme.titleLarge,
          ),
        );
        small(
          '${l10n.t('eqMethodUsed')}: '
          '${l10n.t(differentiationMethodKey(current.method))}',
        );
        small('${l10n.t('calcStepSize')}: ${current.stepSize}');
        small(
          '${l10n.t('calcErrorEstimate')}: '
          '${current.errorEstimate.toStringAsExponential(2)}',
        );
        copyText = formatMatrixNumber(current.value);
      case IntegrationSuccess():
        title(l10n.t('calcIntegralResult'));
        approximateBadge();
        lines.add(
          Text(
            '∫ ≈ ${formatMatrixNumber(current.value)}',
            style: theme.textTheme.titleLarge,
          ),
        );
        small(
          '${l10n.t('eqMethodUsed')}: '
          '${l10n.t(integrationMethodKey(current.method))}',
        );
        small(
          '[${formatMatrixNumber(current.lowerBound)}, '
          '${formatMatrixNumber(current.upperBound)}] · '
          '${l10n.t('calcSubintervals')}: ${current.subintervals}',
        );
        small(
          '${l10n.t('calcErrorEstimate')}: '
          '${current.errorEstimate.toStringAsExponential(2)}',
        );
        copyText = formatMatrixNumber(current.value);
      case FunctionAnalysisSuccess():
        title(l10n.t('calcAnalysisResult'));
        approximateBadge();
        small(
          '${l10n.t('eqScannedInterval')}: '
          '[${formatMatrixNumber(current.rangeMin)}, '
          '${formatMatrixNumber(current.rangeMax)}] · '
          '${l10n.t('calcSamples')}: ${current.sampleCount}',
        );
        lines.add(const SizedBox(height: AppSpacing.xs));
        if (current.roots.isEmpty) {
          lines.add(Text(l10n.t('calcNoRootsInRange')));
        } else {
          lines.add(
            Text(
              '${l10n.t('calcRoots')}: '
              '${current.roots.map((r) => formatMatrixNumber(r.value)).join(', ')}',
            ),
          );
        }
        if (current.extrema.isEmpty) {
          lines.add(Text(l10n.t('calcNoExtremaInRange')));
        } else {
          for (final extremum in current.extrema) {
            lines.add(
              Text(
                '${l10n.t(extremum.isMinimum ? 'calcMinimum' : 'calcMaximum')}: '
                '(${formatMatrixNumber(extremum.x)}, '
                '${formatMatrixNumber(extremum.y)})',
              ),
            );
          }
        }
        if (current.inflectionPoints.isNotEmpty) {
          lines.add(
            Text(
              '${l10n.t('calcInflections')}: '
              '${current.inflectionPoints.map(formatMatrixNumber).join(', ')}',
            ),
          );
        }
        for (final interval in current.monotonicIntervals) {
          lines.add(
            Text(
              '[${formatMatrixNumber(interval.from)}, '
              '${formatMatrixNumber(interval.to)}]: '
              '${l10n.t(interval.increasing ? 'calcIncreasing' : 'calcDecreasing')}',
            ),
          );
        }
        if (current.observedMin != null && current.observedMax != null) {
          small(
            '${l10n.t('calcObservedRange')}: '
            '[${formatMatrixNumber(current.observedMin!.y)}, '
            '${formatMatrixNumber(current.observedMax!.y)}]',
          );
        }
        copyText = current.roots
            .map((r) => formatMatrixNumber(r.value))
            .join(', ');
      case CalculusFailureResult():
        title(l10n.t(calculusFailureKey(current.failure)), error: true);
    }

    for (final warning in current.warnings) {
      lines.add(
        Container(
          margin: const EdgeInsets.only(top: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.t(warning),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      key: const Key('calc-result-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...lines,
            if (copyText != null && copyText.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: copyText!));
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(l10n.t('copied'))));
                    }
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(l10n.t('copyResult')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

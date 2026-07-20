import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/equation_solver/application/linear_system_service.dart';
import 'package:calcademy/features/equation_solver/domain/equation_solver_result.dart';
import 'package:calcademy/features/matrix/domain/linear_system_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_number_formatter.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/presentation/save_result_action.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String equationFailureKey(EquationFailure failure) => switch (failure) {
  EquationFailure.emptyInput => 'eqErrorEmpty',
  EquationFailure.invalidSyntax => 'eqErrorSyntax',
  EquationFailure.unbalancedParentheses => 'eqErrorParentheses',
  EquationFailure.unknownVariable => 'eqErrorUnknownVariable',
  EquationFailure.unknownFunction => 'eqErrorUnknownFunction',
  EquationFailure.invalidNumber => 'eqErrorInvalidNumber',
  EquationFailure.invalidInterval => 'eqErrorInvalidInterval',
  EquationFailure.invalidBracket => 'eqErrorInvalidBracket',
  EquationFailure.derivativeNearZero => 'eqErrorDerivativeZero',
  EquationFailure.maxIterationsReached => 'eqErrorMaxIterations',
  EquationFailure.nonFiniteEvaluation => 'eqErrorNonFinite',
  EquationFailure.singularSystem => 'eqErrorSingular',
  EquationFailure.tooManyVariables => 'eqErrorSystemSize',
};

String equationMethodKey(EquationSolveMethod method) => switch (method) {
  EquationSolveMethod.analyticLinear => 'eqMethodAnalyticLinear',
  EquationSolveMethod.analyticQuadratic => 'eqMethodAnalyticQuadratic',
  EquationSolveMethod.scanAndBisect => 'eqMethodScan',
  EquationSolveMethod.bisection => 'eqMethodBisection',
  EquationSolveMethod.newtonRaphson => 'eqMethodNewton',
  EquationSolveMethod.secant => 'eqMethodSecant',
};

/// Renders any of the three tabs' results with a consistent hierarchy:
/// status line, roots/vector, exact-vs-approximate badge, method,
/// residual/iterations, warnings, copy action. Failure cases render as a
/// persistent card - never a transient snackbar - with a localized,
/// human-readable message.
class EquationResultCard extends StatelessWidget {
  const EquationResultCard({
    super.key,
    this.single,
    this.system,
    this.numeric,
    this.savedDraft,
  });

  final SingleEquationResult? single;
  final LinearSystemServiceResult? system;
  final NumericalMethodResult? numeric;
  final SavedCalculationDraft? savedDraft;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final lines = <Widget>[];
    String? copyText;

    void addTitle(String text, {bool error = false}) {
      lines.add(
        Text(
          text,
          style: theme.textTheme.titleMedium?.copyWith(
            color: error ? theme.colorScheme.error : theme.colorScheme.primary,
          ),
        ),
      );
    }

    void addBadge(bool exact) {
      lines.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                exact ? Icons.verified_outlined : Icons.timeline,
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
                  l10n.t(exact ? 'eqExact' : 'eqApproximate'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    void addWarnings(Iterable<String> warnings) {
      for (final warning in warnings) {
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
    }

    final singleResult = single;
    if (singleResult != null) {
      switch (singleResult) {
        case EquationRootsFound():
          addTitle(
            singleResult.roots.length == 1
                ? l10n.t('eqOneRootFound')
                : '${singleResult.roots.length} ${l10n.t('eqRootsFound')}',
          );
          addBadge(singleResult.exact);
          for (var i = 0; i < singleResult.roots.length; i++) {
            final root = singleResult.roots[i];
            lines.add(
              Text(
                'x${singleResult.roots.length > 1 ? '${i + 1}' : ''}'
                ' = ${formatMatrixNumber(root.value)}',
                style: theme.textTheme.titleLarge,
              ),
            );
          }
          final worstResidual = singleResult.roots
              .map((r) => r.residual)
              .reduce((a, b) => a > b ? a : b);
          lines.add(
            Text(
              '${l10n.t('eqResidual')}: ${worstResidual.toStringAsExponential(2)}',
              style: theme.textTheme.bodySmall,
            ),
          );
          if (singleResult.scanMin != null) {
            lines.add(
              Text(
                '${l10n.t('eqScannedInterval')}: '
                '[${formatMatrixNumber(singleResult.scanMin!)}, '
                '${formatMatrixNumber(singleResult.scanMax!)}]',
                style: theme.textTheme.bodySmall,
              ),
            );
          }
          copyText = singleResult.roots
              .map((r) => formatMatrixNumber(r.value))
              .join(', ');
        case EquationNoRealRoots():
          addTitle(
            l10n.t(
              singleResult.provenNone
                  ? 'eqNoRealRootsProven'
                  : 'eqNoRootsInInterval',
            ),
          );
          if (singleResult.complexRootsPossible) {
            lines.add(Text(l10n.t('eqComplexPossible')));
          }
          if (singleResult.scanMin != null) {
            lines.add(
              Text(
                '${l10n.t('eqScannedInterval')}: '
                '[${formatMatrixNumber(singleResult.scanMin!)}, '
                '${formatMatrixNumber(singleResult.scanMax!)}]',
                style: theme.textTheme.bodySmall,
              ),
            );
          }
        case EquationIdentity():
          addTitle(l10n.t('eqIdentity'));
        case EquationContradiction():
          addTitle(l10n.t('eqContradiction'));
        case EquationSolveFailure():
          addTitle(
            l10n.t(equationFailureKey(singleResult.failure)),
            error: true,
          );
      }
      lines.add(
        Text(
          '${l10n.t('eqMethodUsed')}: '
          '${l10n.t(equationMethodKey(singleResult.method))}',
          style: theme.textTheme.bodySmall,
        ),
      );
      addWarnings(singleResult.warnings);
    }

    final systemResult = system;
    if (systemResult != null) {
      switch (systemResult) {
        case LinearSystemSolved(:final result):
          switch (result) {
            case UniqueSolution(:final values):
              addTitle(l10n.t('eqSystemUnique'));
              addBadge(true);
              for (var i = 0; i < values.length; i++) {
                lines.add(
                  Text(
                    'x${i + 1} = ${formatMatrixNumber(values[i])}',
                    style: theme.textTheme.titleLarge,
                  ),
                );
              }
              copyText = values.map(formatMatrixNumber).join(', ');
            case InfiniteSolutions():
              addTitle(l10n.t('eqSystemInfinite'));
            case NoSolution():
              addTitle(l10n.t('eqSystemNone'));
          }
        case LinearSystemInvalid(:final failure):
          addTitle(l10n.t(equationFailureKey(failure)), error: true);
      }
    }

    final numericResult = numeric;
    if (numericResult != null) {
      if (numericResult.converged) {
        addTitle(l10n.t('eqConverged'));
        addBadge(false);
        lines.add(
          Text(
            'x = ${formatMatrixNumber(numericResult.root!)}',
            style: theme.textTheme.titleLarge,
          ),
        );
        copyText = formatMatrixNumber(numericResult.root!);
      } else {
        addTitle(
          l10n.t(
            equationFailureKey(
              numericResult.failure ?? EquationFailure.maxIterationsReached,
            ),
          ),
          error: true,
        );
        if (numericResult.lastEstimate != null) {
          lines.add(
            Text(
              '${l10n.t('eqLastEstimate')}: '
              '${formatMatrixNumber(numericResult.lastEstimate!)}',
            ),
          );
        }
      }
      lines.add(
        Text(
          '${l10n.t('eqMethodUsed')}: '
          '${l10n.t(equationMethodKey(numericResult.method))}',
          style: theme.textTheme.bodySmall,
        ),
      );
      lines.add(
        Text(
          '${l10n.t('eqIterations')}: ${numericResult.iterations}',
          style: theme.textTheme.bodySmall,
        ),
      );
      if (numericResult.residual != null) {
        lines.add(
          Text(
            '${l10n.t('eqResidual')}: '
            '${numericResult.residual!.toStringAsExponential(2)}',
            style: theme.textTheme.bodySmall,
          ),
        );
      }
    }

    if (lines.isEmpty) return const SizedBox.shrink();
    return Card(
      key: const Key('eq-result-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...lines,
            if (copyText != null || savedDraft != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  alignment: WrapAlignment.end,
                  children: [
                    if (copyText != null)
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: copyText!),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.t('copied'))),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: Text(l10n.t('copyResult')),
                      ),
                    if (savedDraft case final draft?)
                      SaveResultAction(
                        buttonKey: const Key('eq-save-result'),
                        draft: draft,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

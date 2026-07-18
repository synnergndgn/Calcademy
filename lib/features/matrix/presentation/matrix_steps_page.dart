import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/matrix/domain/matrix_number_formatter.dart';
import 'package:calcademy/features/matrix/domain/row_operation.dart';
import 'package:calcademy/features/matrix/presentation/matrix_widgets.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class MatrixStepsPage extends StatefulWidget {
  const MatrixStepsPage({
    required this.title,
    required this.reduction,
    super.key,
  });

  final String title;
  final RowReductionResult reduction;

  @override
  State<MatrixStepsPage> createState() => _MatrixStepsPageState();
}

class _MatrixStepsPageState extends State<MatrixStepsPage> {
  var _index = 0;
  var _showAll = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.t('matrixStepByStep'))),
      body: _showAll ? _allSteps(context) : _singleStep(context),
    );
  }

  Widget _singleStep(BuildContext context) {
    final operations = widget.reduction.operations;
    final operation = _index == 0 ? null : operations[_index - 1];
    final matrix = widget.reduction.matrixAt(_index);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        Text(
          _index == 0
              ? context.l10n.t('matrixInitialMatrix')
              : '${context.l10n.t('matrixStep')} $_index / ${operations.length}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          operation == null
              ? context.l10n.t('matrixStartDescription')
              : _operationDescription(operation),
        ),
        const SizedBox(height: AppSpacing.lg),
        MatrixView(
          matrix: matrix,
          dividerBeforeColumn: _dividerColumn,
          highlightedRows: operation?.changedRows.toSet() ?? const {},
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            IconButton.filledTonal(
              tooltip: context.l10n.t('matrixFirstStep'),
              onPressed: _index > 0 ? () => setState(() => _index = 0) : null,
              icon: const Icon(Icons.first_page_rounded),
            ),
            IconButton.filledTonal(
              tooltip: context.l10n.t('matrixPreviousStep'),
              onPressed: _index > 0 ? () => setState(() => _index--) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton.filledTonal(
              tooltip: context.l10n.t('matrixNextStep'),
              onPressed: _index < operations.length
                  ? () => setState(() => _index++)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            IconButton.filledTonal(
              tooltip: context.l10n.t('matrixLastStep'),
              onPressed: _index < operations.length
                  ? () => setState(() => _index = operations.length)
                  : null,
              icon: const Icon(Icons.last_page_rounded),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _showAll = true),
              icon: const Icon(Icons.view_list_rounded),
              label: Text(context.l10n.t('matrixAllSteps')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _allSteps(BuildContext context) {
    final operations = widget.reduction.operations;
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: operations.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => setState(() => _showAll = false),
              icon: const Icon(Icons.view_carousel_rounded),
              label: Text(context.l10n.t('matrixOneStepAtATime')),
            ),
          );
        }
        final stepIndex = index - 1;
        final operation = stepIndex == 0 ? null : operations[stepIndex - 1];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stepIndex == 0
                      ? context.l10n.t('matrixInitialMatrix')
                      : '${context.l10n.t('matrixStep')} $stepIndex',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (operation != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(_operationDescription(operation)),
                ],
                const SizedBox(height: AppSpacing.sm),
                MatrixView(
                  matrix: widget.reduction.matrixAt(stepIndex),
                  dividerBeforeColumn: _dividerColumn,
                  highlightedRows: operation?.changedRows.toSet() ?? const {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _operationDescription(RowOperation operation) => switch (operation) {
    SwapRows(:final first, :final second) =>
      'R${first + 1} \u2194 R${second + 1}',
    ScaleRow(:final row, :final factor) =>
      'R${row + 1} \u2190 ${formatMatrixNumber(factor)}R${row + 1}',
    AddRowMultiple(:final sourceRow, :final targetRow, :final factor) =>
      'R${targetRow + 1} \u2190 R${targetRow + 1} '
          '${factor < 0 ? '\u2212' : '+'} '
          '${formatMatrixNumber(factor.abs())}R${sourceRow + 1}',
  };

  int? get _dividerColumn {
    final initial = widget.reduction.initial;
    if (initial.columns == initial.rows * 2) return initial.rows;
    if (initial.columns == initial.rows + 1) return initial.columns - 1;
    return null;
  }
}

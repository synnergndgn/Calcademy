import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/matrix/data/matrix_repository.dart';
import 'package:calcademy/features/matrix/domain/linear_system_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_constants.dart';
import 'package:calcademy/features/matrix/domain/matrix_error.dart';
import 'package:calcademy/features/matrix/domain/matrix_examples.dart';
import 'package:calcademy/features/matrix/domain/matrix_number_formatter.dart';
import 'package:calcademy/features/matrix/domain/matrix_operation.dart';
import 'package:calcademy/features/matrix/domain/matrix_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_value.dart';
import 'package:calcademy/features/matrix/domain/saved_matrix_operation.dart';
import 'package:calcademy/features/matrix/presentation/matrix_controller.dart';
import 'package:calcademy/features/matrix/presentation/matrix_steps_page.dart';
import 'package:calcademy/features/matrix/presentation/matrix_widgets.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/matrix_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/presentation/save_result_action.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MatrixHomePage extends ConsumerStatefulWidget {
  const MatrixHomePage({this.savedMatrixId, super.key});

  final String? savedMatrixId;

  @override
  ConsumerState<MatrixHomePage> createState() => _MatrixHomePageState();
}

class _MatrixHomePageState extends ConsumerState<MatrixHomePage> {
  final _matrixA = MatrixEditorHandle();
  final _matrixB = MatrixEditorHandle();
  final _scalar = TextEditingController(text: '2');
  final _rowOne = TextEditingController(text: '1');
  final _rowTwo = TextEditingController(text: '2');
  var _initialA = matrixExamples.first.inputs.first;
  var _initialB = matrixExamples.first.inputs[1];
  var _editorRevision = 0;
  var _loadedSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedIfNeeded());
  }

  @override
  void dispose() {
    _scalar.dispose();
    _rowOne.dispose();
    _rowTwo.dispose();
    super.dispose();
  }

  void _loadSavedIfNeeded() {
    if (_loadedSaved || widget.savedMatrixId == null || !mounted) return;
    _loadedSaved = true;
    final saved = ref
        .read(savedMatricesProvider.notifier)
        .find(widget.savedMatrixId!);
    if (saved == null) return;
    setState(() {
      _initialA = saved.inputs.first;
      if (saved.inputs.length > 1) _initialB = saved.inputs[1];
      _scalar.text = formatMatrixNumber(saved.parameters['scalar'] ?? 2);
      _rowOne.text = '${(saved.parameters['row1'] ?? 0).round() + 1}';
      _rowTwo.text = '${(saved.parameters['row2'] ?? 1).round() + 1}';
      _editorRevision++;
    });
    ref.read(matrixWorkspaceProvider.notifier).loadSaved(saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.t('matrices')),
        actions: [
          IconButton(
            tooltip: context.l10n.t('matrixNewOperation'),
            onPressed: _newOperation,
            icon: const Icon(Icons.add_box_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _IntroCard(onExample: _applyExample),
          const SizedBox(height: AppSpacing.md),
          _OperationSelector(onSelected: _selectOperation),
          const SizedBox(height: AppSpacing.md),
          _MatrixInputs(
            key: ValueKey(_editorRevision),
            matrixA: _matrixA,
            matrixB: _matrixB,
            initialA: _initialA,
            initialB: _initialB,
            scalar: _scalar,
            rowOne: _rowOne,
            rowTwo: _rowTwo,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const ValueKey('matrix-calculate'),
            onPressed: _calculate,
            icon: const Icon(Icons.calculate_outlined),
            label: Text(context.l10n.t('matrixCalculate')),
          ),
          const SizedBox(height: AppSpacing.lg),
          _MatrixResultPanel(onNewOperation: _newOperation),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  void _selectOperation(MatrixOperationType operation) {
    ref.read(matrixWorkspaceProvider.notifier).selectOperation(operation);
    setState(() {
      if (operation == MatrixOperationType.solveLinearSystem &&
          _initialA.columns == _initialA.rows) {
        _initialA = MatrixValue.zero(2, 3);
      } else if (operation != MatrixOperationType.solveLinearSystem &&
          _initialA.columns > matrixMaxColumns) {
        _initialA = MatrixValue.zero(2, 2);
      }
      _editorRevision++;
    });
  }

  void _applyExample(MatrixExample example) {
    ref
        .read(matrixWorkspaceProvider.notifier)
        .selectOperation(example.operation);
    setState(() {
      _initialA = example.inputs.first;
      if (example.inputs.length > 1) _initialB = example.inputs[1];
      _editorRevision++;
    });
  }

  void _newOperation() {
    ref.read(matrixWorkspaceProvider.notifier).newOperation();
    setState(() {
      _initialA = matrixExamples.first.inputs.first;
      _initialB = matrixExamples.first.inputs[1];
      _scalar.text = '2';
      _rowOne.text = '1';
      _rowTwo.text = '2';
      _editorRevision++;
    });
  }

  void _calculate() {
    try {
      final operation = ref.read(matrixWorkspaceProvider).operation;
      final inputs = <MatrixValue>[_matrixA.read()];
      if (operation.needsSecondMatrix) inputs.add(_matrixB.read());
      final parameters = <String, double>{};
      if (operation == MatrixOperationType.scalarMultiply ||
          operation == MatrixOperationType.scaleRow ||
          operation == MatrixOperationType.addRowMultiple) {
        parameters['scalar'] = parseMatrixNumber(_scalar.text);
      }
      if (operation.isRowOperation) {
        parameters['row1'] = _parseRow(_rowOne.text).toDouble();
        if (operation != MatrixOperationType.scaleRow) {
          parameters['row2'] = _parseRow(_rowTwo.text).toDouble();
        }
      }
      ref
          .read(matrixWorkspaceProvider.notifier)
          .execute(inputs, parameters: parameters);
      FocusScope.of(context).unfocus();
    } on MatrixException catch (error) {
      ref.read(matrixWorkspaceProvider.notifier).reportError(error.code);
    }
  }

  int _parseRow(String value) {
    final row = int.tryParse(value.trim());
    if (row == null || row < 1 || row > matrixMaxRows) {
      throw const MatrixException(MatrixErrorCode.invalidRowOperation);
    }
    return row - 1;
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.onExample});

  final ValueChanged<MatrixExample> onExample;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.t('matrixWelcome'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(context.l10n.t('matrixWelcomeBody')),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.t('matrixExamples'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final example in matrixExamples) ...[
                  ActionChip(
                    label: Text(context.l10n.t(example.titleKey)),
                    onPressed: () => onExample(example),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _OperationSelector extends ConsumerWidget {
  const _OperationSelector({required this.onSelected});

  final ValueChanged<MatrixOperationType> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      matrixWorkspaceProvider.select((state) => state.operation),
    );
    return KeyedSubtree(
      key: const ValueKey('matrix-operation-selector'),
      child: DropdownButtonFormField<MatrixOperationType>(
        key: ValueKey(selected),
        initialValue: selected,
        decoration: InputDecoration(
          labelText: context.l10n.t('matrixChooseOperation'),
          prefixIcon: const Icon(Icons.functions_rounded),
        ),
        isExpanded: true,
        items: [
          for (final operation in MatrixOperationType.values)
            DropdownMenuItem(
              value: operation,
              child: Text(
                '${operation.notation}  \u2014  '
                '${context.l10n.t(operation.localizationKey)}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (value) {
          if (value != null) onSelected(value);
        },
      ),
    );
  }
}

class _MatrixInputs extends ConsumerWidget {
  const _MatrixInputs({
    required this.matrixA,
    required this.matrixB,
    required this.initialA,
    required this.initialB,
    required this.scalar,
    required this.rowOne,
    required this.rowTwo,
    super.key,
  });

  final MatrixEditorHandle matrixA;
  final MatrixEditorHandle matrixB;
  final MatrixValue initialA;
  final MatrixValue initialB;
  final TextEditingController scalar;
  final TextEditingController rowOne;
  final TextEditingController rowTwo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operation = ref.watch(
      matrixWorkspaceProvider.select((state) => state.operation),
    );
    final augmented = operation == MatrixOperationType.solveLinearSystem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditableMatrixGrid(
          label: augmented
              ? context.l10n.t('matrixAugmented')
              : context.l10n.t('matrixA'),
          handle: matrixA,
          initialValue: initialA,
          maxColumns: augmented ? matrixMaxAugmentedColumns : matrixMaxColumns,
          augmented: augmented,
        ),
        if (operation.needsSecondMatrix) ...[
          const SizedBox(height: AppSpacing.md),
          EditableMatrixGrid(
            label: context.l10n.t('matrixB'),
            handle: matrixB,
            initialValue: initialB,
          ),
        ],
        if (operation == MatrixOperationType.scalarMultiply ||
            operation == MatrixOperationType.scaleRow ||
            operation == MatrixOperationType.addRowMultiple) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: scalar,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: InputDecoration(
              labelText: context.l10n.t('matrixScalar'),
            ),
          ),
        ],
        if (operation.isRowOperation) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: rowOne,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.l10n.t('matrixSourceRow'),
                  ),
                ),
              ),
              if (operation != MatrixOperationType.scaleRow) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: rowTwo,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.l10n.t('matrixTargetRow'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _MatrixResultPanel extends ConsumerStatefulWidget {
  const _MatrixResultPanel({required this.onNewOperation});

  final VoidCallback onNewOperation;

  @override
  ConsumerState<_MatrixResultPanel> createState() => _MatrixResultPanelState();
}

class _MatrixResultPanelState extends ConsumerState<_MatrixResultPanel> {
  (int, int)? _selectedCell;
  MatrixExecution? _lastExecution;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(
      matrixWorkspaceProvider.select((state) => (state.execution, state.error)),
    );
    final execution = snapshot.$1;
    final error = snapshot.$2;
    if (!identical(execution, _lastExecution)) {
      _lastExecution = execution;
      _selectedCell = null;
    }
    if (error != null) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(_matrixErrorText(context, error))),
            ],
          ),
        ),
      );
    }
    if (execution == null) return const SizedBox.shrink();
    return Card(
      key: const ValueKey('matrix-result-panel'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.t('matrixResult'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '${execution.operation.notation} \u2014 '
              '${context.l10n.t(execution.operation.localizationKey)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.t('matrixApproximateResult'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _resultContent(execution),
            const SizedBox(height: AppSpacing.md),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(context.l10n.t('matrixInputs')),
              children: [
                for (var index = 0; index < execution.inputs.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: MatrixView(
                      matrix: execution.inputs[index],
                      augmented:
                          execution.operation ==
                          MatrixOperationType.solveLinearSystem,
                      highlightedRows:
                          execution.operation == MatrixOperationType.multiply &&
                              index == 0 &&
                              _selectedCell != null
                          ? {_selectedCell!.$1}
                          : const {},
                      highlightedColumn:
                          execution.operation == MatrixOperationType.multiply &&
                              index == 1
                          ? _selectedCell?.$2
                          : null,
                    ),
                  ),
              ],
            ),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _copy(execution),
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(context.l10n.t('matrixCopyResult')),
                ),
                OutlinedButton.icon(
                  onPressed: () => _save(execution),
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: Text(context.l10n.t('matrixSaveResult')),
                ),
                SaveResultAction(
                  buttonKey: const Key('matrix-save-calculation'),
                  draft: MatrixSavedAdapter.fromExecution(
                    execution,
                    title: context.l10n.t(execution.operation.localizationKey),
                  ),
                ),
                if (execution.steps != null)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => MatrixStepsPage(
                          title: context.l10n.t(
                            execution.operation.localizationKey,
                          ),
                          reduction: execution.steps!,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.format_list_numbered_rounded),
                    label: Text(context.l10n.t('matrixShowSteps')),
                  ),
                TextButton.icon(
                  onPressed: widget.onNewOperation,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(context.l10n.t('matrixNewOperation')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultContent(MatrixExecution execution) {
    return switch (execution.result) {
      MatrixResultValue(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (execution.operation == MatrixOperationType.multiply)
            Text(context.l10n.t('matrixTapResultCell')),
          const SizedBox(height: AppSpacing.xs),
          MatrixView(
            matrix: value,
            selectedCell: _selectedCell,
            onCellTap: execution.operation == MatrixOperationType.multiply
                ? (row, column) => setState(() => _selectedCell = (row, column))
                : null,
          ),
          if (_selectedCell != null &&
              execution.operation == MatrixOperationType.multiply) ...[
            const SizedBox(height: AppSpacing.sm),
            _MultiplicationExplanation(
              detail: execution.multiplicationDetail(
                _selectedCell!.$1,
                _selectedCell!.$2,
              ),
            ),
          ],
        ],
      ),
      ScalarMatrixResult(:final value) => Semantics(
        label: formatMatrixNumber(value),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${execution.operation.notation} = ${formatMatrixNumber(value)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (execution.operation == MatrixOperationType.determinant &&
                execution.inputs.first.rows == 2)
              Text(_twoByTwoDeterminantFormula(execution.inputs.first)),
          ],
        ),
      ),
      LinearSystemMatrixResult(:final value) => _LinearResultView(value: value),
    };
  }

  Future<void> _copy(MatrixExecution execution) async {
    await Clipboard.setData(
      ClipboardData(text: _executionText(context, execution)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.t('copied'))));
  }

  Future<void> _save(MatrixExecution execution) async {
    final activeId = ref.read(matrixWorkspaceProvider).activeSavedId;
    final existing = activeId == null
        ? null
        : ref.read(savedMatricesProvider.notifier).find(activeId);
    final title = TextEditingController(
      text:
          existing?.title ??
          context.l10n.t(execution.operation.localizationKey),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('matrixSaveResult')),
        content: TextField(
          controller: title,
          autofocus: true,
          decoration: InputDecoration(labelText: context.l10n.t('title')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.t('save')),
          ),
        ],
      ),
    );
    final value = title.text.trim();
    title.dispose();
    if (confirmed != true || value.isEmpty) return;
    await ref
        .read(savedMatricesProvider.notifier)
        .upsert(
          SavedMatrixOperation(
            id:
                existing?.id ??
                'matrix-${DateTime.now().microsecondsSinceEpoch}',
            title: value,
            type: execution.operation,
            inputs: execution.inputs,
            result: execution.result,
            parameters: execution.parameters,
            createdAt: existing?.createdAt ?? DateTime.now(),
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.t('matrixSaved'))));
  }

  String _executionText(BuildContext context, MatrixExecution execution) =>
      switch (execution.result) {
        MatrixResultValue(:final value) => matrixToPlainText(value),
        ScalarMatrixResult(:final value) =>
          '${execution.operation.notation} = ${formatMatrixNumber(value)}',
        LinearSystemMatrixResult(:final value) => _linearResultText(
          context,
          value,
        ),
      };
}

class _MultiplicationExplanation extends StatelessWidget {
  const _MultiplicationExplanation({required this.detail});

  final MultiplicationCellDetail detail;

  @override
  Widget build(BuildContext context) {
    final terms = detail.terms
        .map(
          (term) =>
              '${formatMatrixNumber(term.left)}\u00d7${formatMatrixNumber(term.right)}',
        )
        .join(' + ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Text(
        'C${detail.row + 1}${detail.column + 1} = $terms\n'
        'C${detail.row + 1}${detail.column + 1} = '
        '${formatMatrixNumber(detail.result)}',
      ),
    );
  }
}

class _LinearResultView extends StatelessWidget {
  const _LinearResultView({required this.value});

  final LinearSystemResult value;

  @override
  Widget build(BuildContext context) => switch (value) {
    UniqueSolution(:final values) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.t('matrixUniqueSolution'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var index = 0; index < values.length; index++)
          Text('x${index + 1} = ${formatMatrixNumber(values[index])}'),
      ],
    ),
    InfiniteSolutions(:final pivotColumns, :final freeColumns) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.t('matrixInfiniteSolutions'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          '${context.l10n.t('matrixPivotVariables')}: '
          '${pivotColumns.map((index) => 'x${index + 1}').join(', ')}',
        ),
        Text(
          '${context.l10n.t('matrixFreeVariables')}: '
          '${freeColumns.map((index) => 'x${index + 1}').join(', ')}',
        ),
        const SizedBox(height: AppSpacing.sm),
        MatrixView(matrix: value.reducedMatrix, augmented: true),
      ],
    ),
    NoSolution() => Text(
      context.l10n.t('matrixNoSolution'),
      style: Theme.of(context).textTheme.titleMedium,
    ),
  };
}

String _linearResultText(BuildContext context, LinearSystemResult value) =>
    switch (value) {
      UniqueSolution(:final values) =>
        values.indexed
            .map(
              (entry) => 'x${entry.$1 + 1} = ${formatMatrixNumber(entry.$2)}',
            )
            .join('\n'),
      InfiniteSolutions(:final pivotColumns, :final freeColumns) =>
        '${context.l10n.t('matrixPivotVariables')}: '
            '${pivotColumns.map((index) => 'x${index + 1}').join(', ')}; '
            '${context.l10n.t('matrixFreeVariables')}: '
            '${freeColumns.map((index) => 'x${index + 1}').join(', ')}\n'
            '${matrixToPlainText(value.reducedMatrix)}',
      NoSolution() => context.l10n.t('matrixNoSolution'),
    };

String _matrixErrorText(BuildContext context, MatrixErrorCode error) =>
    context.l10n.t(switch (error) {
      MatrixErrorCode.invalidDimensions => 'matrixInvalidDimensions',
      MatrixErrorCode.incompatibleDimensions => 'matrixIncompatibleDimensions',
      MatrixErrorCode.squareRequired => 'matrixSquareRequired',
      MatrixErrorCode.singular => 'matrixSingular',
      MatrixErrorCode.invalidNumber => 'matrixInvalidNumber',
      MatrixErrorCode.invalidAugmentedMatrix => 'matrixInvalidAugmented',
      MatrixErrorCode.invalidRowOperation => 'matrixInvalidRowOperation',
    });

String _twoByTwoDeterminantFormula(MatrixValue matrix) =>
    '${formatMatrixNumber(matrix.at(0, 0))}\u00d7'
    '${formatMatrixNumber(matrix.at(1, 1))} \u2212 '
    '${formatMatrixNumber(matrix.at(0, 1))}\u00d7'
    '${formatMatrixNumber(matrix.at(1, 0))}';

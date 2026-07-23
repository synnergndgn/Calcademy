import 'package:calcademy/app/theme/app_radius.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/matrix/domain/matrix_constants.dart';
import 'package:calcademy/features/matrix/domain/matrix_number_formatter.dart';
import 'package:calcademy/features/matrix/domain/matrix_value.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MatrixEditorHandle {
  _EditableMatrixGridState? _state;

  MatrixValue read() {
    final state = _state;
    if (state == null) return MatrixValue.zero(2, 2);
    return state.read();
  }

  void replace(MatrixValue value) => _state?._replace(value);
  void clear() => _state?._clear();
}

class EditableMatrixGrid extends StatefulWidget {
  const EditableMatrixGrid({
    required this.label,
    required this.handle,
    required this.initialValue,
    this.maxColumns = matrixMaxColumns,
    this.augmented = false,
    super.key,
  });

  final String label;
  final MatrixEditorHandle handle;
  final MatrixValue initialValue;
  final int maxColumns;
  final bool augmented;

  @override
  State<EditableMatrixGrid> createState() => _EditableMatrixGridState();
}

class _EditableMatrixGridState extends State<EditableMatrixGrid> {
  late List<List<TextEditingController>> _controllers;

  int get _rows => _controllers.length;
  int get _columns => _controllers.first.length;

  @override
  void initState() {
    super.initState();
    _controllers = _controllersFor(widget.initialValue);
    widget.handle._state = this;
  }

  @override
  void didUpdateWidget(EditableMatrixGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.handle != widget.handle) {
      if (oldWidget.handle._state == this) oldWidget.handle._state = null;
      widget.handle._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.handle._state == this) widget.handle._state = null;
    _disposeControllers(_controllers);
    super.dispose();
  }

  MatrixValue read() => MatrixValue([
    for (final row in _controllers)
      [for (final controller in row) parseMatrixNumber(controller.text)],
  ]);

  void _replace(MatrixValue value) {
    _disposeControllers(_controllers);
    setState(() => _controllers = _controllersFor(value));
  }

  void _clear() {
    for (final controller in _controllers.expand((row) => row)) {
      controller.clear();
    }
  }

  Future<void> _resize(int rows, int columns) async {
    if (rows < matrixMinSize ||
        columns < matrixMinSize ||
        rows > matrixMaxRows ||
        columns > widget.maxColumns) {
      return;
    }
    if (rows < _rows || columns < _columns) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.t('matrixResizeWarningTitle')),
          content: Text(context.l10n.t('matrixResizeWarningBody')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.t('matrixResize')),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    MatrixValue current;
    try {
      current = read();
    } on Object {
      current = MatrixValue([
        for (final row in _controllers)
          [for (final cell in row) double.tryParse(cell.text) ?? 0],
      ]);
    }
    _replace(current.resized(rows, columns));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.label, style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: context.l10n.t('matrixClear'),
                  onPressed: _clear,
                  icon: const Icon(Icons.backspace_outlined),
                ),
              ],
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _DimensionControl(
                  label: context.l10n.t('matrixRows'),
                  value: _rows,
                  onDecrease: _rows > matrixMinSize
                      ? () => _resize(_rows - 1, _columns)
                      : null,
                  onIncrease: _rows < matrixMaxRows
                      ? () => _resize(_rows + 1, _columns)
                      : null,
                ),
                _DimensionControl(
                  label: context.l10n.t('matrixColumns'),
                  value: _columns,
                  onDecrease: _columns > matrixMinSize
                      ? () => _resize(_rows, _columns - 1)
                      : null,
                  onIncrease: _columns < widget.maxColumns
                      ? () => _resize(_rows, _columns + 1)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 410),
              child: Scrollbar(
                thumbVisibility: _rows > 5,
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: FocusTraversalGroup(
                      policy: ReadingOrderTraversalPolicy(),
                      child: _EditableGridBody(
                        label: widget.label,
                        controllers: _controllers,
                        augmented: widget.augmented,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<List<TextEditingController>> _controllersFor(MatrixValue value) =>
      [
        for (final row in value.values)
          [
            for (final cell in row)
              TextEditingController(
                text: cell == 0 ? '' : formatMatrixNumber(cell),
              ),
          ],
      ];

  static void _disposeControllers(
    List<List<TextEditingController>> controllers,
  ) {
    for (final controller in controllers.expand((row) => row)) {
      controller.dispose();
    }
  }
}

class _DimensionControl extends StatelessWidget {
  const _DimensionControl({
    required this.label,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final int value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    final controls = [
      IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: context.l10n.t('matrixRemove'),
        onPressed: onDecrease,
        icon: const Icon(Icons.remove_rounded),
      ),
      IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: context.l10n.t('matrixAddDimension'),
        onPressed: onIncrease,
        icon: const Icon(Icons.add_rounded),
      ),
    ];
    if (MediaQuery.textScalerOf(context).scale(1) >= 1.6) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: $value', maxLines: 1, overflow: TextOverflow.ellipsis),
          Row(mainAxisSize: MainAxisSize.min, children: controls),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Text('$label: $value'), ...controls],
    );
  }
}

class _EditableGridBody extends StatelessWidget {
  const _EditableGridBody({
    required this.label,
    required this.controllers,
    required this.augmented,
  });

  final String label;
  final List<List<TextEditingController>> controllers;
  final bool augmented;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border.symmetric(
          vertical: BorderSide(color: colors.primary, width: 2),
        ),
        borderRadius: AppRadius.control,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 32),
              for (var column = 0; column < controllers.first.length; column++)
                SizedBox(
                  width: 76,
                  child: Text(
                    column == controllers.first.length - 1 && augmented
                        ? 'b'
                        : '${column + 1}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
            ],
          ),
          for (var row = 0; row < controllers.length; row++)
            Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '${row + 1}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                for (var column = 0; column < controllers[row].length; column++)
                  Container(
                    width: 76,
                    padding: const EdgeInsets.all(3),
                    decoration:
                        augmented && column == controllers[row].length - 1
                        ? BoxDecoration(
                            border: Border(
                              left: BorderSide(color: colors.outline),
                            ),
                          )
                        : null,
                    child: Semantics(
                      label:
                          '$label, ${context.l10n.t('matrixRow')} ${row + 1}, '
                          '${context.l10n.t('matrixColumn')} ${column + 1}',
                      textField: true,
                      child: TextField(
                        key: ValueKey('$label-$row-$column'),
                        controller: controllers[row][column],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9eE+\-./]'),
                          ),
                        ],
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class MatrixView extends StatelessWidget {
  const MatrixView({
    required this.matrix,
    this.augmented = false,
    this.dividerBeforeColumn,
    this.highlightedRows = const {},
    this.highlightedColumn,
    this.selectedCell,
    this.onCellTap,
    super.key,
  });

  final MatrixValue matrix;
  final bool augmented;
  final int? dividerBeforeColumn;
  final Set<int> highlightedRows;
  final int? highlightedColumn;
  final (int, int)? selectedCell;
  final void Function(int row, int column)? onCellTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: matrixToPlainText(matrix),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            border: Border.symmetric(
              vertical: BorderSide(color: colors.primary, width: 2),
            ),
            borderRadius: AppRadius.control,
          ),
          child: Column(
            children: [
              for (var row = 0; row < matrix.rows; row++)
                Row(
                  children: [
                    for (var column = 0; column < matrix.columns; column++)
                      _MatrixCell(
                        value: matrix.at(row, column),
                        highlighted:
                            highlightedRows.contains(row) ||
                            highlightedColumn == column,
                        selected: selectedCell == (row, column),
                        augmentedDivider:
                            column ==
                            (dividerBeforeColumn ??
                                (augmented ? matrix.columns - 1 : -1)),
                        onTap: onCellTap == null
                            ? null
                            : () => onCellTap!(row, column),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatrixCell extends StatelessWidget {
  const _MatrixCell({
    required this.value,
    required this.highlighted,
    required this.selected,
    required this.augmentedDivider,
    this.onTap,
  });

  final double value;
  final bool highlighted;
  final bool selected;
  final bool augmentedDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cell = Container(
      constraints: const BoxConstraints(minWidth: 62, minHeight: 42),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: selected
            ? colors.tertiaryContainer
            : highlighted
            ? colors.secondaryContainer
            : null,
        border: augmentedDivider
            ? Border(left: BorderSide(color: colors.outline))
            : selected
            ? Border.all(color: colors.tertiary, width: 2)
            : null,
      ),
      child: Text(formatMatrixNumber(value)),
    );
    return onTap == null ? cell : InkWell(onTap: onTap, child: cell);
  }
}

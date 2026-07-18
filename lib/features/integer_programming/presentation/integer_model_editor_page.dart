// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/integer_programming/domain/mip_constants.dart';
import 'package:calcademy/features/integer_programming/presentation/integer_model_summary_page.dart';
import 'package:calcademy/features/integer_programming/presentation/integer_program_draft.dart';
import 'package:calcademy/features/integer_programming/presentation/variable_type_selector.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/features/linear_programming/presentation/linear_program_draft.dart'
    show ConstraintDraft;
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The model input form: title, direction, variables (name, objective
/// coefficient, type), constraints, an inline mathematical summary, and
/// the solve button. Split out from the home page so the editor itself -
/// the part most likely to grow (assignment helper editor, presolve
/// warnings, ...) - stays in its own file.
class IntegerModelEditor extends StatefulWidget {
  const IntegerModelEditor({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.onSolve,
  });

  final IntegerProgramDraft draft;
  final VoidCallback onChanged;
  final VoidCallback onSolve;

  @override
  State<IntegerModelEditor> createState() => _IntegerModelEditorState();
}

class _IntegerModelEditorState extends State<IntegerModelEditor> {
  IntegerProgramDraft get _draft => widget.draft;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.t('mipNewModel'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('mip-title'),
              controller: _draft.title,
              onChanged: (_) => widget.onChanged(),
              decoration: InputDecoration(labelText: l10n.t('lpModelTitle')),
            ),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<ObjectiveDirection>(
                segments: [
                  ButtonSegment(
                    value: ObjectiveDirection.maximize,
                    label: Text(l10n.t('lpMaximize')),
                  ),
                  ButtonSegment(
                    value: ObjectiveDirection.minimize,
                    label: Text(l10n.t('lpMinimize')),
                  ),
                ],
                selected: {_draft.direction},
                onSelectionChanged: (value) => setState(() {
                  _draft.direction = value.first;
                  widget.onChanged();
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.t('lpVariables')}: ${_draft.variableCount}',
                  ),
                ),
                IconButton(
                  tooltip: l10n.t('lpRemoveVariable'),
                  onPressed: _draft.variableCount <= 1
                      ? null
                      : () => setState(() {
                          _draft.setVariableCount(_draft.variableCount - 1);
                          widget.onChanged();
                        }),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  tooltip: l10n.t('lpAddVariable'),
                  onPressed:
                      _draft.variableCount >= MipConstants.maxTotalVariables
                      ? null
                      : () => setState(() {
                          _draft.setVariableCount(_draft.variableCount + 1);
                          widget.onChanged();
                        }),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            Text(
              l10n.t('mipNonnegativeNotice'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_draft.integerOrBinaryCount >
                MipConstants.maxIntegerVariables) ...[
              const SizedBox(height: AppSpacing.xs),
              _PerformanceWarning(count: _draft.integerOrBinaryCount),
            ],
            const SizedBox(height: AppSpacing.sm),
            for (var index = 0; index < _draft.variableCount; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Card.outlined(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _draft.variableNames[index],
                                onChanged: (_) => widget.onChanged(),
                                decoration: InputDecoration(
                                  labelText:
                                      '${l10n.t('lpVariable')} ${index + 1}',
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextField(
                                key: Key('mip-objective-$index'),
                                controller: _draft.objective[index],
                                onChanged: (_) => widget.onChanged(),
                                decoration: InputDecoration(
                                  labelText:
                                      '${l10n.t('lpObjective')} c${index + 1}',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        VariableTypeSelector(
                          key: Key('mip-type-$index'),
                          variableLabel: _draft.variableNames[index].text,
                          value: _draft.variableTypes[index],
                          onChanged: (type) => setState(() {
                            _draft.setVariableType(index, type);
                            widget.onChanged();
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.t('lpConstraints'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${_draft.constraints.length}/${MipConstants.maxConstraints}',
                ),
                IconButton(
                  tooltip: l10n.t('lpAddConstraint'),
                  onPressed:
                      _draft.constraints.length >= MipConstants.maxConstraints
                      ? null
                      : () => setState(() {
                          _draft.addConstraint();
                          widget.onChanged();
                        }),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            for (var index = 0; index < _draft.constraints.length; index++)
              _ConstraintEditor(
                key: ValueKey(_draft.constraints[index].id),
                draft: _draft.constraints[index],
                variableNames: _draft.variableNames,
                onChanged: widget.onChanged,
                onDelete: _draft.constraints.length == 1
                    ? null
                    : () => setState(() {
                        _draft.removeConstraint(index);
                        widget.onChanged();
                      }),
              ),
            const SizedBox(height: AppSpacing.sm),
            IntegerModelSummaryView(draft: _draft),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              key: const Key('mip-solve'),
              onPressed: widget.onSolve,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.t('mipSolve')),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceWarning extends StatelessWidget {
  const _PerformanceWarning({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.speed,
            color: theme.colorScheme.onTertiaryContainer,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              context.l10n.t('mipPerformanceWarning'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConstraintEditor extends StatefulWidget {
  const _ConstraintEditor({
    super.key,
    required this.draft,
    required this.variableNames,
    required this.onChanged,
    this.onDelete,
  });

  final ConstraintDraft draft;
  final List<TextEditingController> variableNames;
  final VoidCallback onChanged;
  final VoidCallback? onDelete;

  @override
  State<_ConstraintEditor> createState() => _ConstraintEditorState();
}

class _ConstraintEditorState extends State<_ConstraintEditor> {
  final _cellsScrollController = ScrollController();

  @override
  void dispose() {
    _cellsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.draft.name,
                  onChanged: (_) => widget.onChanged(),
                  decoration: InputDecoration(
                    labelText: context.l10n.t('lpConstraintName'),
                  ),
                ),
              ),
              IconButton(
                tooltip: context.l10n.t('delete'),
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          // The coefficient/relation/RHS row can be wider than the screen
          // once a model has more than a couple of variables (each cell is
          // a fixed width so every column stays aligned across
          // constraints). A visible Scrollbar makes that explicit instead
          // of leaving the relation and RHS fields silently off-screen
          // with no hint that the row scrolls.
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Scrollbar(
              controller: _cellsScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _cellsScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    for (
                      var index = 0;
                      index < widget.draft.coefficients.length;
                      index++
                    ) ...[
                      SizedBox(
                        width: 76,
                        child: TextField(
                          key: Key('mip-cell-${widget.draft.id}-$index'),
                          controller: widget.draft.coefficients[index],
                          onChanged: (_) => widget.onChanged(),
                          textAlign: TextAlign.end,
                          decoration: InputDecoration(
                            labelText: widget.variableNames[index].text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    SizedBox(
                      width: 96,
                      child: DropdownButtonFormField<ConstraintRelation>(
                        initialValue: widget.draft.relation,
                        items: const [
                          DropdownMenuItem(
                            value: ConstraintRelation.lessOrEqual,
                            child: Text('≤'),
                          ),
                          DropdownMenuItem(
                            value: ConstraintRelation.greaterOrEqual,
                            child: Text('≥'),
                          ),
                          DropdownMenuItem(
                            value: ConstraintRelation.equal,
                            child: Text('='),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => widget.draft.relation = value);
                            widget.onChanged();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 88,
                      child: TextField(
                        controller: widget.draft.rhs,
                        onChanged: (_) => widget.onChanged(),
                        decoration: const InputDecoration(labelText: 'RHS'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

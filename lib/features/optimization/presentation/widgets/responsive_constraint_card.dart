import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// One selectable relation (≤, ≥, =) for [ResponsiveConstraintCard].
///
/// The card is shared by the Linear and Integer Programming editors but
/// must not depend on either module's domain types, so the relation is a
/// generic [value] plus its display [symbol] and a spoken [semanticLabel]
/// for screen readers (the bare symbol is not reliably announced).
class RelationOption<T> {
  const RelationOption({
    required this.value,
    required this.symbol,
    required this.semanticLabel,
  });

  final T value;
  final String symbol;
  final String semanticLabel;
}

/// The horizontally scrollable coefficient row of a constraint card.
///
/// Only the coefficient cells scroll; the relation and RHS fields live
/// outside this strip so they always stay inside the viewport. The
/// scrollbar thumb is always visible so the scrollability is discoverable
/// even before the first drag.
class CoefficientInputStrip extends StatefulWidget {
  const CoefficientInputStrip({
    super.key,
    required this.labels,
    required this.controllers,
    required this.onChanged,
    this.cellKeys,
    this.minCellWidth = 88,
  }) : assert(labels.length == controllers.length);

  final List<String> labels;
  final List<TextEditingController> controllers;
  final VoidCallback onChanged;

  /// Optional per-cell keys so callers can keep their existing widget-test
  /// keys (e.g. `Key('lp-cell-<id>-<i>')`).
  final List<Key>? cellKeys;
  final double minCellWidth;

  @override
  State<CoefficientInputStrip> createState() => _CoefficientInputStripState();
}

class _CoefficientInputStripState extends State<CoefficientInputStrip> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: _scrollController,
    thumbVisibility: true,
    child: SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          for (var index = 0; index < widget.controllers.length; index++) ...[
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: widget.minCellWidth),
              child: IntrinsicWidth(
                child: TextField(
                  key: widget.cellKeys?[index],
                  controller: widget.controllers[index],
                  onChanged: (_) => widget.onChanged(),
                  textAlign: TextAlign.end,
                  decoration: InputDecoration(
                    labelText: widget.labels[index],
                    isDense: true,
                  ),
                ),
              ),
            ),
            if (index < widget.controllers.length - 1)
              const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    ),
  );
}

/// A constraint editor card shared by the Linear and Integer Programming
/// model editors.
///
/// Layout (compact/phone):
/// ```
/// Constraint 1              [up][down][copy][delete]
/// coefficients ................... horizontal scroll
/// [relation ▾]  [RHS........................]
/// [constraint name .........................]
/// ```
/// The relation and RHS fields are deliberately outside the coefficient
/// strip so they never scroll off-screen; on very narrow layouts they
/// stack vertically instead of shrinking below usable width.
///
/// The card is intentionally domain-free: it receives controllers, labels
/// and callbacks and never imports LP/IP domain types, so both modules
/// share one implementation instead of two drifting copies.
class ResponsiveConstraintCard<T> extends StatelessWidget {
  const ResponsiveConstraintCard({
    super.key,
    required this.title,
    required this.variableLabels,
    required this.coefficientControllers,
    required this.relation,
    required this.relationOptions,
    required this.onRelationChanged,
    required this.rhsController,
    required this.nameController,
    required this.relationLabel,
    required this.rhsLabel,
    required this.nameLabel,
    required this.onChanged,
    required this.deleteTooltip,
    this.coefficientCellKeys,
    this.relationFieldKey,
    this.rhsFieldKey,
    this.onDelete,
    this.onCopy,
    this.copyTooltip,
    this.onMoveUp,
    this.moveUpTooltip,
    this.onMoveDown,
    this.moveDownTooltip,
  });

  final String title;
  final List<String> variableLabels;
  final List<TextEditingController> coefficientControllers;
  final T relation;
  final List<RelationOption<T>> relationOptions;
  final ValueChanged<T> onRelationChanged;
  final TextEditingController rhsController;
  final TextEditingController nameController;
  final String relationLabel;
  final String rhsLabel;
  final String nameLabel;
  final VoidCallback onChanged;
  final List<Key>? coefficientCellKeys;
  final Key? relationFieldKey;
  final Key? rhsFieldKey;

  /// Null disables the delete button (e.g. for the last remaining
  /// constraint) rather than hiding it, so the layout stays stable.
  final VoidCallback? onDelete;
  final String deleteTooltip;
  final VoidCallback? onCopy;
  final String? copyTooltip;
  final VoidCallback? onMoveUp;
  final String? moveUpTooltip;
  final VoidCallback? onMoveDown;
  final String? moveDownTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onMoveUp != null || moveUpTooltip != null)
                  _HeaderIcon(
                    tooltip: moveUpTooltip ?? '',
                    icon: Icons.arrow_upward,
                    onPressed: onMoveUp,
                  ),
                if (onMoveDown != null || moveDownTooltip != null)
                  _HeaderIcon(
                    tooltip: moveDownTooltip ?? '',
                    icon: Icons.arrow_downward,
                    onPressed: onMoveDown,
                  ),
                if (onCopy != null || copyTooltip != null)
                  _HeaderIcon(
                    tooltip: copyTooltip ?? '',
                    icon: Icons.copy,
                    onPressed: onCopy,
                  ),
                _HeaderIcon(
                  tooltip: deleteTooltip,
                  icon: Icons.delete_outline,
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            CoefficientInputStrip(
              labels: variableLabels,
              controllers: coefficientControllers,
              onChanged: onChanged,
              cellKeys: coefficientCellKeys,
            ),
            const SizedBox(height: AppSpacing.xs),
            LayoutBuilder(
              builder: (context, constraints) {
                final relationField = DropdownButtonFormField<T>(
                  key: relationFieldKey,
                  initialValue: relation,
                  decoration: InputDecoration(
                    labelText: relationLabel,
                    isDense: true,
                  ),
                  items: [
                    for (final option in relationOptions)
                      DropdownMenuItem(
                        value: option.value,
                        child: Semantics(
                          label: option.semanticLabel,
                          child: Text(option.symbol),
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) onRelationChanged(value);
                  },
                );
                final rhsField = TextField(
                  key: rhsFieldKey,
                  controller: rhsController,
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                    labelText: rhsLabel,
                    isDense: true,
                  ),
                );
                // At ~240 logical px of card interior (a 320px phone with
                // large text, or a split-screen window) the side-by-side
                // pair would squeeze the RHS below usable width; stack
                // vertically instead.
                if (constraints.maxWidth < 240) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      relationField,
                      const SizedBox(height: AppSpacing.xs),
                      rhsField,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 110, child: relationField),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: rhsField),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: nameController,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(labelText: nameLabel, isDense: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 20),
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
  );
}

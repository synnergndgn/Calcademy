import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/integer_programming/domain/optimization_variable_type.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Lets the user pick continuous/integer/binary for a single decision
/// variable. Every option carries visible text (never colour alone, see
/// the module's accessibility notes), and binary shows a short explanation
/// of the automatic `0 <= x <= 1` bound instead of asking the user to type
/// it as a constraint.
class VariableTypeSelector extends StatelessWidget {
  const VariableTypeSelector({
    super.key,
    required this.variableLabel,
    required this.value,
    required this.onChanged,
  });

  final String variableLabel;
  final OptimizationVariableType value;
  final ValueChanged<OptimizationVariableType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: '$variableLabel ${l10n.t('mipVariableType')}',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<OptimizationVariableType>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: OptimizationVariableType.continuous,
                  label: Text(l10n.t('mipContinuous')),
                ),
                ButtonSegment(
                  value: OptimizationVariableType.integer,
                  label: Text(l10n.t('mipInteger')),
                ),
                ButtonSegment(
                  value: OptimizationVariableType.binary,
                  label: Text(l10n.t('mipBinary')),
                ),
              ],
              selected: {value},
              onSelectionChanged: (selection) => onChanged(selection.first),
            ),
          ),
        ),
        if (value == OptimizationVariableType.binary)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Text(
              l10n.t('mipBinaryHint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

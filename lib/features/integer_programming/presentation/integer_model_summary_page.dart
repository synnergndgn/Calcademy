import 'package:calcademy/features/integer_programming/domain/integer_program.dart';
import 'package:calcademy/features/integer_programming/domain/optimization_variable_type.dart';
import 'package:calcademy/features/integer_programming/presentation/integer_program_draft.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The model, written out in mathematical notation, before it is solved
/// (section 32 of the module spec): objective, constraints, and every
/// variable's type shown explicitly (`x ≥ 0`, `x ∈ Z₊`, or `x ∈ {0,1}`) so
/// a mixed model never leaves the reader guessing which bound applies to
/// which variable.
class IntegerModelSummaryView extends StatelessWidget {
  const IntegerModelSummaryView({super.key, required this.draft});

  final IntegerProgramDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String text;
    try {
      text = _describe(draft.buildProgram(), l10n);
    } on Object {
      text = l10n.t('mipInvalidInput');
    }
    return ExpansionTile(
      title: Text(l10n.t('mipModelSummary')),
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  String _describe(IntegerProgram program, AppLocalizations l10n) {
    final model = program.linearModel;
    final sign = model.direction == ObjectiveDirection.maximize
        ? l10n.t('lpMaximize')
        : l10n.t('lpMinimize');
    final objective = [
      for (var index = 0; index < model.objective.length; index++)
        '${formatLpNumber(model.objective[index])}${model.variables[index].name}',
    ].join(' + ');
    final buffer = StringBuffer('$sign\nZ = $objective\n\n');
    buffer.writeln(l10n.t('lpConstraints'));
    for (final constraint in model.constraints) {
      final terms = [
        for (var index = 0; index < constraint.coefficients.length; index++)
          if (constraint.coefficients[index] != 0)
            '${formatLpNumber(constraint.coefficients[index])}${model.variables[index].name}',
      ].join(' + ');
      final symbol = switch (constraint.relation) {
        ConstraintRelation.lessOrEqual => '≤',
        ConstraintRelation.greaterOrEqual => '≥',
        ConstraintRelation.equal => '=',
      };
      buffer.writeln('$terms $symbol ${formatLpNumber(constraint.rhs)}');
    }
    buffer.writeln();
    for (final variable in model.variables) {
      final type = program.variableTypes[variable.id]!;
      buffer.writeln(switch (type) {
        OptimizationVariableType.continuous => '${variable.name} ≥ 0',
        OptimizationVariableType.integer => '${variable.name} ∈ Z₊',
        OptimizationVariableType.binary => '${variable.name} ∈ {0,1}',
      });
    }
    return buffer.toString().trimRight();
  }
}

// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:calcademy/features/integer_programming/domain/integer_program.dart';
import 'package:calcademy/features/integer_programming/domain/mip_constants.dart';
import 'package:calcademy/features/integer_programming/domain/optimization_variable_type.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/features/linear_programming/presentation/linear_program_draft.dart'
    show ConstraintDraft;
import 'package:flutter/widgets.dart';

/// Form state for the integer program editor. Constraint rows reuse the
/// linear programming module's [ConstraintDraft] as-is (a constraint is a
/// constraint, whether or not any of its variables are typed integer or
/// binary); only the variable list gains a per-variable
/// [OptimizationVariableType].
class IntegerProgramDraft {
  IntegerProgramDraft() {
    title = TextEditingController(text: 'Integer program');
    variableNames = [
      TextEditingController(text: 'x1'),
      TextEditingController(text: 'x2'),
    ];
    objective = [
      TextEditingController(text: '0'),
      TextEditingController(text: '0'),
    ];
    variableTypes = [
      OptimizationVariableType.integer,
      OptimizationVariableType.integer,
    ];
    constraints = [ConstraintDraft(2, 0)];
  }

  IntegerProgramDraft.fromProgram(IntegerProgram program) {
    title = TextEditingController(text: program.title);
    direction = program.linearModel.direction;
    variableNames = program.linearModel.variables
        .map((item) => TextEditingController(text: item.name))
        .toList();
    objective = program.linearModel.objective
        .map((value) => TextEditingController(text: formatLpNumber(value)))
        .toList();
    variableTypes = [
      for (final variable in program.linearModel.variables)
        program.variableTypes[variable.id]!,
    ];
    constraints = program.linearModel.constraints
        .map(ConstraintDraft.fromConstraint)
        .toList();
  }

  late final TextEditingController title;
  ObjectiveDirection direction = ObjectiveDirection.maximize;
  late final List<TextEditingController> variableNames;
  late final List<TextEditingController> objective;
  late List<OptimizationVariableType> variableTypes;
  late final List<ConstraintDraft> constraints;

  int get variableCount => objective.length;

  int get integerOrBinaryCount => variableTypes
      .where((type) => type != OptimizationVariableType.continuous)
      .length;

  void setVariableCount(int count) {
    final target = count.clamp(1, MipConstants.maxTotalVariables);
    while (objective.length < target) {
      final index = objective.length;
      objective.add(TextEditingController(text: '0'));
      variableNames.add(TextEditingController(text: 'x${index + 1}'));
      variableTypes.add(OptimizationVariableType.continuous);
    }
    while (objective.length > target) {
      objective.removeLast().dispose();
      variableNames.removeLast().dispose();
      variableTypes.removeLast();
    }
    for (final constraint in constraints) constraint.resize(target);
  }

  void setVariableType(int index, OptimizationVariableType type) {
    variableTypes[index] = type;
  }

  void addConstraint() {
    if (constraints.length < MipConstants.maxConstraints) {
      constraints.add(ConstraintDraft(variableCount, constraints.length));
    }
  }

  void removeConstraint(int index) {
    if (constraints.length <= 1) return;
    constraints.removeAt(index).dispose();
  }

  IntegerProgram buildProgram() {
    final variables = [
      for (var index = 0; index < variableCount; index++)
        DecisionVariable(
          id: 'x${index + 1}',
          name: variableNames[index].text.trim().isEmpty
              ? 'x${index + 1}'
              : variableNames[index].text.trim(),
        ),
    ];
    final linearModel = LinearProgram(
      title: title.text.trim().isEmpty ? 'Integer program' : title.text.trim(),
      direction: direction,
      variables: variables,
      objective: objective.map((item) => parseLpNumber(item.text)).toList(),
      constraints: [
        for (var index = 0; index < constraints.length; index++)
          LinearConstraint(
            id: constraints[index].id,
            name: constraints[index].name.text.trim().isEmpty
                ? 'C${index + 1}'
                : constraints[index].name.text.trim(),
            coefficients: constraints[index].coefficients
                .map((item) => parseLpNumber(item.text))
                .toList(),
            relation: constraints[index].relation,
            rhs: parseLpNumber(constraints[index].rhs.text),
          ),
      ],
    );
    return IntegerProgram(
      linearModel: linearModel,
      variableTypes: {
        for (var index = 0; index < variables.length; index++)
          variables[index].id: variableTypes[index],
      },
    );
  }

  void dispose() {
    title.dispose();
    for (final controller in variableNames) controller.dispose();
    for (final controller in objective) controller.dispose();
    for (final constraint in constraints) constraint.dispose();
  }
}

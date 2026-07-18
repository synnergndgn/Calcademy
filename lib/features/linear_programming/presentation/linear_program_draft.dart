// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/features/linear_programming/domain/lp_constants.dart';
import 'package:flutter/widgets.dart';

class ConstraintDraft {
  ConstraintDraft(int variableCount, int index)
    : id = 'c${DateTime.now().microsecondsSinceEpoch}-$index',
      name = TextEditingController(text: 'C${index + 1}'),
      coefficients = [
        for (var i = 0; i < variableCount; i++)
          TextEditingController(text: '0'),
      ],
      rhs = TextEditingController(text: '0');

  ConstraintDraft.fromConstraint(LinearConstraint constraint)
    : id = constraint.id,
      name = TextEditingController(text: constraint.name),
      coefficients = constraint.coefficients
          .map((value) => TextEditingController(text: formatLpNumber(value)))
          .toList(),
      relation = constraint.relation,
      rhs = TextEditingController(text: formatLpNumber(constraint.rhs));

  final String id;
  final TextEditingController name;
  final List<TextEditingController> coefficients;
  ConstraintRelation relation = ConstraintRelation.lessOrEqual;
  final TextEditingController rhs;

  ConstraintDraft copy(int index) {
    final result = ConstraintDraft(coefficients.length, index);
    result.name.text = '${name.text} copy';
    for (var i = 0; i < coefficients.length; i++)
      result.coefficients[i].text = coefficients[i].text;
    result.relation = relation;
    result.rhs.text = rhs.text;
    return result;
  }

  void resize(int size) {
    while (coefficients.length < size)
      coefficients.add(TextEditingController(text: '0'));
    while (coefficients.length > size) coefficients.removeLast().dispose();
  }

  void dispose() {
    name.dispose();
    for (final controller in coefficients) controller.dispose();
    rhs.dispose();
  }
}

class LinearProgramDraft {
  LinearProgramDraft() {
    title = TextEditingController(text: 'Product mix');
    variableNames = [
      TextEditingController(text: 'x1'),
      TextEditingController(text: 'x2'),
    ];
    objective = [
      TextEditingController(text: '3'),
      TextEditingController(text: '2'),
    ];
    constraints = [ConstraintDraft(2, 0)];
  }

  LinearProgramDraft.fromProgram(LinearProgram program) {
    title = TextEditingController(text: program.title);
    direction = program.direction;
    variableNames = program.variables
        .map((item) => TextEditingController(text: item.name))
        .toList();
    objective = program.objective
        .map((value) => TextEditingController(text: formatLpNumber(value)))
        .toList();
    constraints = program.constraints
        .map(ConstraintDraft.fromConstraint)
        .toList();
  }

  late final TextEditingController title;
  ObjectiveDirection direction = ObjectiveDirection.maximize;
  late final List<TextEditingController> variableNames;
  late final List<TextEditingController> objective;
  late final List<ConstraintDraft> constraints;

  int get variableCount => objective.length;

  void setVariableCount(int count) {
    final target = count.clamp(
      LpConstants.minVariables,
      LpConstants.maxVariables,
    );
    while (objective.length < target) {
      final index = objective.length;
      objective.add(TextEditingController(text: '0'));
      variableNames.add(TextEditingController(text: 'x${index + 1}'));
    }
    while (objective.length > target) {
      objective.removeLast().dispose();
      variableNames.removeLast().dispose();
    }
    for (final constraint in constraints) constraint.resize(target);
  }

  void addConstraint() {
    if (constraints.length < LpConstants.maxConstraints) {
      constraints.add(ConstraintDraft(variableCount, constraints.length));
    }
  }

  void removeConstraint(int index) {
    if (constraints.length <= 1) return;
    constraints.removeAt(index).dispose();
  }

  LinearProgram buildProgram() => LinearProgram(
    title: title.text.trim().isEmpty ? 'Linear program' : title.text.trim(),
    direction: direction,
    variables: [
      for (var index = 0; index < variableCount; index++)
        DecisionVariable(
          id: 'x${index + 1}',
          name: variableNames[index].text.trim().isEmpty
              ? 'x${index + 1}'
              : variableNames[index].text.trim(),
        ),
    ],
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

  void dispose() {
    title.dispose();
    for (final controller in variableNames) controller.dispose();
    for (final controller in objective) controller.dispose();
    for (final constraint in constraints) constraint.dispose();
  }
}

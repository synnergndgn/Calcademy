import 'dart:collection';

import 'package:calcademy/features/linear_programming/domain/lp_constants.dart';

enum ObjectiveDirection { maximize, minimize }

enum ConstraintRelation { lessOrEqual, greaterOrEqual, equal }

class DecisionVariable {
  DecisionVariable({required this.id, required this.name})
    : assert(id.isNotEmpty),
      assert(name.isNotEmpty);

  final String id;
  final String name;

  Map<String, Object?> toJson() => {'id': id, 'name': name};

  factory DecisionVariable.fromJson(Map<String, Object?> json) =>
      DecisionVariable(
        id: json['id']! as String,
        name: json['name']! as String,
      );
}

class LinearConstraint {
  LinearConstraint({
    required this.id,
    required this.name,
    required List<double> coefficients,
    required this.relation,
    required this.rhs,
  }) : coefficients = UnmodifiableListView(coefficients) {
    if (coefficients.isEmpty || coefficients.any((value) => !value.isFinite)) {
      throw const FormatException('Invalid constraint coefficients.');
    }
    if (!rhs.isFinite) throw const FormatException('Invalid constraint RHS.');
  }

  final String id;
  final String name;
  final List<double> coefficients;
  final ConstraintRelation relation;
  final double rhs;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'coefficients': coefficients,
    'relation': relation.name,
    'rhs': rhs,
  };

  factory LinearConstraint.fromJson(Map<String, Object?> json) =>
      LinearConstraint(
        id: json['id']! as String,
        name: json['name']! as String,
        coefficients: (json['coefficients']! as List<Object?>)
            .map((value) => (value! as num).toDouble())
            .toList(),
        relation: ConstraintRelation.values.byName(json['relation']! as String),
        rhs: (json['rhs']! as num).toDouble(),
      );
}

class LinearProgram {
  LinearProgram({
    required this.title,
    required this.direction,
    required List<DecisionVariable> variables,
    required List<double> objective,
    required List<LinearConstraint> constraints,
  }) : variables = UnmodifiableListView(variables),
       objective = UnmodifiableListView(objective),
       constraints = UnmodifiableListView(constraints) {
    if (variables.length < LpConstants.minVariables ||
        variables.length > LpConstants.maxVariables ||
        objective.length != variables.length ||
        objective.any((value) => !value.isFinite)) {
      throw const FormatException('Invalid objective dimensions.');
    }
    if (constraints.length < LpConstants.minConstraints ||
        constraints.length > LpConstants.maxConstraints ||
        constraints.any(
          (item) => item.coefficients.length != variables.length,
        )) {
      throw const FormatException('Invalid constraint dimensions.');
    }
  }

  /// Builds a [LinearProgram] without the size/shape validation performed
  /// by the default constructor. Intended for internal callers - such as
  /// the integer programming module's Branch-and-Bound solver - that need
  /// to augment an already-valid model with extra generated constraints
  /// beyond [LpConstants.maxConstraints] (e.g. one bound per branching
  /// decision on a deep node). Never exposed through a user-facing editor.
  LinearProgram.unchecked({
    required this.title,
    required this.direction,
    required List<DecisionVariable> variables,
    required List<double> objective,
    required List<LinearConstraint> constraints,
  }) : variables = UnmodifiableListView(variables),
       objective = UnmodifiableListView(objective),
       constraints = UnmodifiableListView(constraints);

  final String title;
  final ObjectiveDirection direction;
  final List<DecisionVariable> variables;
  final List<double> objective;
  final List<LinearConstraint> constraints;

  Map<String, Object?> toJson() => {
    'title': title,
    'direction': direction.name,
    'variables': variables.map((item) => item.toJson()).toList(),
    'objective': objective,
    'constraints': constraints.map((item) => item.toJson()).toList(),
  };

  factory LinearProgram.fromJson(Map<String, Object?> json) => LinearProgram(
    title: json['title']! as String,
    direction: ObjectiveDirection.values.byName(json['direction']! as String),
    variables: (json['variables']! as List<Object?>)
        .map(
          (value) => DecisionVariable.fromJson(
            Map<String, Object?>.from(value! as Map),
          ),
        )
        .toList(),
    objective: (json['objective']! as List<Object?>)
        .map((value) => (value! as num).toDouble())
        .toList(),
    constraints: (json['constraints']! as List<Object?>)
        .map(
          (value) => LinearConstraint.fromJson(
            Map<String, Object?>.from(value! as Map),
          ),
        )
        .toList(),
  );
}

double parseLpNumber(String source) {
  final text = source.trim().replaceAll(',', '.');
  if (text.contains('/')) {
    final parts = text.split('/');
    if (parts.length != 2) throw const FormatException('Invalid fraction.');
    final numerator = double.parse(parts[0].trim());
    final denominator = double.parse(parts[1].trim());
    if (denominator == 0) throw const FormatException('Division by zero.');
    final result = numerator / denominator;
    if (!result.isFinite) throw const FormatException('Invalid number.');
    return result;
  }
  final result = double.parse(text);
  if (!result.isFinite) throw const FormatException('Invalid number.');
  return result;
}

String formatLpNumber(double value) {
  if (value.abs() < LpConstants.simplexEpsilon) return '0';
  if ((value - value.round()).abs() < LpConstants.simplexEpsilon) {
    return value.round().toString();
  }
  return value
      .toStringAsFixed(6)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

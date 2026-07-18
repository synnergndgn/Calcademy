import 'dart:collection';

import 'package:calcademy/features/integer_programming/domain/mip_constants.dart';
import 'package:calcademy/features/integer_programming/domain/optimization_variable_type.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';

/// A mixed integer linear program: a continuous [LinearProgram] plus a
/// per-variable [OptimizationVariableType] map that tells the
/// Branch-and-Bound solver which decision variables must take integer or
/// binary values. The linear model itself is never mutated with integer
/// bookkeeping, so it stays a plain, reusable [LinearProgram] that the
/// existing simplex solver can consume directly for every relaxation.
class IntegerProgram {
  IntegerProgram({
    required LinearProgram linearModel,
    required Map<String, OptimizationVariableType> variableTypes,
  }) : linearModel = linearModel,
       variableTypes = UnmodifiableMapView(Map.of(variableTypes)) {
    final variableIds = linearModel.variables.map((item) => item.id).toSet();
    if (variableIds.length != linearModel.variables.length ||
        !_setEquals(variableIds, this.variableTypes.keys.toSet())) {
      throw const FormatException(
        'Variable type map must match the linear model variables exactly.',
      );
    }
    final integerCount = this.variableTypes.values
        .where((type) => type != OptimizationVariableType.continuous)
        .length;
    if (integerCount == 0) {
      throw const FormatException(
        'An integer program requires at least one integer or binary variable.',
      );
    }
  }

  final LinearProgram linearModel;
  final Map<String, OptimizationVariableType> variableTypes;

  String get title => linearModel.title;

  bool isIntegerOrBinary(String variableId) =>
      variableTypes[variableId] != OptimizationVariableType.continuous;

  int get integerVariableCount => variableTypes.values
      .where((type) => type != OptimizationVariableType.continuous)
      .length;

  /// Whether this model exceeds the *recommended* integer/binary variable
  /// count ([MipConstants.maxIntegerVariables]). Branch-and-Bound is
  /// exponential in the worst case, so models above this size are still
  /// solved, but the editor shows a performance warning instead of a hard
  /// block (the total variable and constraint counts remain hard-capped by
  /// the underlying [LinearProgram]).
  bool get exceedsRecommendedIntegerCount =>
      integerVariableCount > MipConstants.maxIntegerVariables;

  /// The relaxation used at the root of the Branch-and-Bound tree: the same
  /// linear model, with an automatic `x <= 1` constraint appended for every
  /// binary variable (the non-negativity lower bound already comes from the
  /// simplex solver's standard assumption). Integer variables are otherwise
  /// left as ordinary continuous columns; integrality is enforced only by
  /// the branching constraints added at each node, never by this model.
  LinearProgram get relaxationModel {
    final binaryConstraints = <LinearConstraint>[];
    for (var index = 0; index < linearModel.variables.length; index++) {
      final variable = linearModel.variables[index];
      if (variableTypes[variable.id] != OptimizationVariableType.binary) {
        continue;
      }
      binaryConstraints.add(
        LinearConstraint(
          id: 'bin-${variable.id}',
          name: '${variable.name} ≤ 1',
          coefficients: [
            for (
              var column = 0;
              column < linearModel.variables.length;
              column++
            )
              column == index ? 1.0 : 0.0,
          ],
          relation: ConstraintRelation.lessOrEqual,
          rhs: 1,
        ),
      );
    }
    if (binaryConstraints.isEmpty) return linearModel;
    return LinearProgram.unchecked(
      title: linearModel.title,
      direction: linearModel.direction,
      variables: linearModel.variables,
      objective: linearModel.objective,
      constraints: [...linearModel.constraints, ...binaryConstraints],
    );
  }

  Map<String, Object?> toJson() => {
    'linearModel': linearModel.toJson(),
    'variableTypes': variableTypes.map(
      (key, value) => MapEntry(key, value.name),
    ),
  };

  factory IntegerProgram.fromJson(Map<String, Object?> json) => IntegerProgram(
    linearModel: LinearProgram.fromJson(
      Map<String, Object?>.from(json['linearModel']! as Map),
    ),
    variableTypes: (json['variableTypes']! as Map).map(
      (key, value) => MapEntry(
        key as String,
        OptimizationVariableType.values.byName(value! as String),
      ),
    ),
  );
}

bool _setEquals<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.every(b.contains);

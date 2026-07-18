import 'package:calcademy/features/integer_programming/domain/integer_program.dart';
import 'package:calcademy/features/integer_programming/domain/optimization_variable_type.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:flutter_test/flutter_test.dart';

IntegerProgram _twoVarModel({
  OptimizationVariableType x1 = OptimizationVariableType.integer,
  OptimizationVariableType x2 = OptimizationVariableType.continuous,
}) => IntegerProgram(
  linearModel: LinearProgram(
    title: 'Test model',
    direction: ObjectiveDirection.maximize,
    variables: [
      DecisionVariable(id: 'x1', name: 'x1'),
      DecisionVariable(id: 'x2', name: 'x2'),
    ],
    objective: [3, 2],
    constraints: [
      LinearConstraint(
        id: 'c1',
        name: 'C1',
        coefficients: [1, 1],
        relation: ConstraintRelation.lessOrEqual,
        rhs: 4,
      ),
    ],
  ),
  variableTypes: {'x1': x1, 'x2': x2},
);

void main() {
  group('IntegerProgram validation', () {
    test('accepts a model with at least one integer variable', () {
      final program = _twoVarModel();
      expect(program.integerVariableCount, 1);
      expect(program.isIntegerOrBinary('x1'), isTrue);
      expect(program.isIntegerOrBinary('x2'), isFalse);
    });

    test('rejects a continuous-only model', () {
      expect(
        () => _twoVarModel(
          x1: OptimizationVariableType.continuous,
          x2: OptimizationVariableType.continuous,
        ),
        throwsFormatException,
      );
    });

    test('rejects a variable type map that does not match the model', () {
      expect(
        () => IntegerProgram(
          linearModel: LinearProgram(
            title: 'Mismatch',
            direction: ObjectiveDirection.maximize,
            variables: [DecisionVariable(id: 'x1', name: 'x1')],
            objective: [1],
            constraints: [
              LinearConstraint(
                id: 'c1',
                name: 'C1',
                coefficients: [1],
                relation: ConstraintRelation.lessOrEqual,
                rhs: 1,
              ),
            ],
          ),
          variableTypes: const {
            'x1': OptimizationVariableType.integer,
            'x2': OptimizationVariableType.integer,
          },
        ),
        throwsFormatException,
      );
    });

    test(
      'flags models above the recommended integer variable count without blocking',
      () {
        final variables = [
          for (var i = 0; i < 9; i++) DecisionVariable(id: 'x$i', name: 'x$i'),
        ];
        final program = IntegerProgram(
          linearModel: LinearProgram(
            title: 'Large',
            direction: ObjectiveDirection.maximize,
            variables: variables,
            objective: [for (var i = 0; i < 9; i++) 1.0],
            constraints: [
              LinearConstraint(
                id: 'c1',
                name: 'C1',
                coefficients: [for (var i = 0; i < 9; i++) 1.0],
                relation: ConstraintRelation.lessOrEqual,
                rhs: 5,
              ),
            ],
          ),
          variableTypes: {
            for (final v in variables) v.id: OptimizationVariableType.binary,
          },
        );
        expect(program.exceedsRecommendedIntegerCount, isTrue);
        expect(program.integerVariableCount, 9);
      },
    );
  });

  group('relaxationModel', () {
    test('leaves a model with no binary variables untouched', () {
      final program = _twoVarModel();
      expect(
        program.relaxationModel.constraints.length,
        program.linearModel.constraints.length,
      );
    });

    test('adds exactly one upper-bound constraint per binary variable', () {
      final program = _twoVarModel(
        x1: OptimizationVariableType.binary,
        x2: OptimizationVariableType.binary,
      );
      final relaxation = program.relaxationModel;
      expect(
        relaxation.constraints.length,
        program.linearModel.constraints.length + 2,
      );
      final added = relaxation.constraints.sublist(
        program.linearModel.constraints.length,
      );
      for (final constraint in added) {
        expect(constraint.relation, ConstraintRelation.lessOrEqual);
        expect(constraint.rhs, 1);
        expect(constraint.coefficients.where((c) => c == 1), hasLength(1));
      }
    });

    test('does not duplicate binary bounds across repeated calls', () {
      final program = _twoVarModel(x1: OptimizationVariableType.binary);
      final first = program.relaxationModel;
      final second = program.relaxationModel;
      expect(first.constraints.length, second.constraints.length);
      expect(
        first.constraints.length,
        program.linearModel.constraints.length + 1,
      );
    });
  });

  group('JSON round-trip', () {
    test('preserves the linear model and variable types', () {
      final program = _twoVarModel(
        x1: OptimizationVariableType.integer,
        x2: OptimizationVariableType.binary,
      );
      final decoded = IntegerProgram.fromJson(program.toJson());
      expect(decoded.title, program.title);
      expect(
        decoded.linearModel.variables.length,
        program.linearModel.variables.length,
      );
      expect(decoded.variableTypes, program.variableTypes);
      expect(decoded.linearModel.objective, program.linearModel.objective);
    });
  });
}

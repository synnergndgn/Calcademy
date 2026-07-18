import 'package:calcademy/features/integer_programming/domain/branching_strategy.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program.dart';
import 'package:calcademy/features/integer_programming/domain/optimization_variable_type.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:flutter_test/flutter_test.dart';

IntegerProgram _threeIntegerVars() => IntegerProgram(
  linearModel: LinearProgram(
    title: 'Branch test',
    direction: ObjectiveDirection.maximize,
    variables: [
      DecisionVariable(id: 'x1', name: 'x1'),
      DecisionVariable(id: 'x2', name: 'x2'),
      DecisionVariable(id: 'x3', name: 'x3'),
    ],
    objective: [1, 1, 1],
    constraints: [
      LinearConstraint(
        id: 'c1',
        name: 'C1',
        coefficients: [1, 1, 1],
        relation: ConstraintRelation.lessOrEqual,
        rhs: 10,
      ),
    ],
  ),
  variableTypes: const {
    'x1': OptimizationVariableType.integer,
    'x2': OptimizationVariableType.integer,
    'x3': OptimizationVariableType.integer,
  },
);

void main() {
  group('selectBranchVariable', () {
    test('firstFractional picks the lowest-index fractional variable', () {
      final program = _threeIntegerVars();
      final decision = selectBranchVariable(
        program: program,
        relaxationValues: {'x1': 2.5, 'x2': 1.1, 'x3': 3.9},
        strategy: BranchingStrategy.firstFractional,
      );
      expect(decision!.variableId, 'x1');
      expect(decision.floorValue, 2);
      expect(decision.ceilValue, 3);
    });

    test(
      'mostFractional picks the variable closest to a half-integer value',
      () {
        final program = _threeIntegerVars();
        final decision = selectBranchVariable(
          program: program,
          relaxationValues: {'x1': 2.9, 'x2': 1.5, 'x3': 3.1},
          strategy: BranchingStrategy.mostFractional,
        );
        expect(decision!.variableId, 'x2');
        expect(decision.fractionalValue, 1.5);
      },
    );

    test('breaks ties deterministically by variable order', () {
      final program = _threeIntegerVars();
      final decision = selectBranchVariable(
        program: program,
        relaxationValues: {'x1': 1.5, 'x2': 4.5, 'x3': 7.5},
        strategy: BranchingStrategy.mostFractional,
      );
      expect(decision!.variableId, 'x1');
    });

    test('never selects a variable that is already integer within epsilon', () {
      final program = _threeIntegerVars();
      final decision = selectBranchVariable(
        program: program,
        relaxationValues: {'x1': 2.0, 'x2': 3.0000000001, 'x3': 5.7},
        strategy: BranchingStrategy.mostFractional,
      );
      expect(decision!.variableId, 'x3');
    });

    test('returns null once every integer variable is integral', () {
      final program = _threeIntegerVars();
      final decision = selectBranchVariable(
        program: program,
        relaxationValues: {'x1': 2, 'x2': 3, 'x3': 5},
        strategy: BranchingStrategy.mostFractional,
      );
      expect(decision, isNull);
    });

    test('ignores continuous variables even when fractional', () {
      final program = IntegerProgram(
        linearModel: LinearProgram(
          title: 'Mixed',
          direction: ObjectiveDirection.maximize,
          variables: [
            DecisionVariable(id: 'x1', name: 'x1'),
            DecisionVariable(id: 'y1', name: 'y1'),
          ],
          objective: [1, 1],
          constraints: [
            LinearConstraint(
              id: 'c1',
              name: 'C1',
              coefficients: [1, 1],
              relation: ConstraintRelation.lessOrEqual,
              rhs: 10,
            ),
          ],
        ),
        variableTypes: const {
          'x1': OptimizationVariableType.continuous,
          'y1': OptimizationVariableType.integer,
        },
      );
      final decision = selectBranchVariable(
        program: program,
        relaxationValues: {'x1': 4.5, 'y1': 3},
        strategy: BranchingStrategy.mostFractional,
      );
      expect(decision, isNull);
    });
  });
}

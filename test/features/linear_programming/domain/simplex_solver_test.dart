import 'package:calcademy/features/linear_programming/domain/dual_builder.dart';
import 'package:calcademy/features/linear_programming/domain/graphical_solution.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program_result.dart';
import 'package:calcademy/features/linear_programming/domain/lp_examples.dart';
import 'package:calcademy/features/linear_programming/domain/simplex_solver.dart';
import 'package:calcademy/features/linear_programming/domain/standard_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('standardization', () {
    test('adds slack and selects primal simplex for <= models', () {
      final form = LinearProgramStandardizer().standardize(
        LpExamples.productMix,
      );
      expect(form.method, SimplexMethod.primal);
      expect(
        form.tableau.columnNames.where((name) => name.startsWith('s')),
        hasLength(3),
      );
      expect(form.artificialColumns, isEmpty);
    });

    test('adds surplus and artificial variables for >= models', () {
      final form = LinearProgramStandardizer().standardize(
        LpExamples.minimization,
      );
      expect(form.method, SimplexMethod.twoPhase);
      expect(form.artificialColumns, hasLength(2));
      expect(
        form.tableau.columnNames.where((name) => name.startsWith('e')),
        hasLength(2),
      );
    });

    test('flips negative RHS and relation', () {
      final program = _oneConstraint(
        [-1, 0],
        ConstraintRelation.lessOrEqual,
        -2,
      );
      final form = LinearProgramStandardizer().standardize(program);
      expect(form.method, SimplexMethod.twoPhase);
      expect(form.tableau.rows.first.last, 2);
      expect(form.steps.first, startsWith('lpNormalizeNegativeRhs'));
    });
  });

  group('simplex', () {
    test('solves product mix with primal simplex', () {
      final result =
          SimplexSolver().solve(LpExamples.productMix)
              as FeasibleLinearProgramResult;
      expect(result.status, LinearProgramStatus.optimal);
      expect(result.objectiveValue, closeTo(10, 1e-8));
      expect(result.variableValues['x1'], closeTo(2, 1e-8));
      expect(result.variableValues['x2'], closeTo(2, 1e-8));
      expect(result.method, SimplexMethod.primal);
    });

    test('solves minimization with two phases', () {
      final result =
          SimplexSolver().solve(LpExamples.minimization)
              as FeasibleLinearProgramResult;
      expect(result.objectiveValue, closeTo(8 / 3, 1e-8));
      expect(result.variableValues['x1'], closeTo(4 / 3, 1e-8));
      expect(result.variableValues['x2'], closeTo(4 / 3, 1e-8));
      expect(result.method, SimplexMethod.twoPhase);
      expect(
        result.iterations.any((item) => item.phase.name == 'phaseOne'),
        isTrue,
      );
      expect(
        result.iterations.any((item) => item.phase.name == 'phaseTwo'),
        isTrue,
      );
    });

    test('solves equality model', () {
      final result =
          SimplexSolver().solve(LpExamples.equality)
              as FeasibleLinearProgramResult;
      expect(result.objectiveValue, closeTo(7, 1e-8));
      expect(result.variableValues['x1'], closeTo(3, 1e-8));
      expect(result.variableValues['x2'], closeTo(1, 1e-8));
    });

    test('detects infeasible model', () {
      expect(
        SimplexSolver().solve(LpExamples.infeasible).status,
        LinearProgramStatus.infeasible,
      );
    });

    test('detects unbounded model', () {
      expect(
        SimplexSolver().solve(LpExamples.unbounded).status,
        LinearProgramStatus.unbounded,
      );
    });

    test('detects multiple optima', () {
      final result = SimplexSolver().solve(LpExamples.multiple);
      expect(result.status, LinearProgramStatus.multipleOptimal);
    });

    test('reports iteration limit deterministically', () {
      final result = SimplexSolver(
        maxIterations: 0,
      ).solve(LpExamples.productMix);
      expect(result.status, LinearProgramStatus.iterationLimit);
    });

    test('records pivots and complete tableaus', () {
      final result = SimplexSolver().solve(LpExamples.productMix);
      expect(result.iterations, isNotEmpty);
      expect(
        result.iterations.last.tableau.columnNames,
        containsAll(['x1', 'x2']),
      );
      expect(
        result.iterations.last.tableau.rows.last.length,
        result.iterations.last.tableau.columnNames.length + 1,
      );
    });
  });

  test('graphical solver finds corners and same optimum', () {
    final graph = GraphicalSolver().solve(LpExamples.productMix);
    expect(graph.status, LinearProgramStatus.optimal);
    expect(graph.corners, isNotEmpty);
    expect(graph.objectiveValue, closeTo(10, 1e-8));
    expect(graph.optimum!.x, closeTo(2, 1e-8));
    expect(graph.optimum!.y, closeTo(2, 1e-8));
  });

  test('dual builder transposes safe max model', () {
    final result =
        DualBuilder().build(LpExamples.productMix) as DualBuildSuccess;
    expect(result.program.direction, ObjectiveDirection.minimize);
    expect(result.program.objective, [4, 2, 3]);
    expect(result.program.constraints.first.coefficients, [1, 1, 0]);
    expect(
      result.program.constraints.first.relation,
      ConstraintRelation.greaterOrEqual,
    );
  });

  test('dual builder rejects unsupported form', () {
    expect(
      DualBuilder().build(LpExamples.minimization),
      isA<DualBuildUnsupported>(),
    );
  });

  test('domain JSON round trip and fraction parser preserve model', () {
    final decoded = LinearProgram.fromJson(LpExamples.productMix.toJson());
    expect(decoded.objective, [3, 2]);
    expect(decoded.constraints, hasLength(3));
    expect(parseLpNumber('-3/4'), closeTo(-.75, 1e-12));
  });

  test('2x3, 5x10 and 10x20 solves remain bounded for UI use', () {
    final solver = SimplexSolver();
    solver.solve(_boundedProgram(2, 3));
    final small = _measure(() => solver.solve(_boundedProgram(2, 3)));
    final medium = _measure(() => solver.solve(_boundedProgram(5, 10)));
    late LinearProgramResult result;
    final large = _measure(
      () => result = solver.solve(_boundedProgram(10, 20)),
    );
    // Captured during explicit profile verification.
    // ignore: avoid_print
    print('lp-performance-us 2x3=$small 5x10=$medium 10x20=$large');
    expect(
      result.status,
      anyOf(LinearProgramStatus.optimal, LinearProgramStatus.multipleOptimal),
    );
    expect(small, lessThan(1000000));
    expect(medium, lessThan(1000000));
    expect(large, lessThan(1000000));
  });
}

int _measure(void Function() action) {
  final stopwatch = Stopwatch()..start();
  action();
  stopwatch.stop();
  return stopwatch.elapsedMicroseconds;
}

LinearProgram _boundedProgram(int variableCount, int constraintCount) =>
    LinearProgram(
      title: '$variableCount x $constraintCount',
      direction: ObjectiveDirection.maximize,
      variables: [
        for (var index = 0; index < variableCount; index++)
          DecisionVariable(id: 'x$index', name: 'x${index + 1}'),
      ],
      objective: List.filled(variableCount, 1),
      constraints: [
        for (var row = 0; row < constraintCount; row++)
          LinearConstraint(
            id: 'c$row',
            name: 'C${row + 1}',
            coefficients: [
              for (var column = 0; column < variableCount; column++)
                column == row % variableCount ? 1 : 0,
            ],
            relation: ConstraintRelation.lessOrEqual,
            rhs: 10 + row.toDouble(),
          ),
      ],
    );

LinearProgram _oneConstraint(
  List<double> coefficients,
  ConstraintRelation relation,
  double rhs,
) => LinearProgram(
  title: 'Test',
  direction: ObjectiveDirection.maximize,
  variables: [
    DecisionVariable(id: 'x1', name: 'x1'),
    DecisionVariable(id: 'x2', name: 'x2'),
  ],
  objective: const [1, 1],
  constraints: [
    LinearConstraint(
      id: 'c1',
      name: 'C1',
      coefficients: coefficients,
      relation: relation,
      rhs: rhs,
    ),
  ],
);

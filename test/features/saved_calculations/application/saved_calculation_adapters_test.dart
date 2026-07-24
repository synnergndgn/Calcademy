import 'package:calcademy/features/equation_solver/application/linear_system_service.dart';
import 'package:calcademy/features/equation_solver/domain/equation_solver_result.dart';
import 'package:calcademy/features/graph/domain/graph_expression.dart';
import 'package:calcademy/features/graph/domain/graph_function.dart';
import 'package:calcademy/features/graph/domain/graph_range.dart';
import 'package:calcademy/features/history/domain/calculation_record.dart';
import 'package:calcademy/features/integer_programming/domain/branch_node.dart';
import 'package:calcademy/features/integer_programming/domain/branching_strategy.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program.dart';
import 'package:calcademy/features/integer_programming/domain/mip_result.dart';
import 'package:calcademy/features/integer_programming/domain/node_selection_strategy.dart';
import 'package:calcademy/features/integer_programming/domain/optimization_variable_type.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program_result.dart';
import 'package:calcademy/features/linear_programming/domain/standard_form.dart';
import 'package:calcademy/features/matrix/domain/linear_system_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_operation.dart';
import 'package:calcademy/features/matrix/domain/matrix_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_value.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/calculator_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/equation_solver_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/graph_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/matrix_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/optimization_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/application/saved_calculations_service.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_failure.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_limits.dart';
import 'package:calcademy/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('equation adapter', () {
    test('builds a single-root summary', () {
      final draft = EquationSolverSavedAdapter.single(
        equation: 'x - 2 = 0',
        result: EquationRootsFound(
          method: EquationSolveMethod.analyticLinear,
          roots: const [EquationRoot(value: 2, residual: 0, exact: true)],
        ),
      );

      expect(draft.module, SavedCalculationModule.equationSolver);
      expect(draft.resultSummary, contains('roots: 2'));
      expect(draft.resultJson['roots'], [2.0]);
    });

    test('builds a numerical-method summary', () {
      final draft = EquationSolverSavedAdapter.numerical(
        function: 'x^2 - 2',
        initialValues: const [1, 2],
        result: const NumericalMethodResult(
          method: EquationSolveMethod.bisection,
          converged: true,
          iterations: 30,
          root: 1.41421356,
          residual: 1e-10,
        ),
      );

      expect(draft.calculationType, 'numericalMethod');
      expect(draft.resultSummary, contains('iterations: 30'));
    });

    test('builds a linear-system summary without storing its matrix', () {
      final draft = EquationSolverSavedAdapter.linearSystem(
        dimension: 2,
        result: LinearSystemSolved(
          UniqueSolution(
            const [1, 2],
            MatrixValue(const [
              [1, 0, 1],
              [0, 1, 2],
            ]),
          ),
        ),
      );

      expect(draft.resultSummary, contains('unique solution'));
      expect(draft.fullInputJson, {'dimension': 2});
      expect(draft.resultJson, isNot(contains('reducedMatrix')));
    });

    test('rejects an unsupported failed result', () {
      expect(
        () => EquationSolverSavedAdapter.single(
          equation: 'bad',
          result: EquationSolveFailure(
            method: EquationSolveMethod.scanAndBisect,
            failure: EquationFailure.invalidSyntax,
          ),
        ),
        throwsA(
          isA<SavedCalculationsException>().having(
            (error) => error.issue,
            'issue',
            SavedCalculationsIssue.invalidPayload,
          ),
        ),
      );
    });
  });

  group('matrix adapter', () {
    test('builds a scalar result summary', () {
      final draft = MatrixSavedAdapter.fromExecution(
        MatrixExecution(
          operation: MatrixOperationType.determinant,
          inputs: [
            MatrixValue(const [
              [1, 2],
              [3, 4],
            ]),
          ],
          result: const ScalarMatrixResult(-2),
        ),
      );

      expect(draft.module, SavedCalculationModule.matrix);
      expect(draft.resultJson['value'], -2);
      expect(draft.fullInputJson['inputs'], [
        {
          'rows': 2,
          'columns': 2,
          'values': [
            [1.0, 2.0],
            [3.0, 4.0],
          ],
        },
      ]);
    });

    test('truncates a large matrix preview at the central limit', () {
      final matrix = MatrixValue([
        for (var row = 0; row < 4; row++)
          [for (var column = 0; column < 4; column++) row * 4.0 + column],
      ]);
      final draft = MatrixSavedAdapter.fromExecution(
        MatrixExecution(
          operation: MatrixOperationType.transpose,
          inputs: [matrix],
          result: MatrixResultValue(matrix),
        ),
      );

      expect(
        draft.resultJson['preview'],
        hasLength(SavedCalculationsLimits.maxMatrixPreviewCells),
      );
      expect(draft.resultJson['truncated'], isTrue);
      expect(draft.resultSummary, contains('…'));
    });
  });

  group('optimization adapters', () {
    test('builds a compact LP result', () {
      final program = _linearProgram();
      final draft = OptimizationSavedAdapter.linear(
        program,
        FeasibleLinearProgramResult(
          status: LinearProgramStatus.optimal,
          method: SimplexMethod.primal,
          iterationCount: 2,
          iterations: const [],
          standardizationSteps: const [],
          objectiveValue: 10,
          variableValues: const {'x1': 2, 'x2': 2},
          constraintAnalysis: const [],
          basicVariables: const [],
          reducedCosts: const {},
          degenerate: false,
        ),
      );

      expect(draft.module, SavedCalculationModule.linearProgramming);
      expect(draft.resultSummary, contains('z = 10'));
      expect(draft.fullInputJson, isNot(contains('constraints')));
    });

    test('builds a compact IP result without its branch tree', () {
      final model = _linearProgram();
      final program = IntegerProgram(
        linearModel: model,
        variableTypes: const {
          'x1': OptimizationVariableType.integer,
          'x2': OptimizationVariableType.binary,
        },
      );
      final result = OptimalIntegerSolution(
        rootRelaxationObjective: 11,
        nodesSolved: 3,
        openNodes: 0,
        maxDepthReached: 1,
        pruneCounts: const {PruneReason.integral: 1},
        branchTree: const [],
        incumbentHistory: const [],
        branchingStrategy: BranchingStrategy.firstFractional,
        nodeSelectionStrategy: NodeSelectionStrategy.depthFirst,
        elapsedMicroseconds: 20,
        warnings: const [],
        objectiveValue: 10,
        variableValues: const {'x1': 2, 'x2': 1},
      );
      final draft = OptimizationSavedAdapter.integer(program, result);

      expect(draft.module, SavedCalculationModule.integerProgramming);
      expect(draft.resultJson, isNot(contains('branchTree')));
      expect(draft.resultSummary, contains('optimal'));
    });
  });

  test('calculator adapter stores expression, result, mode and timestamp', () {
    final draft = CalculatorSavedAdapter.fromRecord(
      CalculationRecord(
        id: '1',
        expression: 'sin(30)',
        result: '0.5',
        createdAt: DateTime.utc(2026, 7, 20),
        angleMode: AngleMode.degrees,
      ),
    );

    expect(draft.module, SavedCalculationModule.scientificCalculator);
    expect(draft.resultSummary, 'sin(30) = 0.5');
    expect(draft.fullInputJson['angleMode'], 'degrees');
  });

  test('graph adapter stores configuration but no sampled points', () {
    final draft = GraphSavedAdapter.tryBuild(
      functions: const [
        GraphFunction(id: '1', expression: 'x^2', visualIndex: 0),
      ],
      xRange: const GraphRange(min: -5, max: 5),
      autoY: true,
      manualYMin: -10,
      manualYMax: 10,
      angleMode: GraphAngleMode.radians,
    )!;

    expect(draft.module, SavedCalculationModule.graphPlotter);
    expect(draft.fullInputJson['expressions'], ['x^2']);
    expect(draft.fullInputJson, isNot(contains('series')));
  });

  test('central payload guard rejects an oversized adapter payload', () {
    final oversized = 'x' * SavedCalculationsLimits.maxStoredPayloadBytes;
    expect(
      () => SavedCalculationsService().create(
        SavedCalculationDraft(
          title: 'Oversized',
          module: SavedCalculationModule.matrix,
          calculationType: 'test',
          inputSummary: 'input',
          resultSummary: 'result',
          resultJson: {'preview': oversized},
        ),
      ),
      throwsA(
        isA<SavedCalculationsException>().having(
          (error) => error.issue,
          'issue',
          SavedCalculationsIssue.payloadTooLarge,
        ),
      ),
    );
  });

  test('service rejects unknown modules and non-finite JSON values', () {
    final service = SavedCalculationsService();
    SavedCalculationDraft draft({
      SavedCalculationModule module = SavedCalculationModule.matrix,
      Object? value = 1,
    }) => SavedCalculationDraft(
      title: 'Invalid',
      module: module,
      calculationType: 'test',
      inputSummary: 'input',
      resultSummary: 'result',
      resultJson: {'value': value},
    );

    expect(
      () => service.create(draft(module: SavedCalculationModule.unknown)),
      throwsA(
        isA<SavedCalculationsException>().having(
          (error) => error.issue,
          'issue',
          SavedCalculationsIssue.unknownModule,
        ),
      ),
    );
    expect(
      () => service.create(draft(value: double.infinity)),
      throwsA(
        isA<SavedCalculationsException>().having(
          (error) => error.issue,
          'issue',
          SavedCalculationsIssue.invalidPayload,
        ),
      ),
    );
  });
}

LinearProgram _linearProgram() => LinearProgram(
  title: 'Example optimization',
  direction: ObjectiveDirection.maximize,
  variables: [
    DecisionVariable(id: 'x1', name: 'x1'),
    DecisionVariable(id: 'x2', name: 'x2'),
  ],
  objective: const [3, 2],
  constraints: [
    LinearConstraint(
      id: 'c1',
      name: 'c1',
      coefficients: const [1, 1],
      relation: ConstraintRelation.lessOrEqual,
      rhs: 4,
    ),
  ],
);

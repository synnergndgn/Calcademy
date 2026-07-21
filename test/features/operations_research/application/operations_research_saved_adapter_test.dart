import 'package:calcademy/features/operations_research/application/assignment_solver.dart';
import 'package:calcademy/features/operations_research/application/transportation_solver.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_problem.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/operations_research_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_limits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a compact transportation draft', () {
    final result =
        const TransportationSolver().solve(
              TransportationProblem(
                costs: const [
                  [1, 4],
                  [3, 1],
                ],
                supply: const [5, 5],
                demand: const [5, 5],
              ),
            )
            as TransportationResult;
    final draft = OperationsResearchSavedAdapter.transportation(result);

    expect(draft.module, SavedCalculationModule.operationsResearch);
    expect(draft.calculationType, 'transportation');
    expect(draft.resultSummary, contains('total 10'));
    expect(draft.resultJson, isNot(contains('allocations')));
  });

  test('builds a compact assignment draft', () {
    final result =
        const AssignmentSolver().solve(
              AssignmentProblem(
                values: const [
                  [5, 1],
                  [2, 4],
                ],
              ),
            )
            as AssignmentResult;
    final draft = OperationsResearchSavedAdapter.assignment(result);

    expect(draft.module, SavedCalculationModule.operationsResearch);
    expect(draft.calculationType, 'assignment');
    expect(draft.resultSummary, contains('total 3'));
  });

  test('truncates a large allocation payload preview', () {
    final result = TransportationResult(
      objective: OperationsResearchObjective.minimize,
      initialMethod: TransportationInitialMethod.leastCost,
      allocations: [
        for (var row = 0; row < 8; row++)
          [for (var column = 0; column < 8; column++) 1],
      ],
      totalValue: 64,
      originalSourceCount: 8,
      originalDestinationCount: 8,
      balancedSourceCount: 8,
      balancedDestinationCount: 8,
      totalSupply: 64,
      totalDemand: 64,
      isOptimal: true,
      isInitialOnly: false,
      iterations: 1,
      degenerate: false,
      warnings: const [],
    );
    final draft = OperationsResearchSavedAdapter.transportation(result);

    expect(
      draft.resultJson['allocationPreview'],
      hasLength(SavedCalculationsLimits.maxMatrixPreviewCells),
    );
    expect(draft.resultJson['previewTruncated'], isTrue);
  });

  test('module registry exposes the OR identity and route', () {
    expect(
      SavedCalculationModule.fromId('operations-research'),
      SavedCalculationModule.operationsResearch,
    );
    expect(
      SavedCalculationModule.operationsResearch.route,
      '/operations-research',
    );
  });
}

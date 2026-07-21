import 'package:calcademy/features/operations_research/application/transportation_solver.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_problem.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const solver = TransportationSolver();

  test('North-West Corner builds the known feasible solution', () {
    final initial = solver.buildInitial(
      _problem(TransportationInitialMethod.northWestCorner),
    );

    expect(initial.allocations, [
      [10, 10, 0],
      [0, 15, 15],
    ]);
    expect(initial.value, 230);
  });

  test('Least Cost builds the known feasible solution', () {
    final initial = solver.buildInitial(
      _problem(TransportationInitialMethod.leastCost),
    );

    expect(initial.allocations, [
      [5, 0, 15],
      [5, 25, 0],
    ]);
    expect(initial.value, 150);
  });

  test('MODI improves North-West solution and proves the optimum', () {
    final result =
        solver.solve(_problem(TransportationInitialMethod.northWestCorner))
            as TransportationResult;

    expect(result.totalValue, closeTo(150, 1e-8));
    expect(result.isOptimal, isTrue);
    expect(result.isInitialOnly, isFalse);
    expect(result.iterations, greaterThan(0));
  });

  test('adds a dummy destination when supply exceeds demand', () {
    final result =
        solver.solve(
              TransportationProblem(
                costs: const [
                  [2, 4],
                  [3, 1],
                ],
                supply: const [10, 10],
                demand: const [8, 7],
              ),
            )
            as TransportationResult;

    expect(result.dummyDestinationIndex, 2);
    expect(result.balancedDestinationCount, 3);
    expect(result.warnings, contains('orWarningDummyDestination'));
    for (var row = 0; row < result.allocations.length; row++) {
      expect(result.allocations[row].fold<double>(0, (a, b) => a + b), 10);
    }
  });

  test('adds a dummy source when demand exceeds supply', () {
    final result =
        solver.solve(
              TransportationProblem(
                costs: const [
                  [2, 4],
                  [3, 1],
                ],
                supply: const [5, 5],
                demand: const [8, 7],
              ),
            )
            as TransportationResult;

    expect(result.dummySourceIndex, 2);
    expect(result.balancedSourceCount, 3);
    expect(result.warnings, contains('orWarningDummySource'));
  });

  test('maximizes profit through a safe cost transformation', () {
    final result =
        solver.solve(
              TransportationProblem(
                costs: const [
                  [8, 6],
                  [4, 9],
                ],
                supply: const [10, 10],
                demand: const [10, 10],
                objective: OperationsResearchObjective.maximize,
                initialMethod: TransportationInitialMethod.northWestCorner,
              ),
            )
            as TransportationResult;

    expect(result.totalValue, 170);
    expect(result.isOptimal, isTrue);
  });

  test('returns typed validation failures', () {
    final negative =
        solver.solve(
              TransportationProblem(
                costs: const [
                  [1, 2],
                  [3, 4],
                ],
                supply: const [-1, 2],
                demand: const [1, 1],
              ),
            )
            as OperationsResearchFailureResult;
    final dimensions =
        solver.solve(
              TransportationProblem(
                costs: const [
                  [1, 2],
                  [3],
                ],
                supply: const [1, 1],
                demand: const [1, 1],
              ),
            )
            as OperationsResearchFailureResult;
    final zero =
        solver.solve(
              TransportationProblem(
                costs: const [
                  [1, 2],
                  [3, 4],
                ],
                supply: const [0, 0],
                demand: const [1, 1],
              ),
            )
            as OperationsResearchFailureResult;

    expect(negative.issue, OperationsResearchIssue.negativeSupply);
    expect(dimensions.issue, OperationsResearchIssue.invalidDimensions);
    expect(zero.issue, OperationsResearchIssue.zeroSupply);
  });
}

TransportationProblem _problem(TransportationInitialMethod method) =>
    TransportationProblem(
      costs: const [
        [2, 3, 1],
        [5, 4, 8],
      ],
      supply: const [20, 30],
      demand: const [10, 25, 15],
      initialMethod: method,
    );

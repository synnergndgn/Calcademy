import 'package:calcademy/features/operations_research/application/assignment_solver.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_problem.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const solver = AssignmentSolver();

  test('solves a known square minimization problem', () {
    final result =
        solver.solve(
              AssignmentProblem(
                values: const [
                  [9, 2, 7],
                  [6, 4, 3],
                  [5, 8, 1],
                ],
              ),
            )
            as AssignmentResult;

    expect(result.totalValue, 9);
    expect(
      result.assignments
          .where((item) => !item.isDummy)
          .map((item) => (item.row, item.column)),
      containsAll([(0, 1), (1, 0), (2, 2)]),
    );
    expect(result.methodName, 'Hungarian algorithm');
  });

  test('pads a rectangular minimization problem with a dummy row', () {
    final result =
        solver.solve(
              AssignmentProblem(
                values: const [
                  [4, 1, 3],
                  [2, 0, 5],
                ],
              ),
            )
            as AssignmentResult;

    expect(result.totalValue, 3);
    expect(result.balancedSize, 3);
    expect(result.hasDummyAssignments, isTrue);
    expect(result.warnings, contains('orWarningRectangular'));
    expect(result.warnings, contains('orWarningDummyAssignment'));
  });

  test('pads a rectangular minimization problem with a dummy column', () {
    final result =
        solver.solve(
              AssignmentProblem(
                values: const [
                  [1, 9],
                  [8, 2],
                  [4, 5],
                ],
              ),
            )
            as AssignmentResult;

    expect(result.totalValue, 3);
    expect(result.balancedSize, 3);
    expect(result.hasDummyAssignments, isTrue);
    expect(result.assignments.where((item) => item.isDummy), hasLength(1));
  });

  test('solves a maximization problem using original profits', () {
    final result =
        solver.solve(
              AssignmentProblem(
                values: const [
                  [5, 9],
                  [10, 3],
                ],
                objective: OperationsResearchObjective.maximize,
              ),
            )
            as AssignmentResult;

    expect(result.totalValue, 19);
    expect(result.objective, OperationsResearchObjective.maximize);
  });

  test('supports finite negative values', () {
    final result =
        solver.solve(
              AssignmentProblem(
                values: const [
                  [-1, 2],
                  [3, -4],
                ],
              ),
            )
            as AssignmentResult;

    expect(result.totalValue, -5);
  });

  test('returns typed invalid-dimension and invalid-value failures', () {
    final dimensions =
        solver.solve(
              AssignmentProblem(
                values: const [
                  [1, 2],
                  [3],
                ],
              ),
            )
            as OperationsResearchFailureResult;
    final number =
        solver.solve(
              AssignmentProblem(
                values: const [
                  [1, double.infinity],
                  [3, 4],
                ],
              ),
            )
            as OperationsResearchFailureResult;

    expect(dimensions.issue, OperationsResearchIssue.invalidDimensions);
    expect(number.issue, OperationsResearchIssue.invalidNumber);
  });
}

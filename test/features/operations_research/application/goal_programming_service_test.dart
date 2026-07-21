import 'package:calcademy/features/operations_research/application/goal_programming_service.dart';
import 'package:calcademy/features/operations_research/domain/goal_programming_problem.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_limits.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = GoalProgrammingService();

  test('solves a simple weighted equality goal', () {
    final result =
        service.solve(
              GoalProgrammingProblem(
                variableCount: 1,
                hardConstraints: const [],
                goals: [_goal(target: 10, under: 1, over: 1)],
              ),
            )
            as GoalProgrammingResult;

    expect(result.totalWeightedDeviation, closeTo(0, 1e-9));
    expect(result.decisionVariables['x1'], closeTo(10, 1e-9));
    expect(result.deviations.single.satisfied, isTrue);
  });

  test('an at-least goal penalizes under-achievement', () {
    final result =
        service.solve(
              GoalProgrammingProblem(
                variableCount: 1,
                hardConstraints: [_hard(GoalConstraintRelation.lessOrEqual, 5)],
                goals: [
                  _goal(
                    relation: GoalTargetRelation.atLeast,
                    target: 10,
                    under: 1,
                  ),
                ],
              ),
            )
            as GoalProgrammingResult;

    expect(result.decisionVariables['x1'], closeTo(5, 1e-9));
    expect(result.deviations.single.under, closeTo(5, 1e-9));
    expect(result.totalWeightedDeviation, closeTo(5, 1e-9));
  });

  test('an at-most goal penalizes over-achievement', () {
    final result =
        service.solve(
              GoalProgrammingProblem(
                variableCount: 1,
                hardConstraints: [
                  _hard(GoalConstraintRelation.greaterOrEqual, 8),
                ],
                goals: [
                  _goal(
                    relation: GoalTargetRelation.atMost,
                    target: 5,
                    over: 2,
                  ),
                ],
              ),
            )
            as GoalProgrammingResult;

    expect(result.decisionVariables['x1'], closeTo(8, 1e-9));
    expect(result.deviations.single.over, closeTo(3, 1e-9));
    expect(result.totalWeightedDeviation, closeTo(6, 1e-9));
  });

  test('an equality goal uses its weighted deviation', () {
    final result =
        service.solve(
              GoalProgrammingProblem(
                variableCount: 1,
                hardConstraints: [_hard(GoalConstraintRelation.lessOrEqual, 4)],
                goals: [_goal(target: 6, under: 2, over: 3)],
              ),
            )
            as GoalProgrammingResult;

    expect(result.deviations.single.under, closeTo(2, 1e-9));
    expect(result.deviations.single.over, closeTo(0, 1e-9));
    expect(result.totalWeightedDeviation, closeTo(4, 1e-9));
  });

  test('respects hard constraints and reports infeasibility', () {
    final feasible =
        service.solve(
              GoalProgrammingProblem(
                variableCount: 1,
                hardConstraints: [_hard(GoalConstraintRelation.lessOrEqual, 3)],
                goals: [_goal(target: 10, under: 1)],
              ),
            )
            as GoalProgrammingResult;
    final infeasible =
        service.solve(
              GoalProgrammingProblem(
                variableCount: 1,
                hardConstraints: [
                  _hard(GoalConstraintRelation.lessOrEqual, 1),
                  _hard(GoalConstraintRelation.greaterOrEqual, 2),
                ],
                goals: [_goal(target: 1, under: 1)],
              ),
            )
            as OperationsResearchFailureResult;

    expect(feasible.decisionVariables['x1'], closeTo(3, 1e-9));
    expect(feasible.hardConstraintsSatisfied, isTrue);
    expect(infeasible.issue, OperationsResearchIssue.infeasible);
  });

  test('validates negative and all-zero weights', () {
    final negative =
        service.solve(
              GoalProgrammingProblem(
                variableCount: 1,
                hardConstraints: const [],
                goals: [_goal(target: 1, under: -1)],
              ),
            )
            as OperationsResearchFailureResult;
    final zero =
        service.solve(
              GoalProgrammingProblem(
                variableCount: 1,
                hardConstraints: const [],
                goals: [_goal(target: 1)],
              ),
            )
            as OperationsResearchFailureResult;

    expect(negative.issue, OperationsResearchIssue.invalidWeight);
    expect(zero.issue, OperationsResearchIssue.allGoalWeightsZero);
  });

  test('rejects a model above the central variable limit', () {
    final result =
        service.solve(
              GoalProgrammingProblem(
                variableCount: OperationsResearchLimits.maxGoalVariables + 1,
                hardConstraints: const [],
                goals: [
                  GoalTarget(
                    coefficients: List.filled(
                      OperationsResearchLimits.maxGoalVariables + 1,
                      1,
                    ),
                    relation: GoalTargetRelation.equal,
                    target: 1,
                    underWeight: 1,
                    overWeight: 1,
                  ),
                ],
              ),
            )
            as OperationsResearchFailureResult;

    expect(result.issue, OperationsResearchIssue.tooLarge);
  });
}

GoalHardConstraint _hard(GoalConstraintRelation relation, double rhs) =>
    GoalHardConstraint(coefficients: const [1], relation: relation, rhs: rhs);

GoalTarget _goal({
  GoalTargetRelation relation = GoalTargetRelation.equal,
  double target = 0,
  double under = 0,
  double over = 0,
}) => GoalTarget(
  coefficients: const [1],
  relation: relation,
  target: target,
  underWeight: under,
  overWeight: over,
);

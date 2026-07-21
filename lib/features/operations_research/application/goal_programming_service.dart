import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program_result.dart';
import 'package:calcademy/features/linear_programming/domain/simplex_solver.dart';
import 'package:calcademy/features/operations_research/domain/goal_programming_problem.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_limits.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';

class GoalProgrammingService {
  const GoalProgrammingService({this.solver = const SimplexSolver()});

  final SimplexSolver solver;

  OperationsResearchResult solve(GoalProgrammingProblem problem) {
    final issue = _validate(problem);
    if (issue != null) return OperationsResearchFailureResult(issue);
    try {
      final program = _buildLinearProgram(problem);
      final lpResult = solver.solve(program);
      if (lpResult is! FeasibleLinearProgramResult) {
        return OperationsResearchFailureResult(switch (lpResult.status) {
          LinearProgramStatus.infeasible => OperationsResearchIssue.infeasible,
          LinearProgramStatus.unbounded =>
            OperationsResearchIssue.goalUnbounded,
          LinearProgramStatus.iterationLimit =>
            OperationsResearchIssue.iterationLimit,
          _ => OperationsResearchIssue.solverFailure,
        });
      }
      final decisions = <String, double>{
        for (var index = 0; index < problem.variableCount; index++)
          'x${index + 1}': lpResult.variableValues['x${index + 1}'] ?? 0,
      };
      final deviations = <GoalDeviation>[];
      for (var index = 0; index < problem.goals.length; index++) {
        final goal = problem.goals[index];
        final under = lpResult.variableValues['d${index + 1}_minus'] ?? 0;
        final over = lpResult.variableValues['d${index + 1}_plus'] ?? 0;
        final contribution = goal.underWeight * under + goal.overWeight * over;
        final satisfied = switch (goal.relation) {
          GoalTargetRelation.equal =>
            under <= OperationsResearchLimits.tolerance &&
                over <= OperationsResearchLimits.tolerance,
          GoalTargetRelation.atLeast =>
            under <= OperationsResearchLimits.tolerance,
          GoalTargetRelation.atMost =>
            over <= OperationsResearchLimits.tolerance,
        };
        deviations.add(
          GoalDeviation(
            goalIndex: index,
            relation: goal.relation,
            under: under,
            over: over,
            weightedContribution: contribution,
            satisfied: satisfied,
          ),
        );
      }
      final multiple = lpResult.status == LinearProgramStatus.multipleOptimal;
      return GoalProgrammingResult(
        totalWeightedDeviation: lpResult.objectiveValue,
        decisionVariables: decisions,
        deviations: deviations,
        hardConstraintCount: problem.hardConstraints.length,
        goalCount: problem.goals.length,
        hardConstraintsSatisfied: true,
        status: multiple
            ? GoalProgrammingStatus.multipleOptimal
            : GoalProgrammingStatus.optimal,
        iterations: lpResult.iterationCount,
        warnings: [if (multiple) 'orWarningMultipleOptimal'],
      );
    } on Object {
      return const OperationsResearchFailureResult(
        OperationsResearchIssue.solverFailure,
      );
    }
  }

  OperationsResearchIssue? _validate(GoalProgrammingProblem problem) {
    if (problem.variableCount < OperationsResearchLimits.minGoalVariables) {
      return OperationsResearchIssue.invalidGoalVariableCount;
    }
    if (problem.variableCount > OperationsResearchLimits.maxGoalVariables) {
      return OperationsResearchIssue.tooLarge;
    }
    if (problem.hardConstraints.length <
        OperationsResearchLimits.minHardConstraints) {
      return OperationsResearchIssue.invalidHardConstraintCount;
    }
    if (problem.hardConstraints.length >
        OperationsResearchLimits.maxHardConstraints) {
      return OperationsResearchIssue.tooLarge;
    }
    if (problem.goals.length < OperationsResearchLimits.minGoals) {
      return OperationsResearchIssue.invalidGoalCount;
    }
    if (problem.goals.length > OperationsResearchLimits.maxGoals) {
      return OperationsResearchIssue.tooLarge;
    }
    for (final constraint in problem.hardConstraints) {
      if (constraint.coefficients.length != problem.variableCount) {
        return OperationsResearchIssue.invalidDimensions;
      }
      if (!constraint.rhs.isFinite ||
          constraint.coefficients.any((value) => !value.isFinite)) {
        return OperationsResearchIssue.invalidNumber;
      }
    }
    var hasPositiveWeight = false;
    for (final goal in problem.goals) {
      if (goal.coefficients.length != problem.variableCount) {
        return OperationsResearchIssue.invalidDimensions;
      }
      if (!goal.target.isFinite ||
          goal.coefficients.any((value) => !value.isFinite)) {
        return OperationsResearchIssue.invalidNumber;
      }
      if (!goal.underWeight.isFinite ||
          !goal.overWeight.isFinite ||
          goal.underWeight < 0 ||
          goal.overWeight < 0) {
        return OperationsResearchIssue.invalidWeight;
      }
      hasPositiveWeight |= goal.underWeight > 0 || goal.overWeight > 0;
    }
    return hasPositiveWeight
        ? null
        : OperationsResearchIssue.allGoalWeightsZero;
  }

  LinearProgram _buildLinearProgram(GoalProgrammingProblem problem) {
    final transformedCount = problem.variableCount + problem.goals.length * 2;
    final variables = <DecisionVariable>[
      for (var index = 0; index < problem.variableCount; index++)
        DecisionVariable(id: 'x${index + 1}', name: 'x${index + 1}'),
      for (var index = 0; index < problem.goals.length; index++) ...[
        DecisionVariable(
          id: 'd${index + 1}_minus',
          name: 'd${index + 1}_minus',
        ),
        DecisionVariable(id: 'd${index + 1}_plus', name: 'd${index + 1}_plus'),
      ],
    ];
    final objective = List<double>.filled(transformedCount, 0);
    for (var index = 0; index < problem.goals.length; index++) {
      objective[problem.variableCount + index * 2] =
          problem.goals[index].underWeight;
      objective[problem.variableCount + index * 2 + 1] =
          problem.goals[index].overWeight;
    }
    final constraints = <LinearConstraint>[];
    for (var index = 0; index < problem.hardConstraints.length; index++) {
      final constraint = problem.hardConstraints[index];
      constraints.add(
        LinearConstraint(
          id: 'hard-${index + 1}',
          name: 'H${index + 1}',
          coefficients: [
            ...constraint.coefficients,
            ...List<double>.filled(problem.goals.length * 2, 0),
          ],
          relation: switch (constraint.relation) {
            GoalConstraintRelation.lessOrEqual =>
              ConstraintRelation.lessOrEqual,
            GoalConstraintRelation.equal => ConstraintRelation.equal,
            GoalConstraintRelation.greaterOrEqual =>
              ConstraintRelation.greaterOrEqual,
          },
          rhs: constraint.rhs,
        ),
      );
    }
    for (var index = 0; index < problem.goals.length; index++) {
      final goal = problem.goals[index];
      final coefficients = List<double>.filled(transformedCount, 0);
      for (var variable = 0; variable < problem.variableCount; variable++) {
        coefficients[variable] = goal.coefficients[variable];
      }
      coefficients[problem.variableCount + index * 2] = 1;
      coefficients[problem.variableCount + index * 2 + 1] = -1;
      constraints.add(
        LinearConstraint(
          id: 'goal-${index + 1}',
          name: 'G${index + 1}',
          coefficients: coefficients,
          relation: ConstraintRelation.equal,
          rhs: goal.target,
        ),
      );
    }
    return LinearProgram.unchecked(
      title: 'Weighted Goal Programming',
      direction: ObjectiveDirection.minimize,
      variables: variables,
      objective: objective,
      constraints: constraints,
    );
  }
}

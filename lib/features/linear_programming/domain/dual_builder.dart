import 'package:calcademy/features/linear_programming/domain/linear_program.dart';

sealed class DualBuildResult {
  const DualBuildResult();
}

class DualBuildSuccess extends DualBuildResult {
  const DualBuildSuccess(this.program);
  final LinearProgram program;
}

class DualBuildUnsupported extends DualBuildResult {
  const DualBuildUnsupported(this.reason);
  final String reason;
}

class DualBuilder {
  const DualBuilder();

  DualBuildResult build(LinearProgram primal) {
    if (primal.direction != ObjectiveDirection.maximize ||
        primal.constraints.any(
          (item) => item.relation != ConstraintRelation.lessOrEqual,
        )) {
      return const DualBuildUnsupported(
        'Only max models with <= constraints and nonnegative variables are supported.',
      );
    }
    return DualBuildSuccess(
      LinearProgram(
        title: '${primal.title} - Dual',
        direction: ObjectiveDirection.minimize,
        variables: [
          for (var row = 0; row < primal.constraints.length; row++)
            DecisionVariable(id: 'y${row + 1}', name: 'y${row + 1}'),
        ],
        objective: primal.constraints.map((item) => item.rhs).toList(),
        constraints: [
          for (var column = 0; column < primal.variables.length; column++)
            LinearConstraint(
              id: 'dual-c${column + 1}',
              name: 'D${column + 1}',
              coefficients: [
                for (final row in primal.constraints) row.coefficients[column],
              ],
              relation: ConstraintRelation.greaterOrEqual,
              rhs: primal.objective[column],
            ),
        ],
      ),
    );
  }
}

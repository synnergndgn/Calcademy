import 'dart:collection';

import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/features/linear_programming/domain/simplex_tableau.dart';

enum SimplexMethod { primal, twoPhase }

class StandardForm {
  StandardForm({
    required this.program,
    required this.tableau,
    required Set<int> artificialColumns,
    required this.method,
    required List<String> steps,
  }) : artificialColumns = UnmodifiableSetView(artificialColumns),
       steps = UnmodifiableListView(steps);

  final LinearProgram program;
  final SimplexTableau tableau;
  final Set<int> artificialColumns;
  final SimplexMethod method;
  final List<String> steps;
}

class LinearProgramStandardizer {
  const LinearProgramStandardizer();

  StandardForm standardize(LinearProgram program) {
    final normalized = <LinearConstraint>[];
    final steps = <String>[];
    for (final constraint in program.constraints) {
      var coefficients = constraint.coefficients.toList();
      var rhs = constraint.rhs;
      var relation = constraint.relation;
      if (rhs < 0) {
        coefficients = coefficients.map((value) => -value).toList();
        rhs = -rhs;
        relation = switch (relation) {
          ConstraintRelation.lessOrEqual => ConstraintRelation.greaterOrEqual,
          ConstraintRelation.greaterOrEqual => ConstraintRelation.lessOrEqual,
          ConstraintRelation.equal => ConstraintRelation.equal,
        };
        steps.add('lpNormalizeNegativeRhs|${constraint.name}');
      }
      normalized.add(
        LinearConstraint(
          id: constraint.id,
          name: constraint.name,
          coefficients: coefficients,
          relation: relation,
          rhs: rhs,
        ),
      );
    }

    final columns = program.variables.map((item) => item.name).toList();
    final extras = <List<double>>[for (final _ in normalized) <double>[]];
    final basis = <int>[];
    final artificial = <int>{};
    var slack = 0;
    var surplus = 0;
    var art = 0;

    void addColumn(String name, int rowIndex, double value) {
      columns.add(name);
      for (var row = 0; row < extras.length; row++) {
        extras[row].add(row == rowIndex ? value : 0);
      }
    }

    for (var row = 0; row < normalized.length; row++) {
      switch (normalized[row].relation) {
        case ConstraintRelation.lessOrEqual:
          addColumn('s${++slack}', row, 1);
          basis.add(columns.length - 1);
          steps.add('lpAddSlack|${normalized[row].name}|s$slack');
        case ConstraintRelation.greaterOrEqual:
          addColumn('e${++surplus}', row, -1);
          addColumn('a${++art}', row, 1);
          basis.add(columns.length - 1);
          artificial.add(columns.length - 1);
          steps.add(
            'lpAddSurplusArtificial|${normalized[row].name}|e$surplus|a$art',
          );
        case ConstraintRelation.equal:
          addColumn('a${++art}', row, 1);
          basis.add(columns.length - 1);
          artificial.add(columns.length - 1);
          steps.add('lpAddArtificial|${normalized[row].name}|a$art');
      }
    }

    final rows = <List<double>>[];
    for (var index = 0; index < normalized.length; index++) {
      rows.add([
        ...normalized[index].coefficients,
        ...extras[index],
        normalized[index].rhs,
      ]);
    }
    rows.add(List<double>.filled(columns.length + 1, 0));
    return StandardForm(
      program: program,
      tableau: SimplexTableau(columnNames: columns, rows: rows, basis: basis),
      artificialColumns: artificial,
      method: artificial.isEmpty
          ? SimplexMethod.primal
          : SimplexMethod.twoPhase,
      steps: steps,
    );
  }
}

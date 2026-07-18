// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:math' as math;

import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program_result.dart';
import 'package:calcademy/features/linear_programming/domain/lp_constants.dart';
import 'package:calcademy/features/linear_programming/domain/simplex_solver.dart';

class LpPoint {
  const LpPoint(this.x, this.y);
  final double x;
  final double y;
}

class GraphicalSolution {
  const GraphicalSolution({
    required this.status,
    required this.corners,
    required this.hull,
    required this.plotMaximum,
    this.optimum,
    this.objectiveValue,
  });

  final LinearProgramStatus status;
  final List<LpPoint> corners;
  final List<LpPoint> hull;
  final LpPoint? optimum;
  final double? objectiveValue;
  final double plotMaximum;
}

class GraphicalSolver {
  const GraphicalSolver();

  GraphicalSolution solve(LinearProgram program) {
    if (program.variables.length != 2) {
      throw UnsupportedError('Graphical solution requires two variables.');
    }
    final simplex = SimplexSolver().solve(program);
    final lines = <List<double>>[
      for (final item in program.constraints)
        [item.coefficients[0], item.coefficients[1], item.rhs],
      [1, 0, 0],
      [0, 1, 0],
    ];
    final candidates = <LpPoint>[];
    for (var first = 0; first < lines.length; first++) {
      for (var second = first + 1; second < lines.length; second++) {
        final point = _intersection(lines[first], lines[second]);
        if (point != null && _feasible(program, point))
          _addUnique(candidates, point);
      }
    }
    const origin = LpPoint(0, 0);
    if (_feasible(program, origin)) _addUnique(candidates, origin);
    candidates.sort(
      (a, b) => a.x == b.x ? a.y.compareTo(b.y) : a.x.compareTo(b.x),
    );
    final hull = _convexHull(candidates);
    LpPoint? optimum;
    double? best;
    for (final point in candidates) {
      final value =
          program.objective[0] * point.x + program.objective[1] * point.y;
      final better =
          best == null ||
          (program.direction == ObjectiveDirection.maximize
              ? value > best + LpConstants.simplexEpsilon
              : value < best - LpConstants.simplexEpsilon);
      if (better) {
        best = value;
        optimum = point;
      }
    }
    var maximum = 10.0;
    for (final point in candidates) {
      maximum = math.max(maximum, math.max(point.x, point.y) * 1.2);
    }
    return GraphicalSolution(
      status: simplex.status,
      corners: List.unmodifiable(candidates),
      hull: List.unmodifiable(hull),
      optimum: simplex is FeasibleLinearProgramResult ? optimum : null,
      objectiveValue: simplex is FeasibleLinearProgramResult
          ? simplex.objectiveValue
          : best,
      plotMaximum: maximum.isFinite ? maximum : 10,
    );
  }

  LpPoint? _intersection(List<double> first, List<double> second) {
    final determinant = first[0] * second[1] - second[0] * first[1];
    if (determinant.abs() <= LpConstants.simplexEpsilon) return null;
    final x = (first[2] * second[1] - second[2] * first[1]) / determinant;
    final y = (first[0] * second[2] - second[0] * first[2]) / determinant;
    if (!x.isFinite || !y.isFinite) return null;
    return LpPoint(
      x.abs() < LpConstants.simplexEpsilon ? 0 : x,
      y.abs() < LpConstants.simplexEpsilon ? 0 : y,
    );
  }

  bool _feasible(LinearProgram program, LpPoint point) {
    if (point.x < -LpConstants.simplexEpsilon ||
        point.y < -LpConstants.simplexEpsilon)
      return false;
    for (final constraint in program.constraints) {
      final lhs =
          constraint.coefficients[0] * point.x +
          constraint.coefficients[1] * point.y;
      final valid = switch (constraint.relation) {
        ConstraintRelation.lessOrEqual =>
          lhs <= constraint.rhs + LpConstants.simplexEpsilon,
        ConstraintRelation.greaterOrEqual =>
          lhs >= constraint.rhs - LpConstants.simplexEpsilon,
        ConstraintRelation.equal =>
          (lhs - constraint.rhs).abs() <= LpConstants.simplexEpsilon,
      };
      if (!valid) return false;
    }
    return true;
  }

  void _addUnique(List<LpPoint> points, LpPoint candidate) {
    if (points.any(
      (point) =>
          (point.x - candidate.x).abs() <= LpConstants.simplexEpsilon &&
          (point.y - candidate.y).abs() <= LpConstants.simplexEpsilon,
    ))
      return;
    points.add(candidate);
  }

  List<LpPoint> _convexHull(List<LpPoint> points) {
    if (points.length <= 2) return points.toList();
    double cross(LpPoint origin, LpPoint a, LpPoint b) =>
        (a.x - origin.x) * (b.y - origin.y) -
        (a.y - origin.y) * (b.x - origin.x);
    final lower = <LpPoint>[];
    for (final point in points) {
      while (lower.length >= 2 &&
          cross(lower[lower.length - 2], lower.last, point) <= 0) {
        lower.removeLast();
      }
      lower.add(point);
    }
    final upper = <LpPoint>[];
    for (final point in points.reversed) {
      while (upper.length >= 2 &&
          cross(upper[upper.length - 2], upper.last, point) <= 0) {
        upper.removeLast();
      }
      upper.add(point);
    }
    return [...lower.take(lower.length - 1), ...upper.take(upper.length - 1)];
  }
}

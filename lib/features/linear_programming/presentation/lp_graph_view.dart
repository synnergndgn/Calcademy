// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:calcademy/features/linear_programming/domain/graphical_solution.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class LpGraphView extends StatelessWidget {
  const LpGraphView({super.key, required this.program});
  final LinearProgram program;

  @override
  Widget build(BuildContext context) {
    final solution = const GraphicalSolver().solve(program);
    return Semantics(
      label: context.l10n.t('lpGraphicalSolution'),
      child: AspectRatio(
        aspectRatio: 1.35,
        child: CustomPaint(
          painter: _LpPainter(program, solution, Theme.of(context).colorScheme),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _LpPainter extends CustomPainter {
  _LpPainter(this.program, this.solution, this.colors);
  final LinearProgram program;
  final GraphicalSolution solution;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 28.0;
    final area = Rect.fromLTRB(inset, 8, size.width - 8, size.height - inset);
    final axis = Paint()
      ..color = colors.onSurfaceVariant
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(area.left, area.bottom),
      Offset(area.right, area.bottom),
      axis,
    );
    canvas.drawLine(
      Offset(area.left, area.bottom),
      Offset(area.left, area.top),
      axis,
    );
    Offset map(LpPoint p) => Offset(
      area.left + p.x / solution.plotMaximum * area.width,
      area.bottom - p.y / solution.plotMaximum * area.height,
    );
    final linePaint = Paint()
      ..color = colors.onSurfaceVariant.withValues(alpha: .75)
      ..strokeWidth = 1.5;
    for (final constraint in program.constraints) {
      final segment = _lineSegment(
        constraint.coefficients[0],
        constraint.coefficients[1],
        constraint.rhs,
      );
      if (segment == null) continue;
      final first = map(segment.$1);
      final second = map(segment.$2);
      canvas.drawLine(first, second, linePaint);
      _label(
        canvas,
        constraint.name,
        Offset.lerp(first, second, .5)!,
        colors.onSurface,
      );
    }
    if (solution.hull.length >= 3) {
      final path = Path()
        ..moveTo(map(solution.hull.first).dx, map(solution.hull.first).dy);
      for (final point in solution.hull.skip(1))
        path.lineTo(map(point).dx, map(point).dy);
      path.close();
      canvas.drawPath(
        path,
        Paint()..color = colors.primary.withValues(alpha: .18),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = colors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    final pointPaint = Paint()..color = colors.secondary;
    for (final point in solution.corners)
      canvas.drawCircle(map(point), 4, pointPaint);
    if (solution.optimum != null) {
      canvas.drawCircle(
        map(solution.optimum!),
        8,
        Paint()
          ..color = colors.tertiary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      final objective = _lineSegment(
        program.objective[0],
        program.objective[1],
        solution.objectiveValue ?? 0,
      );
      if (objective != null) {
        final objectivePaint = Paint()
          ..color = colors.tertiary
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(map(objective.$1), map(objective.$2), objectivePaint);
        _label(
          canvas,
          'z',
          Offset.lerp(map(objective.$1), map(objective.$2), .65)!,
          colors.tertiary,
        );
      }
    }
    _label(
      canvas,
      program.variables[0].name,
      Offset(area.right - 14, area.bottom + 6),
      colors.onSurface,
    );
    _label(
      canvas,
      program.variables[1].name,
      Offset(area.left - 24, area.top),
      colors.onSurface,
    );
  }

  (LpPoint, LpPoint)? _lineSegment(double a, double b, double rhs) {
    final points = <LpPoint>[];
    void add(double x, double y) {
      if (!x.isFinite ||
          !y.isFinite ||
          x < 0 ||
          y < 0 ||
          x > solution.plotMaximum ||
          y > solution.plotMaximum)
        return;
      if (points.any(
        (point) => (point.x - x).abs() < 1e-9 && (point.y - y).abs() < 1e-9,
      ))
        return;
      points.add(LpPoint(x, y));
    }

    if (b.abs() > 1e-9) {
      add(0, rhs / b);
      add(solution.plotMaximum, (rhs - a * solution.plotMaximum) / b);
    }
    if (a.abs() > 1e-9) {
      add(rhs / a, 0);
      add((rhs - b * solution.plotMaximum) / a, solution.plotMaximum);
    }
    return points.length >= 2 ? (points[0], points[1]) : null;
  }

  void _label(Canvas canvas, String text, Offset offset, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 80);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _LpPainter oldDelegate) =>
      oldDelegate.program != program;
}

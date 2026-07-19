import 'package:calcademy/features/equation_solver/domain/root_finding.dart';

/// The detected `a·x² + b·x + c` shape of a function, if it has one.
class QuadraticShape {
  const QuadraticShape({required this.a, required this.b, required this.c});

  final double a;
  final double b;
  final double c;
}

/// Detects whether f is (numerically) a polynomial of degree ≤ 2, so the
/// solver can use the exact analytic formulas instead of a numeric scan.
///
/// Method: fit a, b, c from three exact samples (f(-1), f(0), f(1)), then
/// *verify* the fit at four additional points spread away from the fit
/// points. A transcendental function (sin, exp, ...) will fit three points
/// trivially but fail verification, falling back to the scan path. The
/// caller additionally residual-checks any analytic root against the real
/// f before trusting it (belt and braces against a false positive).
QuadraticShape? detectQuadratic(RealFunction f) {
  final f0 = f(0);
  final f1 = f(1);
  final fm1 = f(-1);
  if (!f0.isFinite || !f1.isFinite || !fm1.isFinite) return null;

  final c = f0;
  final a = (f1 + fm1 - 2 * c) / 2;
  final b = (f1 - fm1) / 2;

  double model(double x) => a * x * x + b * x + c;
  final scale = [
    a.abs(),
    b.abs(),
    c.abs(),
    1.0,
  ].reduce((p, q) => p > q ? p : q);
  for (final x in const [2.0, -2.0, 0.5, 3.7]) {
    final actual = f(x);
    if (!actual.isFinite) return null;
    if ((actual - model(x)).abs() > 1e-8 * scale * (1 + x * x)) return null;
  }
  return QuadraticShape(a: a, b: b, c: c);
}

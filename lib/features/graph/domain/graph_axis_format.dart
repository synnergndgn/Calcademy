/// Axis tick helpers shared by the graphing and calculus charts.
///
/// fl_chart walks an axis by repeatedly adding the tick interval to a base
/// value, so the tick that should be exactly `0` arrives at the label
/// callback as accumulated rounding noise such as `-2.8e-16`. Snapping the
/// tick back onto its interval before anything formats it keeps the zero
/// label readable, and the formatter below refuses to print noise in
/// exponential form even if a snap is ever missed.
library;

/// How far a tick may sit from a multiple of the interval and still count as
/// that multiple. Rounding noise is many orders of magnitude below this;
/// genuine intermediate values are far above it.
const _tickTolerance = 1e-6;

/// A value smaller than this fraction of the axis span is not a point on the
/// axis, it is the zero tick carrying rounding noise.
const _zeroTolerance = 1e-6;

/// Snaps [value] onto the nearest multiple of [interval] when it is only a
/// rounding error away from one, and returns positive zero for the zero tick.
///
/// Values that genuinely fall between ticks are returned untouched, so this
/// is safe to apply to every label callback.
double snapAxisTick(double value, double interval) {
  if (!value.isFinite || !interval.isFinite || interval <= 0) return value;
  final steps = value / interval;
  final rounded = steps.roundToDouble();
  if ((steps - rounded).abs() > _tickTolerance) return value;
  if (rounded == 0) return 0;
  return rounded * interval;
}

/// Whether [value] is negligible against an axis spanning [span] - that is,
/// whether it is the zero tick rather than a genuinely small value.
///
/// The comparison is relative so a `1e-6`-scale axis keeps its real ticks:
/// only values millions of times smaller than the visible span are zero.
bool isNegligibleOnAxis(double value, double span) {
  if (value == 0) return true;
  if (!value.isFinite) return false;
  final reference = span.isFinite && span > 0 ? span.abs() : value.abs();
  return value.abs() < reference * _zeroTolerance;
}

/// Formats a tick for a graphing axis whose visible extent is [span].
///
/// Negligible values print as `0.0` rather than in exponential form, which
/// is both wrong and too wide for the reserved axis width.
String formatGraphAxisLabel(double value, {required double span}) {
  if (isNegligibleOnAxis(value, span)) return '0.0';
  final magnitude = value.abs();
  if (magnitude >= 1000 || magnitude < 0.01) {
    return value.toStringAsExponential(1);
  }
  return value.toStringAsFixed(magnitude < 10 ? 1 : 0);
}

/// Whether the label for [value] fits inside the chart frame.
///
/// fl_chart centres a tick label on its tick, so a tick sitting on (or just
/// inside) [min]/[max] is drawn straddling the border. Ticks are a full
/// [interval] apart, so this drops at most one label per end.
bool showsAxisLabel(
  double value, {
  required double min,
  required double max,
  required double interval,
}) {
  if (!interval.isFinite || interval <= 0) return true;
  final margin = interval * _edgeLabelMargin;
  return value - min >= margin && max - value >= margin;
}

/// The share of a tick interval that has to separate a tick from the chart
/// bound before its label clears the border.
const _edgeLabelMargin = 0.3;

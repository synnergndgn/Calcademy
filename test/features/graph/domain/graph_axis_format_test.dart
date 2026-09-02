import 'package:calcademy/features/graph/domain/graph_axis_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('snapAxisTick', () {
    test('returns exact positive zero for a tick made of rounding noise', () {
      final snapped = snapAxisTick(-2.8e-16, 0.2);

      expect(snapped, 0.0);
      expect(snapped.isNegative, isFalse);
    });

    test('snaps a tick that is a rounding error off its multiple', () {
      expect(snapAxisTick(0.30000000000000004, 0.1), closeTo(0.3, 1e-12));
      expect(snapAxisTick(-1.1999999999999997, 0.2), closeTo(-1.2, 1e-12));
    });

    test('leaves values that genuinely fall between ticks alone', () {
      expect(snapAxisTick(0.35, 0.2), 0.35);
      expect(snapAxisTick(-0.75, 0.5), -0.75);
    });

    test('keeps real ticks on very small and very large axes', () {
      expect(snapAxisTick(5e-7, 5e-7), closeTo(5e-7, 1e-19));
      expect(snapAxisTick(5e5, 5e5), closeTo(5e5, 1e-6));
    });

    test('passes values through when the interval is unusable', () {
      expect(snapAxisTick(1.5, 0), 1.5);
      expect(snapAxisTick(1.5, double.nan), 1.5);
      expect(snapAxisTick(double.infinity, 0.2), double.infinity);
    });

    test('cleans the whole walk fl_chart makes across a sin/cos axis', () {
      // fl_chart steps the axis by adding the interval repeatedly, which is
      // how the zero tick arrived as -2.8e-16 on the sin(x)/cos(x) chart.
      const interval = 0.2;
      const span = 2.456;
      final labels = <String>[];
      var value = -1.4000000000000001;
      while (value <= 1.4) {
        labels.add(
          formatGraphAxisLabel(snapAxisTick(value, interval), span: span),
        );
        value += interval;
      }

      expect(labels, contains('0.0'));
      expect(labels.where((label) => label.contains('e')), isEmpty);
    });
  });

  group('formatGraphAxisLabel', () {
    test('prints a negligible value as zero, never in exponential form', () {
      expect(formatGraphAxisLabel(-2.8e-16, span: 2.456), '0.0');
      expect(formatGraphAxisLabel(0, span: 2.456), '0.0');
      expect(formatGraphAxisLabel(1e-22, span: 2e-6), '0.0');
    });

    test('keeps ordinary ticks readable', () {
      expect(formatGraphAxisLabel(1.2, span: 2.456), '1.2');
      expect(formatGraphAxisLabel(-1.0, span: 2.456), '-1.0');
      expect(formatGraphAxisLabel(12, span: 40), '12');
    });

    test('still formats genuinely small and large axes sensibly', () {
      expect(formatGraphAxisLabel(5e-7, span: 2e-6), '5.0e-7');
      expect(formatGraphAxisLabel(-1e-6, span: 2e-6), '-1.0e-6');
      expect(formatGraphAxisLabel(5e5, span: 2e6), '5.0e+5');
      expect(formatGraphAxisLabel(1e6, span: 2e6), '1.0e+6');
    });

    test('falls back to the value itself when the span is unusable', () {
      expect(formatGraphAxisLabel(1.2, span: 0), '1.2');
      expect(formatGraphAxisLabel(1.2, span: double.nan), '1.2');
    });
  });

  group('showsAxisLabel', () {
    test('hides a tick sitting on the chart bound', () {
      expect(showsAxisLabel(-1.2, min: -1.2, max: 1.2, interval: 0.2), isFalse);
      expect(showsAxisLabel(1.2, min: -1.2, max: 1.2, interval: 0.2), isFalse);
    });

    test('hides the outermost tick of a padded automatic range', () {
      // sin(x)/cos(x) with the sampler's 12% padding: 1.2 lands 0.028 inside
      // the bound, close enough that the label straddles the border.
      expect(
        showsAxisLabel(1.2, min: -1.228, max: 1.228, interval: 0.2),
        isFalse,
      );
    });

    test('keeps every tick that clears the border', () {
      expect(showsAxisLabel(0, min: -1.228, max: 1.228, interval: 0.2), isTrue);
      expect(showsAxisLabel(1, min: -1.228, max: 1.228, interval: 0.2), isTrue);
      expect(
        showsAxisLabel(-1, min: -1.228, max: 1.228, interval: 0.2),
        isTrue,
      );
    });

    test('drops at most one label per end', () {
      const min = -1.228;
      const max = 1.228;
      const interval = 0.2;
      final hidden = [
        for (var step = -6; step <= 6; step++)
          if (!showsAxisLabel(
            step * interval,
            min: min,
            max: max,
            interval: interval,
          ))
            step,
      ];

      expect(hidden, [-6, 6]);
    });

    test('shows everything when the interval is unusable', () {
      expect(showsAxisLabel(1, min: -1, max: 1, interval: 0), isTrue);
    });
  });
}

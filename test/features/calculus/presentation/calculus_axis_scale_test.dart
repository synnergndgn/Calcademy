import 'package:calcademy/features/calculus/presentation/calculus_axis_scale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'uses readable labels and real headroom for a wide asymmetric range',
    () {
      final scale = CalculusAxisScale.calculate(-66.9, 201);

      expect(scale.labelCount, inInclusiveRange(2, 6));
      expect(scale.interval, greaterThan(0));
      expect(scale.max, greaterThan(scale.lastLabel));
      expect(scale.min, lessThan(scale.firstLabel));
      expect(scale.lastLabel, isNot(201));
    },
  );

  test('does not expose chart boundary values as title values', () {
    final scale = CalculusAxisScale.calculate(-1, 1);

    expect(scale.shows(scale.min), isFalse);
    expect(scale.shows(scale.max), isFalse);
    expect(scale.shows(scale.firstLabel), isTrue);
    expect(scale.shows(scale.lastLabel), isTrue);
  });
}

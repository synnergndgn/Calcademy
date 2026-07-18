import 'dart:math' as math;

import 'package:calcademy/features/graph/domain/graph_expression.dart';
import 'package:calcademy/features/graph/domain/graph_point.dart';
import 'package:calcademy/features/graph/domain/graph_range.dart';
import 'package:calcademy/features/graph/domain/graph_sampler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compiler = GraphExpressionCompiler();
  final sampler = GraphSampler();

  group('GraphExpressionCompiler', () {
    test('evaluates supported single-variable expressions', () {
      expect(compiler.compile('x^2').evaluate(3), 9);
      expect(compiler.compile('2*x+1').evaluate(3), 7);
      expect(compiler.compile('2x + 3').evaluate(4), 11);
      expect(compiler.compile('(x+1)(x-1)').evaluate(3), 8);
      expect(compiler.compile('f(x) = x^2').evaluate(4), 16);
      expect(
        compiler.compile('sin(x)').evaluate(math.pi / 2),
        closeTo(1, 1e-12),
      );
      expect(compiler.compile('cos(x)').evaluate(0), closeTo(1, 1e-12));
      expect(compiler.compile('sqrt(x)').evaluate(9), 3);
      expect(compiler.compile('1/x').evaluate(2), 0.5);
      expect(compiler.compile('log(x)').evaluate(100), closeTo(2, 1e-12));
      expect(compiler.compile('abs(x)').evaluate(-3), 3);
      expect(compiler.compile('exp(x)').evaluate(1), closeTo(math.e, 1e-12));
    });

    test('applies real function domains without exposing NaN as a result', () {
      final sqrt = compiler.compile('sqrt(x)');
      final log = compiler.compile('log(x)');
      final asin = compiler.compile('asin(x)');
      final acos = compiler.compile('acos(x)');
      final atan = compiler.compile('atan(x)');

      expect(sqrt.evaluate(-1), isNaN);
      expect(log.evaluate(0), isNaN);
      expect(log.evaluate(-1), isNaN);
      expect(asin.evaluate(-1).isFinite, isTrue);
      expect(asin.evaluate(1).isFinite, isTrue);
      expect(asin.evaluate(1.001), isNaN);
      expect(acos.evaluate(-1).isFinite, isTrue);
      expect(acos.evaluate(1).isFinite, isTrue);
      expect(acos.evaluate(-1.001), isNaN);
      expect(atan.evaluate(-100).isFinite, isTrue);
      expect(atan.evaluate(100).isFinite, isTrue);
    });

    test('rejects unsupported variables and unknown functions', () {
      expect(
        () => compiler.compile('x + y'),
        throwsA(
          predicate<GraphExpressionException>(
            (error) => error.error == GraphExpressionError.unsupportedVariable,
          ),
        ),
      );
      expect(
        () => compiler.compile('mystery(x)'),
        throwsA(
          predicate<GraphExpressionException>(
            (error) => error.error == GraphExpressionError.unknownFunction,
          ),
        ),
      );
    });
  });

  group('GraphSampler', () {
    test('skips sqrt and log points outside their domains', () {
      final sqrt = sampler.sample(
        functionId: 'sqrt',
        evaluator: compiler.compile('sqrt(x)'),
        range: const GraphRange(min: -4, max: 4),
      );
      final log = sampler.sample(
        functionId: 'log',
        evaluator: compiler.compile('log(x)'),
        range: const GraphRange(min: -4, max: 4),
      );

      expect(
        sqrt.segments.expand((item) => item.points).every((p) => p.x >= 0),
        isTrue,
      );
      expect(
        log.segments.expand((item) => item.points).every((p) => p.x > 0),
        isTrue,
      );
    });

    test('does not connect across the 1/x discontinuity', () {
      final series = sampler.sample(
        functionId: 'reciprocal',
        evaluator: compiler.compile('1/x'),
        range: const GraphRange(min: -10, max: 10),
      );

      expect(series.segments.length, greaterThanOrEqualTo(2));
      expect(
        series.segments.every(
          (segment) =>
              !(segment.points.first.x < 0 && segment.points.last.x > 0),
        ),
        isTrue,
      );
    });

    test('cuts tan segments near asymptotes', () {
      final series = sampler.sample(
        functionId: 'tan',
        evaluator: compiler.compile('tan(x)'),
        range: const GraphRange(min: -10, max: 10),
      );

      expect(series.segments.length, greaterThan(3));
    });

    test('cuts shifted and quadratic reciprocal poles', () {
      final shifted = sampler.sample(
        functionId: 'shifted',
        evaluator: compiler.compile('1/(x-2)'),
        range: const GraphRange(min: -10, max: 10),
      );
      final quadratic = sampler.sample(
        functionId: 'quadratic',
        evaluator: compiler.compile('1/(x^2-1)'),
        range: const GraphRange(min: -10, max: 10),
      );

      expect(_crosses(shifted, 2), isFalse);
      expect(_crosses(quadratic, -1), isFalse);
      expect(_crosses(quadratic, 1), isFalse);
    });

    test('keeps a fast continuous oscillation connected', () {
      final series = sampler.sample(
        functionId: 'oscillation',
        evaluator: compiler.compile('sin(10x)'),
        range: const GraphRange(min: -10, max: 10),
      );

      expect(series.segments, hasLength(1));
    });
  });

  group('Adaptive GraphSampler', () {
    test('uses fewer points for a line than a fast oscillation', () {
      final adaptive = GraphSampler();
      final line = adaptive.sample(
        functionId: 'line',
        evaluator: compiler.compile('2x+1'),
        expressionKey: '2x+1',
        range: const GraphRange(),
      );
      final oscillation = adaptive.sample(
        functionId: 'oscillation',
        evaluator: compiler.compile('sin(10x)'),
        expressionKey: 'sin(10x)',
        range: const GraphRange(),
      );

      expect(line.stats.generatedPointCount, lessThan(200));
      expect(
        oscillation.stats.generatedPointCount,
        greaterThan(line.stats.generatedPointCount),
      );
    });

    test('honors maximum points and recursion depth', () {
      final limited = GraphSampler(
        maxPoints: 180,
        maxDepth: 3,
        maxEvaluations: 500,
      );
      final series = limited.sample(
        functionId: 'sharp',
        evaluator: compiler.compile('1/(x^2+0.01)'),
        range: const GraphRange(),
      );

      expect(series.stats.generatedPointCount, lessThanOrEqualTo(180));
      expect(series.stats.maxDepthReached, lessThanOrEqualTo(3));
      expect(series.stats.evaluationCount, lessThanOrEqualTo(500));
    });

    test('reuses identical samples and invalidates on range changes', () {
      final cached = GraphSampler();
      GraphSeries sample(GraphRange range) => cached.sample(
        functionId: 'cached',
        evaluator: compiler.compile('x^2'),
        expressionKey: 'x^2',
        range: range,
      );

      final first = sample(const GraphRange());
      final second = sample(const GraphRange());
      final changed = sample(const GraphRange(min: -5, max: 5));

      expect(first.stats.fromCache, isFalse);
      expect(second.stats.fromCache, isTrue);
      expect(second.stats.evaluationCount, 0);
      expect(changed.stats.fromCache, isFalse);
    });
  });

  group('GraphRange', () {
    test('validates bounds and preserves defaults', () {
      expect(GraphRange.isValid(-10, 10), isTrue);
      expect(GraphRange.isValid(10, -10), isFalse);
      expect(GraphRange.isValid(-1001, 10), isFalse);
      expect(GraphRange.isValid(-10, 1001), isFalse);
      expect(const GraphRange().min, GraphRange.defaultMin);
      expect(const GraphRange().max, GraphRange.defaultMax);
    });
  });
}

bool _crosses(GraphSeries series, double x) => series.segments.any(
  (segment) => segment.points.first.x < x && segment.points.last.x > x,
);

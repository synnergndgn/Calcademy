import 'dart:math' as math;

import 'package:calcademy/features/graph/domain/graph_expression.dart';
import 'package:calcademy/features/graph/domain/graph_point.dart';
import 'package:calcademy/features/graph/domain/graph_range.dart';
import 'package:calcademy/features/graph/domain/graph_sampler.dart';
import 'package:calcademy/features/graph/domain/graph_viewport_clipper.dart';
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

    test(
      'turns overflow and invalid intermediate operations into undefined',
      () {
        expect(compiler.compile('e^x').evaluate(1000), isNaN);
        expect(compiler.compile('e^(x^2)').evaluate(100), isNaN);
        expect(compiler.compile('exp(x)').evaluate(1000), isNaN);
        expect(compiler.compile('floor(exp(x))').evaluate(1000), isNaN);
        expect(compiler.compile('1/0').evaluate(0), isNaN);
        expect(compiler.compile('tan(pi/2)').evaluate(0), isNaN);
        expect(compiler.compile('e^x').evaluate(-1000), 0);
        expect(compiler.compile('x').evaluate(double.infinity), isNaN);
      },
    );

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

    test('samples the graph-engine regression set within safety limits', () {
      const expressions = [
        '(1/30)^x + e^(x/4)',
        'e^x',
        'e^(x^2)',
        '1/x',
        'tan(x)',
        'log(x)',
        'sqrt(x)',
        'sin(100x)',
        '1/(x-2)',
        'x^10',
      ];

      for (final expression in expressions) {
        final series = GraphSampler().sample(
          functionId: expression,
          evaluator: compiler.compile(expression),
          range: const GraphRange(),
          viewportWidth: 720,
          viewportHeight: 390,
        );
        final points = series.segments.expand((segment) => segment.points);
        expect(
          points.every(
            (point) =>
                point.x.isFinite &&
                point.y.isFinite &&
                point.y.abs() <= GraphSampler.maxDrawableMagnitude,
          ),
          isTrue,
          reason: expression,
        );
        expect(
          series.stats.generatedPointCount,
          lessThanOrEqualTo(3200),
          reason: expression,
        );
        expect(
          series.stats.evaluationCount,
          lessThanOrEqualTo(6400),
          reason: expression,
        );
      }
    });

    test(
      'samples off-isolate and still reuses the parsed-expression cache',
      () async {
        final asyncSampler = GraphSampler();
        final evaluator = compiler.compile('(1/30)^x + e^(x/4)');
        final first = await asyncSampler.sampleAsync(
          functionId: 'async',
          evaluator: evaluator,
          expressionKey: '(1/30)^x + e^(x/4)',
          range: const GraphRange(),
        );
        final second = await asyncSampler.sampleAsync(
          functionId: 'async',
          evaluator: evaluator,
          expressionKey: '(1/30)^x + e^(x/4)',
          range: const GraphRange(),
        );

        expect(first.pointCount, greaterThan(0));
        expect(second.stats.fromCache, isTrue);
        expect(second.stats.evaluationCount, 0);
      },
    );
  });

  group('GraphViewportClipper', () {
    const clipper = GraphViewportClipper();

    test('keeps extreme finite coordinates out of the renderer', () {
      const source = GraphSeries(
        functionId: 'steep',
        segments: [
          GraphSegment([
            GraphPoint(-1, -1e12),
            GraphPoint(0, 0),
            GraphPoint(1, 1e12),
          ]),
        ],
      );
      final clipped = clipper.clip(
        series: source,
        xRange: const GraphRange(),
        yRange: const GraphYRange(-10, 10),
      );

      expect(clipped.pointCount, greaterThanOrEqualTo(2));
      expect(
        clipped.segments
            .expand((segment) => segment.points)
            .every((point) => point.y.abs() <= 11.6 + 1e-9),
        isTrue,
      );
    });

    test('drops segments fully outside the viewport', () {
      const source = GraphSeries(
        functionId: 'outside',
        segments: [
          GraphSegment([GraphPoint(-1, 1e9), GraphPoint(1, 1e9)]),
        ],
      );
      final clipped = clipper.clip(
        series: source,
        xRange: const GraphRange(),
        yRange: const GraphYRange(-10, 10),
      );

      expect(clipped.pointCount, 0);
    });
  });

  group('GraphRange', () {
    test('validates bounds and preserves defaults', () {
      expect(GraphRange.isValid(-10, 10), isTrue);
      expect(GraphRange.isValid(10, -10), isFalse);
      expect(GraphRange.isValid(0, GraphRange.minimumSpan / 2), isFalse);
      expect(GraphRange.isValid(-1001, 10), isFalse);
      expect(GraphRange.isValid(-10, 1001), isFalse);
      expect(const GraphRange().min, GraphRange.defaultMin);
      expect(const GraphRange().max, GraphRange.defaultMax);
      expect(GraphYRange.isValid(-10, 10), isTrue);
      expect(GraphYRange.isValid(-1e20, 10), isFalse);
      expect(GraphYRange.isValid(1, 1 + 1e-13), isFalse);
    });
  });
}

bool _crosses(GraphSeries series, double x) => series.segments.any(
  (segment) => segment.points.first.x < x && segment.points.last.x > x,
);

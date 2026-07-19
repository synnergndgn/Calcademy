import 'package:calcademy/features/equation_solver/domain/equation_solver_result.dart';
import 'package:calcademy/features/graph/domain/graph_expression.dart';

/// A parsed single-variable equation, reduced to root form f(x) = 0.
///
/// Parsing deliberately reuses the graph module's expression compiler
/// rather than introducing a second parser: it already supports the full
/// required syntax (`+ - * / ^`, parentheses, unary minus, decimals, `x`,
/// `sin/cos/tan`, `sqrt`, `ln/log`, `exp`, `pi`, `e`) *including implicit
/// multiplication* (`2x`, `3(x+1)`), and it is battle-tested by the graph
/// test suite. An input containing `=` is split into two sides and solved
/// as lhs - rhs = 0; a bare expression is treated as expr = 0.
///
/// All trigonometric evaluation uses radians - the solver's documented
/// convention.
class ParsedEquation {
  ParsedEquation._(this._lhs, this._rhs, this.source);

  final GraphEvaluator _lhs;
  final GraphEvaluator? _rhs;
  final String source;

  /// f(x) = lhs(x) - rhs(x); non-finite evaluations surface as NaN, which
  /// every downstream algorithm treats as "undefined here".
  double evaluate(double x) {
    final left = _lhs.evaluate(x);
    if (_rhs == null) return left;
    final right = _rhs.evaluate(x);
    final value = left - right;
    return value.isFinite ? value : double.nan;
  }

  static ParsedEquation parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const EquationParseException(EquationFailure.emptyInput);
    }
    final sides = trimmed.split('=');
    if (sides.length > 2 || (sides.length == 2 && sides[1].trim().isEmpty)) {
      throw const EquationParseException(EquationFailure.invalidSyntax);
    }
    try {
      const compiler = GraphExpressionCompiler();
      final lhs = compiler.compile(sides[0]);
      final rhs = sides.length == 2 ? compiler.compile(sides[1]) : null;
      return ParsedEquation._(lhs, rhs, trimmed);
    } on GraphExpressionException catch (exception) {
      throw EquationParseException(switch (exception.error) {
        GraphExpressionError.parentheses =>
          EquationFailure.unbalancedParentheses,
        GraphExpressionError.unsupportedVariable =>
          EquationFailure.unknownVariable,
        GraphExpressionError.unknownFunction => EquationFailure.unknownFunction,
        GraphExpressionError.invalid => EquationFailure.invalidSyntax,
      });
    }
  }
}

class EquationParseException implements Exception {
  const EquationParseException(this.failure);

  final EquationFailure failure;
}

import 'dart:math' as math;

import 'package:calcademy/features/calculator/domain/calculator_error.dart';
import 'package:calcademy/features/calculator/domain/expression_normalizer.dart';
import 'package:calcademy/features/calculator/domain/expression_validator.dart';
import 'package:calcademy/features/settings/domain/app_settings.dart';

class CalculatorEngine {
  const CalculatorEngine({
    this.normalizer = const ExpressionNormalizer(),
    this.validator = const ExpressionValidator(),
  });

  final ExpressionNormalizer normalizer;
  final ExpressionValidator validator;

  double evaluate(
    String expression, {
    AngleMode angleMode = AngleMode.degrees,
    double answer = 0,
  }) {
    final normalized = normalizer.normalize(expression);
    validator.validate(normalized);
    try {
      final parser = _SafeMathParser(normalized, angleMode, answer);
      final result = parser.parse();
      if (result.isNaN) {
        throw const CalculatorException(CalculatorErrorType.undefined);
      }
      if (result.isInfinite) {
        throw const CalculatorException(CalculatorErrorType.overflow);
      }
      return result;
    } on CalculatorException {
      rethrow;
    } on FormatException {
      throw const CalculatorException(CalculatorErrorType.invalid);
    } on RangeError {
      throw const CalculatorException(CalculatorErrorType.invalid);
    }
  }
}

enum _TokenType { number, identifier, operator, leftParen, rightParen, end }

class _Token {
  const _Token(this.type, this.text);
  final _TokenType type;
  final String text;
}

class _Lexer {
  _Lexer(this.source);
  final String source;
  int index = 0;

  _Token next() {
    while (index < source.length && source[index].trim().isEmpty) {
      index++;
    }
    if (index >= source.length) return const _Token(_TokenType.end, '');
    final character = source[index];
    if (RegExp(r'[0-9.]').hasMatch(character)) {
      final start = index++;
      while (index < source.length &&
          RegExp(r'[0-9.eE]').hasMatch(source[index])) {
        if ((source[index] == 'e' || source[index] == 'E') &&
            index + 1 < source.length &&
            (source[index + 1] == '+' || source[index + 1] == '-')) {
          index += 2;
        } else {
          index++;
        }
      }
      return _Token(_TokenType.number, source.substring(start, index));
    }
    if (RegExp(r'[a-zA-Z_]').hasMatch(character)) {
      final start = index++;
      while (index < source.length &&
          RegExp(r'[a-zA-Z_]').hasMatch(source[index])) {
        index++;
      }
      final text = source.substring(start, index).toLowerCase();
      return _Token(
        text == 'mod' ? _TokenType.operator : _TokenType.identifier,
        text,
      );
    }
    index++;
    if (character == '(') return const _Token(_TokenType.leftParen, '(');
    if (character == ')') return const _Token(_TokenType.rightParen, ')');
    if ('+-*/^!%'.contains(character)) {
      return _Token(_TokenType.operator, character);
    }
    throw const CalculatorException(CalculatorErrorType.invalid);
  }
}

class _SafeMathParser {
  _SafeMathParser(String source, this.angleMode, this.answer)
    : _lexer = _Lexer(source) {
    _current = _lexer.next();
  }

  final _Lexer _lexer;
  final AngleMode angleMode;
  final double answer;
  late _Token _current;

  double parse() {
    final value = _expression();
    if (_current.type != _TokenType.end) {
      throw const CalculatorException(CalculatorErrorType.invalid);
    }
    return value;
  }

  void _advance() => _current = _lexer.next();

  double _expression() {
    var value = _term();
    while (_current.type == _TokenType.operator &&
        (_current.text == '+' || _current.text == '-')) {
      final operator = _current.text;
      _advance();
      final right = _term();
      value = operator == '+' ? value + right : value - right;
    }
    return value;
  }

  double _term() {
    var value = _unary();
    while (true) {
      if (_current.type == _TokenType.operator &&
          ['*', '/', 'mod'].contains(_current.text)) {
        final operator = _current.text;
        _advance();
        final right = _unary();
        if ((operator == '/' || operator == 'mod') && right == 0) {
          throw const CalculatorException(CalculatorErrorType.divisionByZero);
        }
        value = switch (operator) {
          '*' => value * right,
          '/' => value / right,
          _ => value % right,
        };
      } else if (_startsPrimary(_current)) {
        value *= _unary();
      } else {
        break;
      }
    }
    return value;
  }

  bool _startsPrimary(_Token token) =>
      token.type == _TokenType.number ||
      token.type == _TokenType.identifier ||
      token.type == _TokenType.leftParen;

  double _unary() {
    if (_current.type == _TokenType.operator && _current.text == '+') {
      _advance();
      return _unary();
    }
    if (_current.type == _TokenType.operator && _current.text == '-') {
      _advance();
      return -_unary();
    }
    return _power();
  }

  double _power() {
    var value = _postfix();
    if (_current.type == _TokenType.operator && _current.text == '^') {
      _advance();
      value = math.pow(value, _unary()).toDouble();
    }
    return value;
  }

  double _postfix() {
    var value = _primary();
    while (_current.type == _TokenType.operator &&
        (_current.text == '!' || _current.text == '%')) {
      if (_current.text == '!') {
        value = _factorial(value);
      } else {
        value /= 100;
      }
      _advance();
    }
    return value;
  }

  double _primary() {
    if (_current.type == _TokenType.number) {
      final value = double.tryParse(_current.text);
      if (value == null) {
        throw const CalculatorException(CalculatorErrorType.invalid);
      }
      _advance();
      return value;
    }
    if (_current.type == _TokenType.leftParen) {
      _advance();
      final value = _expression();
      if (_current.type != _TokenType.rightParen) {
        throw const CalculatorException(CalculatorErrorType.parentheses);
      }
      _advance();
      return value;
    }
    if (_current.type == _TokenType.identifier) {
      final identifier = _current.text;
      _advance();
      if (identifier == 'pi') return math.pi;
      if (identifier == 'e') return math.e;
      if (identifier == 'ans') return answer;
      if (_current.type != _TokenType.leftParen) {
        throw const CalculatorException(CalculatorErrorType.invalid);
      }
      _advance();
      final argument = _expression();
      if (_current.type != _TokenType.rightParen) {
        throw const CalculatorException(CalculatorErrorType.parentheses);
      }
      _advance();
      return _function(identifier, argument);
    }
    throw const CalculatorException(CalculatorErrorType.incomplete);
  }

  double _function(String name, double value) {
    final radians = angleMode == AngleMode.degrees
        ? value * math.pi / 180
        : value;
    final result = switch (name) {
      'sin' => math.sin(radians),
      'cos' => math.cos(radians),
      'tan' => _tan(radians),
      'asin' => _inverseAngle(math.asin(_unitDomain(value))),
      'acos' => _inverseAngle(math.acos(_unitDomain(value))),
      'atan' => _inverseAngle(math.atan(value)),
      'log' => value > 0 ? math.log(value) / math.ln10 : double.nan,
      'ln' => value > 0 ? math.log(value) : double.nan,
      'exp' => math.exp(value),
      'sqrt' => value >= 0 ? math.sqrt(value) : double.nan,
      'abs' => value.abs(),
      'floor' => value.floorToDouble(),
      'ceil' => value.ceilToDouble(),
      'round' => value.roundToDouble(),
      'factorial' => _factorial(value),
      _ => throw const CalculatorException(CalculatorErrorType.invalid),
    };
    if (result.isNaN) {
      throw const CalculatorException(CalculatorErrorType.domain);
    }
    return result;
  }

  double _tan(double radians) {
    if (math.cos(radians).abs() < 1e-12) {
      throw const CalculatorException(CalculatorErrorType.undefined);
    }
    return math.tan(radians);
  }

  double _unitDomain(double value) {
    if (value < -1 || value > 1) {
      throw const CalculatorException(CalculatorErrorType.domain);
    }
    return value;
  }

  double _inverseAngle(double radians) =>
      angleMode == AngleMode.degrees ? radians * 180 / math.pi : radians;

  double _factorial(double value) {
    if (value < 0 || value != value.roundToDouble()) {
      throw const CalculatorException(CalculatorErrorType.domain);
    }
    if (value > 170) {
      throw const CalculatorException(CalculatorErrorType.overflow);
    }
    var result = 1.0;
    for (var i = 2; i <= value.toInt(); i++) {
      result *= i;
    }
    return result;
  }
}

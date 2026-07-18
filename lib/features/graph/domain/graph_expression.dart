import 'dart:math' as math;

enum GraphAngleMode { radians, degrees }

enum GraphExpressionError {
  invalid,
  parentheses,
  unsupportedVariable,
  unknownFunction,
}

class GraphExpressionException implements Exception {
  const GraphExpressionException(this.error);

  final GraphExpressionError error;
}

class GraphExpressionCompiler {
  const GraphExpressionCompiler();

  GraphEvaluator compile(String source) {
    final normalized = _normalize(source);
    if (normalized.isEmpty ||
        RegExp(r'[^0-9a-zA-Z_+\-*/^().,\s]').hasMatch(normalized)) {
      throw const GraphExpressionException(GraphExpressionError.invalid);
    }
    return GraphEvaluator._(_Parser(normalized).parse());
  }

  String _normalize(String source) {
    return source
        .replaceFirst(RegExp(r'^\s*[a-zA-Z]\s*\(\s*x\s*\)\s*='), '')
        .trim()
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('π', 'pi')
        .replaceAllMapped(RegExp(r'(?<=\d),(?=\d)'), (_) => '.');
  }
}

class GraphEvaluator {
  const GraphEvaluator._(this._root);

  final _Node _root;

  double evaluate(
    double x, {
    GraphAngleMode angleMode = GraphAngleMode.radians,
  }) {
    final value = _root.evaluate(x, angleMode);
    return value.isFinite ? value : double.nan;
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
    if (_isDigit(character) || character == '.') return _number();
    if (RegExp(r'[a-zA-Z_]').hasMatch(character)) {
      final start = index++;
      while (index < source.length &&
          RegExp(r'[a-zA-Z_]').hasMatch(source[index])) {
        index++;
      }
      return _Token(
        _TokenType.identifier,
        source.substring(start, index).toLowerCase(),
      );
    }
    index++;
    if (character == '(') return const _Token(_TokenType.leftParen, '(');
    if (character == ')') return const _Token(_TokenType.rightParen, ')');
    if ('+-*/^'.contains(character)) {
      return _Token(_TokenType.operator, character);
    }
    throw const GraphExpressionException(GraphExpressionError.invalid);
  }

  _Token _number() {
    final start = index;
    var hasDot = false;
    while (index < source.length) {
      final character = source[index];
      if (_isDigit(character)) {
        index++;
      } else if (character == '.' && !hasDot) {
        hasDot = true;
        index++;
      } else {
        break;
      }
    }
    if (index < source.length &&
        (source[index] == 'e' || source[index] == 'E')) {
      final exponentStart = index++;
      if (index < source.length &&
          (source[index] == '+' || source[index] == '-')) {
        index++;
      }
      final digitStart = index;
      while (index < source.length && _isDigit(source[index])) {
        index++;
      }
      if (digitStart == index) index = exponentStart;
    }
    return _Token(_TokenType.number, source.substring(start, index));
  }

  bool _isDigit(String value) =>
      value.codeUnitAt(0) >= 48 && value.codeUnitAt(0) <= 57;
}

class _Parser {
  _Parser(String source) : _lexer = _Lexer(source) {
    _current = _lexer.next();
  }

  static const _functions = <String>{
    'sin',
    'cos',
    'tan',
    'asin',
    'acos',
    'atan',
    'sqrt',
    'abs',
    'log',
    'ln',
    'exp',
    'floor',
    'ceil',
    'round',
  };

  final _Lexer _lexer;
  late _Token _current;

  _Node parse() {
    final result = _expression();
    if (_current.type != _TokenType.end) {
      throw const GraphExpressionException(GraphExpressionError.invalid);
    }
    return result;
  }

  void _advance() => _current = _lexer.next();

  _Node _expression() {
    var node = _term();
    while (_current.type == _TokenType.operator &&
        (_current.text == '+' || _current.text == '-')) {
      final operator = _current.text;
      _advance();
      node = _BinaryNode(operator, node, _term());
    }
    return node;
  }

  _Node _term() {
    var node = _unary();
    while (true) {
      if (_current.type == _TokenType.operator &&
          (_current.text == '*' || _current.text == '/')) {
        final operator = _current.text;
        _advance();
        node = _BinaryNode(operator, node, _unary());
      } else if (_startsPrimary(_current)) {
        node = _BinaryNode('*', node, _unary());
      } else {
        return node;
      }
    }
  }

  bool _startsPrimary(_Token token) =>
      token.type == _TokenType.number ||
      token.type == _TokenType.identifier ||
      token.type == _TokenType.leftParen;

  _Node _unary() {
    if (_current.type == _TokenType.operator &&
        (_current.text == '+' || _current.text == '-')) {
      final operator = _current.text;
      _advance();
      return _UnaryNode(operator, _unary());
    }
    return _power();
  }

  _Node _power() {
    var node = _primary();
    if (_current.type == _TokenType.operator && _current.text == '^') {
      _advance();
      node = _BinaryNode('^', node, _unary());
    }
    return node;
  }

  _Node _primary() {
    if (_current.type == _TokenType.number) {
      final value = double.tryParse(_current.text);
      if (value == null) {
        throw const GraphExpressionException(GraphExpressionError.invalid);
      }
      _advance();
      return _NumberNode(value);
    }
    if (_current.type == _TokenType.leftParen) {
      _advance();
      final node = _expression();
      if (_current.type != _TokenType.rightParen) {
        throw const GraphExpressionException(GraphExpressionError.parentheses);
      }
      _advance();
      return node;
    }
    if (_current.type == _TokenType.identifier) {
      final identifier = _current.text;
      _advance();
      if (identifier == 'x') return const _VariableNode();
      if (identifier == 'pi') return const _NumberNode(math.pi);
      if (identifier == 'e') return const _NumberNode(math.e);
      if (_current.type != _TokenType.leftParen) {
        throw const GraphExpressionException(
          GraphExpressionError.unsupportedVariable,
        );
      }
      if (!_functions.contains(identifier)) {
        throw const GraphExpressionException(
          GraphExpressionError.unknownFunction,
        );
      }
      _advance();
      final argument = _expression();
      if (_current.type != _TokenType.rightParen) {
        throw const GraphExpressionException(GraphExpressionError.parentheses);
      }
      _advance();
      return _FunctionNode(identifier, argument);
    }
    throw const GraphExpressionException(GraphExpressionError.invalid);
  }
}

abstract class _Node {
  const _Node();

  double evaluate(double x, GraphAngleMode angleMode);
}

class _NumberNode extends _Node {
  const _NumberNode(this.value);

  final double value;

  @override
  double evaluate(double x, GraphAngleMode angleMode) => value;
}

class _VariableNode extends _Node {
  const _VariableNode();

  @override
  double evaluate(double x, GraphAngleMode angleMode) => x;
}

class _UnaryNode extends _Node {
  const _UnaryNode(this.operator, this.operand);

  final String operator;
  final _Node operand;

  @override
  double evaluate(double x, GraphAngleMode angleMode) {
    final value = operand.evaluate(x, angleMode);
    return operator == '-' ? -value : value;
  }
}

class _BinaryNode extends _Node {
  const _BinaryNode(this.operator, this.left, this.right);

  final String operator;
  final _Node left;
  final _Node right;

  @override
  double evaluate(double x, GraphAngleMode angleMode) {
    final leftValue = left.evaluate(x, angleMode);
    final rightValue = right.evaluate(x, angleMode);
    return switch (operator) {
      '+' => leftValue + rightValue,
      '-' => leftValue - rightValue,
      '*' => leftValue * rightValue,
      '/' => rightValue == 0 ? double.nan : leftValue / rightValue,
      '^' => math.pow(leftValue, rightValue).toDouble(),
      _ => double.nan,
    };
  }
}

class _FunctionNode extends _Node {
  const _FunctionNode(this.name, this.argument);

  final String name;
  final _Node argument;

  @override
  double evaluate(double x, GraphAngleMode angleMode) {
    final value = argument.evaluate(x, angleMode);
    final radians = angleMode == GraphAngleMode.degrees
        ? value * math.pi / 180
        : value;
    return switch (name) {
      'sin' => math.sin(radians),
      'cos' => math.cos(radians),
      'tan' => math.cos(radians).abs() < 1e-10 ? double.nan : math.tan(radians),
      'asin' =>
        value >= -1 && value <= 1
            ? _inverseAngle(math.asin(value), angleMode)
            : double.nan,
      'acos' =>
        value >= -1 && value <= 1
            ? _inverseAngle(math.acos(value), angleMode)
            : double.nan,
      'atan' => _inverseAngle(math.atan(value), angleMode),
      'sqrt' => value >= 0 ? math.sqrt(value) : double.nan,
      'abs' => value.abs(),
      'log' => value > 0 ? math.log(value) / math.ln10 : double.nan,
      'ln' => value > 0 ? math.log(value) : double.nan,
      'exp' => math.exp(value),
      'floor' => value.floorToDouble(),
      'ceil' => value.ceilToDouble(),
      'round' => value.roundToDouble(),
      _ => double.nan,
    };
  }

  double _inverseAngle(double radians, GraphAngleMode angleMode) {
    return angleMode == GraphAngleMode.degrees
        ? radians * 180 / math.pi
        : radians;
  }
}

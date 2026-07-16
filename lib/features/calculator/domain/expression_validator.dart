import 'package:calcademy/features/calculator/domain/calculator_error.dart';

class ExpressionValidator {
  const ExpressionValidator();

  void validate(String expression) {
    if (expression.trim().isEmpty) {
      throw const CalculatorException(CalculatorErrorType.empty);
    }
    if (RegExp(r'[^0-9a-zA-Z_+\-*/^().,!%\s]').hasMatch(expression)) {
      throw const CalculatorException(CalculatorErrorType.invalid);
    }
    if (RegExp(r'(?:\+|\*|/|\^)\s*[+\-*/^]').hasMatch(expression)) {
      throw const CalculatorException(CalculatorErrorType.invalid);
    }
    var balance = 0;
    for (final character in expression.split('')) {
      if (character == '(') balance++;
      if (character == ')') balance--;
      if (balance < 0) {
        throw const CalculatorException(CalculatorErrorType.parentheses);
      }
    }
    if (balance != 0) {
      throw const CalculatorException(CalculatorErrorType.parentheses);
    }
    if (RegExp(r'[+\-*/^.]\s*$').hasMatch(expression)) {
      throw const CalculatorException(CalculatorErrorType.incomplete);
    }
  }
}

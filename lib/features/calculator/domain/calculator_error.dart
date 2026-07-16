enum CalculatorErrorType {
  empty,
  incomplete,
  parentheses,
  invalid,
  divisionByZero,
  domain,
  undefined,
  overflow,
}

class CalculatorException implements Exception {
  const CalculatorException(this.type);

  final CalculatorErrorType type;
}

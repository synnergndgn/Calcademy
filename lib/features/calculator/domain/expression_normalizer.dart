class ExpressionNormalizer {
  const ExpressionNormalizer();

  String normalize(String expression) {
    return expression
        .trim()
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('π', 'pi')
        .replaceAllMapped(RegExp(r'(?<=\d),(?=\d)'), (_) => '.')
        .replaceAll(RegExp(r'\bmod\b', caseSensitive: false), ' mod ')
        .replaceAll(RegExp(r'\bAns\b', caseSensitive: false), 'ans');
  }
}

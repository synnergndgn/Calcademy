import 'package:calcademy/features/linear_programming/domain/linear_program.dart'
    show parseLpNumber;

/// The calculus form inputs that can fail to parse.
///
/// The tabs remember which one failed so the error decoration lands on the
/// field the user has to correct. Flagging f(x) for every failure - including
/// a bound such as `pi` that the numeric parser cannot read - pointed at the
/// wrong input.
enum CalculusInputField {
  lowerBound,
  upperBound,
  subintervals,
  point,
  stepSize,
  rangeMin,
  rangeMax,
}

/// A parse failure tagged with the field that produced it.
class CalculusInputException implements Exception {
  const CalculusInputException(this.field);

  final CalculusInputField field;

  @override
  String toString() => 'CalculusInputException(${field.name})';
}

/// Parses [source] as a number, tagging a failure with [field].
double parseCalculusNumber(String source, CalculusInputField field) {
  try {
    return parseLpNumber(source);
  } on Object {
    throw CalculusInputException(field);
  }
}

/// Parses [source] as an integer, tagging a failure with [field].
int parseCalculusInteger(String source, CalculusInputField field) {
  final value = int.tryParse(source.trim());
  if (value == null) throw CalculusInputException(field);
  return value;
}

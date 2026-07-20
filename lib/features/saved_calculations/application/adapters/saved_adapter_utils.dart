import 'package:calcademy/features/saved_calculations/domain/saved_calculations_failure.dart';

String truncateSavedText(String value, int maxLength) {
  final text = value.trim();
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength - 1)}…';
}

Never invalidSavedAdapterOutput() => throw const SavedCalculationsException(
  SavedCalculationsIssue.invalidPayload,
);

void requireSavedText(String value) {
  if (value.trim().isEmpty) invalidSavedAdapterOutput();
}

void requireFinite(Iterable<double?> values) {
  if (values.any((value) => value != null && !value.isFinite)) {
    invalidSavedAdapterOutput();
  }
}

import 'package:calcademy/features/statistics/domain/statistics_limits.dart';
import 'package:calcademy/features/statistics/domain/statistics_result.dart';

class StatisticsDataParser {
  const StatisticsDataParser();

  List<double> parse(String input) {
    final text = input.trim();
    if (text.isEmpty) {
      throw const StatisticsValidationException(StatisticsIssue.emptyDataset);
    }

    final List<String> tokens;
    final hasStructuredSeparator = text.contains(';') || text.contains('\n');
    if (hasStructuredSeparator) {
      tokens = text.split(RegExp(r'[;\r\n\s]+'));
    } else if (RegExp(r',\s|\s,').hasMatch(text)) {
      tokens = text.split(RegExp(r'[,\s]+'));
    } else if (text.contains(RegExp(r'\s'))) {
      tokens = text.split(RegExp(r'\s+'));
    } else {
      final commaCount = ','.allMatches(text).length;
      if (commaCount == 1) {
        throw const StatisticsValidationException(
          StatisticsIssue.ambiguousSeparator,
        );
      }
      tokens = commaCount > 1 ? text.split(',') : [text];
    }

    final cleaned = tokens.where((token) => token.trim().isNotEmpty).toList();
    if (cleaned.length > StatisticsLimits.maxDatasetSize) {
      throw const StatisticsValidationException(
        StatisticsIssue.datasetTooLarge,
      );
    }
    final values = <double>[];
    for (final token in cleaned) {
      final normalized = token.trim().replaceAll(',', '.');
      final value = double.tryParse(normalized);
      if (value == null || !value.isFinite) {
        throw const StatisticsValidationException(
          StatisticsIssue.invalidNumber,
        );
      }
      values.add(value);
    }
    if (values.isEmpty) {
      throw const StatisticsValidationException(StatisticsIssue.emptyDataset);
    }
    return List.unmodifiable(values);
  }
}

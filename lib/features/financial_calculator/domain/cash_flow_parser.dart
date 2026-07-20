import 'package:calcademy/features/financial_calculator/domain/financial_limits.dart';
import 'package:calcademy/features/financial_calculator/domain/financial_result.dart';
import 'package:calcademy/features/statistics/domain/statistics_data_parser.dart';
import 'package:calcademy/features/statistics/domain/statistics_result.dart';

class CashFlowParser {
  const CashFlowParser({this.dataParser = const StatisticsDataParser()});

  final StatisticsDataParser dataParser;

  List<double> parse(String input) {
    try {
      final values = dataParser.parse(input);
      if (values.length > FinancialLimits.maxCashFlowCount) {
        throw const FinancialValidationException(
          FinancialIssue.tooManyCashFlows,
        );
      }
      return values;
    } on StatisticsValidationException catch (error) {
      throw FinancialValidationException(switch (error.issue) {
        StatisticsIssue.emptyDataset => FinancialIssue.emptyCashFlows,
        StatisticsIssue.ambiguousSeparator => FinancialIssue.ambiguousSeparator,
        StatisticsIssue.datasetTooLarge => FinancialIssue.tooManyCashFlows,
        _ => FinancialIssue.invalidNumber,
      });
    }
  }
}

import 'package:calcademy/features/financial_calculator/application/cash_flow_service.dart';
import 'package:calcademy/features/financial_calculator/domain/cash_flow_parser.dart';
import 'package:calcademy/features/financial_calculator/domain/financial_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = CashFlowService();
  const parser = CashFlowParser();

  test('cash-flow parser supports safe separators and decimal commas', () {
    expect(parser.parse('1, 2, 3'), [1, 2, 3]);
    expect(parser.parse('1;2;3'), [1, 2, 3]);
    expect(parser.parse('1\n2\n3'), [1, 2, 3]);
    expect(parser.parse('1,5; 2,5'), [1.5, 2.5]);
    expect(
      () => parser.parse('1,5'),
      throwsA(
        isA<FinancialValidationException>().having(
          (error) => error.issue,
          'issue',
          FinancialIssue.ambiguousSeparator,
        ),
      ),
    );
  });

  test(
    'NPV matches known value and initial investment is not double-counted',
    () {
      final result = service.npv(
        discountRatePercent: 10,
        initialInvestment: 1000,
        cashFlowInput: '600, 600',
      );
      expect(result.value, closeTo(41.32231405, 1e-8));
      expect(result.rows.first.cashFlow, -1000);
      expect(result.rows, hasLength(3));
    },
  );

  test('IRR finds a known root and marks it approximate', () {
    final result = service.irr(
      initialInvestment: 1000,
      cashFlowInput: '600, 600',
    );
    expect(result.value, closeTo(13.06623863, 1e-6));
    expect(result.approximate, isTrue);
    expect(result.warnings, contains(FinancialWarning.approximateIrr));
  });

  test('IRR reports multiple-root possibility and candidates', () {
    final result = service.irr(
      initialInvestment: 100,
      cashFlowInput: '230, -132',
    );
    expect(result.irrCandidatesPercent, hasLength(2));
    expect(result.irrCandidatesPercent[0], closeTo(10, 1e-5));
    expect(result.irrCandidatesPercent[1], closeTo(20, 1e-5));
    expect(result.warnings, contains(FinancialWarning.multipleIrrPossible));
  });

  test('IRR without positive recovery is a typed failure', () {
    expect(
      () => service.irr(initialInvestment: 100, cashFlowInput: '-10, -20'),
      throwsA(
        isA<FinancialValidationException>().having(
          (error) => error.issue,
          'issue',
          FinancialIssue.irrNoSignChange,
        ),
      ),
    );
  });

  test('payback supports exact, fractional, and not-reached outcomes', () {
    expect(
      service.payback(initialInvestment: 100, cashFlowInput: '40, 60').value,
      2,
    );
    expect(
      service.payback(initialInvestment: 100, cashFlowInput: '40, 100').value,
      closeTo(1.6, 1e-12),
    );
    final missing = service.payback(
      initialInvestment: 100,
      cashFlowInput: '10, 20',
    );
    expect(missing.value, isNull);
    expect(missing.warnings, contains(FinancialWarning.paybackNotReached));
  });

  test('discounted payback matches a known fractional period', () {
    final result = service.payback(
      initialInvestment: 100,
      cashFlowInput: '60, 60',
      discountRatePercent: 10,
    );
    expect(result.value, closeTo(1.9166666667, 1e-9));
  });
}

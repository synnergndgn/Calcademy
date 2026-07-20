import 'package:calcademy/features/financial_calculator/application/break_even_service.dart';
import 'package:calcademy/features/financial_calculator/application/cash_flow_service.dart';
import 'package:calcademy/features/financial_calculator/application/loan_service.dart';
import 'package:calcademy/features/financial_calculator/application/tvm_service.dart';
import 'package:calcademy/features/financial_calculator/domain/financial_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tvmServiceProvider = Provider<TvmService>((ref) => const TvmService());
final cashFlowServiceProvider = Provider<CashFlowService>(
  (ref) => const CashFlowService(),
);
final loanServiceProvider = Provider<LoanService>((ref) => const LoanService());
final breakEvenServiceProvider = Provider<BreakEvenService>(
  (ref) => const BreakEvenService(),
);

class FinancialWorkspaceState {
  const FinancialWorkspaceState({this.result});

  final FinancialResult? result;
}

final financialWorkspaceProvider =
    NotifierProvider.autoDispose<
      FinancialWorkspaceController,
      FinancialWorkspaceState
    >(FinancialWorkspaceController.new);

class FinancialWorkspaceController extends Notifier<FinancialWorkspaceState> {
  @override
  FinancialWorkspaceState build() => const FinancialWorkspaceState();

  void calculate(FinancialResult Function() calculation) {
    try {
      state = FinancialWorkspaceState(result: calculation());
    } on FinancialValidationException catch (error) {
      state = FinancialWorkspaceState(
        result: FinancialFailureResult(error.issue),
      );
    } on Object {
      state = const FinancialWorkspaceState(
        result: FinancialFailureResult(FinancialIssue.calculationRange),
      );
    }
  }

  void clear() => state = const FinancialWorkspaceState();
}

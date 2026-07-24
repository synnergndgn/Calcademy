import 'package:calcademy/features/saved_calculations/application/adapters/calculus_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/equation_solver_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/financial_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/graph_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/matrix_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/statistics_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';

/// Builds the deep-link route used by the Saved page's "Open" button, or
/// null when a record cannot be restored (so the button stays hidden).
///
/// Records that pre-date restore support, or whose payloads are too old or
/// too large to rebuild the inputs from, return null via their adapter's
/// `tryRestore` guard. Operations Research stays result-only for now.
String? savedCalculationRestoreRoute(SavedCalculation item) {
  switch (item.module) {
    case SavedCalculationModule.scientificCalculator:
      final expression = item.fullInputJson['expression'];
      if (expression is! String || expression.trim().isEmpty) return null;
      return '/calculator?expression=${Uri.encodeQueryComponent(expression)}';
    case SavedCalculationModule.graphPlotter:
      if (GraphSavedAdapter.tryRestore(item) == null) return null;
      return '/graph?savedCalculationId=${Uri.encodeQueryComponent(item.id)}';
    case SavedCalculationModule.matrix:
      if (MatrixSavedAdapter.tryRestore(item) == null) return null;
      return '/matrix?savedCalculationId=${Uri.encodeQueryComponent(item.id)}';
    case SavedCalculationModule.equationSolver:
      if (EquationSolverSavedAdapter.tryRestore(item) == null) return null;
      return '/equation-solver?savedCalculationId='
          '${Uri.encodeQueryComponent(item.id)}';
    case SavedCalculationModule.calculus:
      if (CalculusSavedAdapter.tryRestore(item) == null) return null;
      return '/calculus?savedCalculationId='
          '${Uri.encodeQueryComponent(item.id)}';
    case SavedCalculationModule.statistics:
      if (StatisticsSavedAdapter.tryRestore(item) == null) return null;
      return '/statistics?savedCalculationId='
          '${Uri.encodeQueryComponent(item.id)}';
    case SavedCalculationModule.financialCalculator:
      if (FinancialSavedAdapter.tryRestore(item) == null) return null;
      return '/financial-calculator?savedCalculationId='
          '${Uri.encodeQueryComponent(item.id)}';
    case SavedCalculationModule.linearProgramming:
    case SavedCalculationModule.integerProgramming:
    case SavedCalculationModule.operationsResearch:
    case SavedCalculationModule.unknown:
      return null;
  }
}

import 'package:calcademy/features/saved_calculations/application/adapters/graph_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/matrix_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';

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
    case SavedCalculationModule.financialCalculator:
    case SavedCalculationModule.statistics:
    case SavedCalculationModule.calculus:
    case SavedCalculationModule.equationSolver:
    case SavedCalculationModule.linearProgramming:
    case SavedCalculationModule.integerProgramming:
    case SavedCalculationModule.operationsResearch:
    case SavedCalculationModule.unknown:
      return null;
  }
}

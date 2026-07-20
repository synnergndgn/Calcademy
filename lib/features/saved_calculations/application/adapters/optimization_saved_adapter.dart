import 'package:calcademy/features/integer_programming/domain/integer_program.dart';
import 'package:calcademy/features/integer_programming/domain/mip_result.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program_result.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/saved_adapter_utils.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_limits.dart';

abstract final class OptimizationSavedAdapter {
  static SavedCalculationDraft? tryLinear(
    LinearProgram program,
    LinearProgramResult result,
  ) => result is FeasibleLinearProgramResult ? linear(program, result) : null;

  static SavedCalculationDraft linear(
    LinearProgram program,
    FeasibleLinearProgramResult result,
  ) {
    requireFinite([result.objectiveValue, ...result.variableValues.values]);
    final variables = _limitedVariables(result.variableValues);
    final direction = program.direction.name;
    return SavedCalculationDraft(
      title: truncateSavedText(
        program.title,
        SavedCalculationsLimits.maxTitleLength,
      ),
      module: SavedCalculationModule.linearProgramming,
      calculationType: 'linearProgram',
      inputSummary:
          '$direction · ${program.variables.length} variables · ${program.constraints.length} constraints',
      resultSummary:
          '${result.status.name} · z = ${formatLpNumber(result.objectiveValue)} · ${_variableText(variables, result.variableValues.length)}',
      fullInputJson: {
        'direction': direction,
        'variableCount': program.variables.length,
        'constraintCount': program.constraints.length,
        'objectivePreview': program.objective
            .take(SavedCalculationsLimits.maxVariableSummaryCount)
            .toList(),
      },
      resultJson: {
        'status': result.status.name,
        'objectiveValue': result.objectiveValue,
        'variables': variables,
        'iterationCount': result.iterationCount,
        if (result.warning != null) 'warning': result.warning,
      },
    );
  }

  static SavedCalculationDraft? tryInteger(
    IntegerProgram program,
    MipResult result,
  ) => result is IncumbentMipResult ? integer(program, result) : null;

  static SavedCalculationDraft integer(
    IntegerProgram program,
    IncumbentMipResult result,
  ) {
    requireFinite([
      result.objectiveValue,
      result.bestBound,
      ...result.variableValues.values,
    ]);
    final model = program.linearModel;
    final variables = _limitedVariables(result.variableValues);
    final status = result is OptimalIntegerSolution ? 'optimal' : 'feasible';
    return SavedCalculationDraft(
      title: truncateSavedText(
        program.title,
        SavedCalculationsLimits.maxTitleLength,
      ),
      module: SavedCalculationModule.integerProgramming,
      calculationType: 'integerProgram',
      inputSummary:
          '${model.direction.name} · ${model.variables.length} variables (${program.integerVariableCount} integer/binary) · ${model.constraints.length} constraints',
      resultSummary:
          '$status · z = ${formatLpNumber(result.objectiveValue)} · ${_variableText(variables, result.variableValues.length)}',
      fullInputJson: {
        'direction': model.direction.name,
        'variableCount': model.variables.length,
        'integerVariableCount': program.integerVariableCount,
        'constraintCount': model.constraints.length,
        'objectivePreview': model.objective
            .take(SavedCalculationsLimits.maxVariableSummaryCount)
            .toList(),
      },
      resultJson: {
        'status': status,
        'objectiveValue': result.objectiveValue,
        'variables': variables,
        'bestBound': result.bestBound,
        'nodesSolved': result.nodesSolved,
        if (result.warnings.isNotEmpty)
          'warnings': result.warnings
              .take(SavedCalculationsLimits.maxConstraintSummaryCount)
              .toList(),
      },
    );
  }

  static Map<String, double> _limitedVariables(Map<String, double> values) =>
      Map.fromEntries(
        values.entries.take(SavedCalculationsLimits.maxVariableSummaryCount),
      );

  static String _variableText(Map<String, double> values, int total) {
    final text = values.entries
        .map((entry) => '${entry.key}=${formatLpNumber(entry.value)}')
        .join(', ');
    return '$text${values.length < total ? ', …' : ''}';
  }
}

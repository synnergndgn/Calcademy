import 'package:calcademy/features/matrix/domain/linear_system_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_number_formatter.dart';
import 'package:calcademy/features/matrix/domain/matrix_operation.dart';
import 'package:calcademy/features/matrix/domain/matrix_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_value.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/saved_adapter_utils.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_limits.dart';

abstract final class MatrixSavedAdapter {
  static SavedCalculationDraft fromExecution(
    MatrixExecution execution, {
    String? title,
  }) {
    final inputDimensions = execution.inputs
        .map((matrix) => '${matrix.rows}×${matrix.columns}')
        .join(' + ');
    final resultJson = <String, Object?>{};
    final resultSummary = switch (execution.result) {
      ScalarMatrixResult(:final value) => () {
        requireFinite([value]);
        resultJson.addAll({'kind': 'scalar', 'value': value});
        return '${execution.operation.notation} = ${formatMatrixNumber(value)}';
      }(),
      MatrixResultValue(:final value) => _matrixResult(value, resultJson),
      LinearSystemMatrixResult(:final value) => _linearResult(
        value,
        resultJson,
      ),
    };
    return SavedCalculationDraft(
      title: title?.trim().isNotEmpty == true
          ? title!.trim()
          : execution.operation.notation,
      module: SavedCalculationModule.matrix,
      calculationType: execution.operation.name,
      inputSummary:
          '${execution.operation.notation} · input dimensions: $inputDimensions',
      resultSummary: resultSummary,
      fullInputJson: {
        'operation': execution.operation.name,
        'inputDimensions': [
          for (final matrix in execution.inputs)
            {'rows': matrix.rows, 'columns': matrix.columns},
        ],
        if (execution.parameters.isNotEmpty) 'parameters': execution.parameters,
      },
      resultJson: resultJson,
    );
  }

  static String _matrixResult(
    MatrixValue value,
    Map<String, Object?> resultJson,
  ) {
    final cells = value.values.expand((row) => row).toList();
    requireFinite(cells);
    final preview = cells
        .take(SavedCalculationsLimits.maxMatrixPreviewCells)
        .toList();
    final truncated = preview.length < cells.length;
    resultJson.addAll({
      'kind': 'matrix',
      'rows': value.rows,
      'columns': value.columns,
      'preview': preview,
      'truncated': truncated,
    });
    final values = preview.map(formatMatrixNumber).join(', ');
    return '${value.rows}×${value.columns} matrix: [$values${truncated ? ', …' : ''}]';
  }

  static String _linearResult(
    LinearSystemResult value,
    Map<String, Object?> resultJson,
  ) {
    return switch (value) {
      UniqueSolution(:final values) => () {
        requireFinite(values);
        final preview = values
            .take(SavedCalculationsLimits.maxVariableSummaryCount)
            .toList();
        resultJson.addAll({
          'kind': 'linear',
          'status': 'unique',
          'values': preview,
        });
        return 'unique solution: ${preview.map(formatMatrixNumber).join(', ')}${preview.length < values.length ? ', …' : ''}';
      }(),
      InfiniteSolutions() => () {
        resultJson.addAll({'kind': 'linear', 'status': 'infinite'});
        return 'infinitely many solutions';
      }(),
      NoSolution() => () {
        resultJson.addAll({'kind': 'linear', 'status': 'none'});
        return 'no solution';
      }(),
    };
  }
}

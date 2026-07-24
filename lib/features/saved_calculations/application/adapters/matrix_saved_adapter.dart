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
        'inputs': [for (final matrix in execution.inputs) matrix.toJson()],
        'inputDimensions': [
          for (final matrix in execution.inputs)
            {'rows': matrix.rows, 'columns': matrix.columns},
        ],
        if (execution.parameters.isNotEmpty) 'parameters': execution.parameters,
      },
      resultJson: resultJson,
    );
  }

  static MatrixSavedInput? tryRestore(SavedCalculation item) {
    if (item.module != SavedCalculationModule.matrix) return null;
    try {
      final payload = item.fullInputJson;
      final operationName = payload['operation'];
      final rawInputs = payload['inputs'];
      if (operationName is! String || rawInputs is! List<Object?>) return null;
      final operation = MatrixOperationType.values
          .where((value) => value.name == operationName)
          .firstOrNull;
      if (operation == null) return null;
      final inputs = <MatrixValue>[];
      for (final rawInput in rawInputs) {
        if (rawInput is! Map) return null;
        inputs.add(MatrixValue.fromJson(Map<String, Object?>.from(rawInput)));
      }
      final expectedInputCount = operation.needsSecondMatrix ? 2 : 1;
      if (inputs.length != expectedInputCount) return null;
      final parameters = <String, double>{};
      final rawParameters = payload['parameters'];
      if (rawParameters != null) {
        if (rawParameters is! Map) return null;
        for (final entry in rawParameters.entries) {
          if (entry.key is! String || entry.value is! num) return null;
          final value = (entry.value as num).toDouble();
          if (!value.isFinite) return null;
          parameters[entry.key as String] = value;
        }
      }
      return MatrixSavedInput(
        operation: operation,
        inputs: List.unmodifiable(inputs),
        parameters: Map.unmodifiable(parameters),
      );
    } on Object {
      return null;
    }
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

class MatrixSavedInput {
  const MatrixSavedInput({
    required this.operation,
    required this.inputs,
    required this.parameters,
  });

  final MatrixOperationType operation;
  final List<MatrixValue> inputs;
  final Map<String, double> parameters;
}

import 'package:calcademy/features/matrix/domain/matrix_engine.dart';
import 'package:calcademy/features/matrix/domain/matrix_error.dart';
import 'package:calcademy/features/matrix/domain/matrix_operation.dart';
import 'package:calcademy/features/matrix/domain/matrix_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_value.dart';
import 'package:calcademy/features/matrix/domain/row_operation.dart';
import 'package:calcademy/features/matrix/domain/saved_matrix_operation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final matrixEngineProvider = Provider<MatrixEngine>(
  (ref) => const MatrixEngine(),
);

final matrixWorkspaceProvider =
    NotifierProvider.autoDispose<
      MatrixWorkspaceController,
      MatrixWorkspaceState
    >(MatrixWorkspaceController.new);

class MatrixWorkspaceState {
  const MatrixWorkspaceState({
    this.operation = MatrixOperationType.multiply,
    this.execution,
    this.error,
    this.activeSavedId,
  });

  final MatrixOperationType operation;
  final MatrixExecution? execution;
  final MatrixErrorCode? error;
  final String? activeSavedId;

  MatrixWorkspaceState copyWith({
    MatrixOperationType? operation,
    MatrixExecution? execution,
    bool clearExecution = false,
    MatrixErrorCode? error,
    bool clearError = false,
    String? activeSavedId,
    bool clearActiveSavedId = false,
  }) => MatrixWorkspaceState(
    operation: operation ?? this.operation,
    execution: clearExecution ? null : execution ?? this.execution,
    error: clearError ? null : error ?? this.error,
    activeSavedId: clearActiveSavedId
        ? null
        : activeSavedId ?? this.activeSavedId,
  );
}

class MatrixWorkspaceController extends Notifier<MatrixWorkspaceState> {
  MatrixEngine get _engine => ref.read(matrixEngineProvider);

  @override
  MatrixWorkspaceState build() => const MatrixWorkspaceState();

  void selectOperation(MatrixOperationType operation) {
    state = MatrixWorkspaceState(operation: operation);
  }

  void newOperation() {
    state = const MatrixWorkspaceState();
  }

  void reportError(MatrixErrorCode error) {
    state = state.copyWith(error: error, clearExecution: true);
  }

  void loadSaved(SavedMatrixOperation saved) {
    state = MatrixWorkspaceState(
      operation: saved.type,
      activeSavedId: saved.id,
    );
    execute(saved.inputs, parameters: saved.parameters);
  }

  bool execute(
    List<MatrixValue> inputs, {
    Map<String, double> parameters = const {},
  }) {
    try {
      if (inputs.isEmpty) {
        throw const MatrixException(MatrixErrorCode.invalidDimensions);
      }
      final operation = state.operation;
      final first = inputs.first;
      MatrixResult result;
      RowReductionResult? steps;
      switch (operation) {
        case MatrixOperationType.add:
          result = MatrixResultValue(_engine.add(first, inputs[1]));
          break;
        case MatrixOperationType.subtract:
          result = MatrixResultValue(_engine.subtract(first, inputs[1]));
          break;
        case MatrixOperationType.scalarMultiply:
          result = MatrixResultValue(
            _engine.scalarMultiply(first, parameters['scalar'] ?? 1),
          );
          break;
        case MatrixOperationType.multiply:
          result = MatrixResultValue(_engine.multiply(first, inputs[1]));
          break;
        case MatrixOperationType.transpose:
          result = MatrixResultValue(_engine.transpose(first));
          break;
        case MatrixOperationType.trace:
          result = ScalarMatrixResult(_engine.trace(first));
          break;
        case MatrixOperationType.determinant:
          final determinant = _engine.determinantWithSteps(first);
          result = ScalarMatrixResult(determinant.value);
          steps = determinant.reduction;
          break;
        case MatrixOperationType.inverse:
          final inverse = _engine.inverseWithSteps(first);
          result = MatrixResultValue(inverse.inverse);
          steps = inverse.reduction;
          break;
        case MatrixOperationType.rank:
          final reduction = _engine.rowEchelon(first);
          result = ScalarMatrixResult(_engine.rank(first).toDouble());
          steps = reduction;
          break;
        case MatrixOperationType.swapRows:
          final operation = SwapRows(
            (parameters['row1'] ?? 0).round(),
            (parameters['row2'] ?? 1).round(),
          );
          result = MatrixResultValue(operation.apply(first));
          steps = RowReductionResult(
            initial: first,
            result: operation.apply(first),
            operations: [operation],
          );
          break;
        case MatrixOperationType.scaleRow:
          final operation = ScaleRow(
            (parameters['row1'] ?? 0).round(),
            parameters['scalar'] ?? 1,
          );
          result = MatrixResultValue(operation.apply(first));
          steps = RowReductionResult(
            initial: first,
            result: operation.apply(first),
            operations: [operation],
          );
          break;
        case MatrixOperationType.addRowMultiple:
          final operation = AddRowMultiple(
            (parameters['row1'] ?? 0).round(),
            (parameters['row2'] ?? 1).round(),
            parameters['scalar'] ?? 1,
          );
          result = MatrixResultValue(operation.apply(first));
          steps = RowReductionResult(
            initial: first,
            result: operation.apply(first),
            operations: [operation],
          );
          break;
        case MatrixOperationType.rowEchelon:
          final reduction = _engine.rowEchelon(first);
          result = MatrixResultValue(reduction.result);
          steps = reduction;
          break;
        case MatrixOperationType.reducedRowEchelon:
          final reduction = _engine.reducedRowEchelon(first);
          result = MatrixResultValue(reduction.result);
          steps = reduction;
          break;
        case MatrixOperationType.solveLinearSystem:
          final solution = _engine.solveLinearSystem(first);
          result = LinearSystemMatrixResult(solution.result);
          steps = solution.reduction;
          break;
      }
      state = state.copyWith(
        execution: MatrixExecution(
          operation: operation,
          inputs: List.unmodifiable(inputs),
          result: result,
          parameters: Map.unmodifiable(parameters),
          steps: steps,
        ),
        clearError: true,
      );
      return true;
    } on MatrixException catch (error) {
      state = state.copyWith(error: error.code, clearExecution: true);
      return false;
    } on RangeError {
      state = state.copyWith(
        error: MatrixErrorCode.invalidRowOperation,
        clearExecution: true,
      );
      return false;
    }
  }
}

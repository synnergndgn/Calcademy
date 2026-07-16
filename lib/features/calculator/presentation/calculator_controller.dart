import 'package:calcademy/features/calculator/domain/calculator_engine.dart';
import 'package:calcademy/features/calculator/domain/calculator_error.dart';
import 'package:calcademy/features/calculator/domain/result_formatter.dart';
import 'package:calcademy/features/history/domain/calculation_record.dart';
import 'package:calcademy/features/history/presentation/history_controller.dart';
import 'package:calcademy/features/settings/presentation/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalculatorState {
  const CalculatorState({
    this.expression = '',
    this.result = '',
    this.answer = 0,
    this.error,
    this.lastRecord,
    this.justEvaluated = false,
  });

  final String expression;
  final String result;
  final double answer;
  final CalculatorErrorType? error;
  final CalculationRecord? lastRecord;
  final bool justEvaluated;

  CalculatorState copyWith({
    String? expression,
    String? result,
    double? answer,
    CalculatorErrorType? error,
    bool clearError = false,
    CalculationRecord? lastRecord,
    bool? justEvaluated,
  }) {
    return CalculatorState(
      expression: expression ?? this.expression,
      result: result ?? this.result,
      answer: answer ?? this.answer,
      error: clearError ? null : error ?? this.error,
      lastRecord: lastRecord ?? this.lastRecord,
      justEvaluated: justEvaluated ?? this.justEvaluated,
    );
  }
}

final calculatorProvider =
    NotifierProvider<CalculatorController, CalculatorState>(
      CalculatorController.new,
    );

class CalculatorController extends Notifier<CalculatorState> {
  final _engine = const CalculatorEngine();
  final _formatter = const ResultFormatter();

  @override
  CalculatorState build() => const CalculatorState();

  void setExpression(String value) {
    state = state.copyWith(
      expression: value,
      clearError: true,
      justEvaluated: false,
    );
  }

  void loadExpression(String value) {
    state = CalculatorState(expression: value, answer: state.answer);
  }

  void clear() {
    state = CalculatorState(answer: state.answer);
  }

  Future<void> evaluate() async {
    final settings = ref.read(settingsProvider);
    try {
      final value = _engine.evaluate(
        state.expression,
        angleMode: settings.angleMode,
        answer: state.answer,
      );
      final formatted = _formatter.format(
        value,
        precision: settings.decimalPrecision,
        scientificNotation: settings.scientificNotation,
      );
      final record = CalculationRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        expression: state.expression.trim(),
        result: formatted,
        createdAt: DateTime.now(),
        angleMode: settings.angleMode,
      );
      state = state.copyWith(
        result: formatted,
        answer: value,
        clearError: true,
        lastRecord: record,
        justEvaluated: true,
      );
      await ref.read(historyProvider.notifier).add(record);
    } on CalculatorException catch (error) {
      state = state.copyWith(
        result: '',
        error: error.type,
        justEvaluated: false,
      );
    }
  }
}

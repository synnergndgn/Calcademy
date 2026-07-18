import 'dart:async';

import 'package:calcademy/features/graph/data/graph_repository.dart';
import 'package:calcademy/features/graph/domain/graph_expression.dart';
import 'package:calcademy/features/graph/domain/graph_function.dart';
import 'package:calcademy/features/graph/domain/graph_point.dart';
import 'package:calcademy/features/graph/domain/graph_range.dart';
import 'package:calcademy/features/graph/domain/graph_sampler.dart';
import 'package:calcademy/features/graph/domain/saved_graph.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final graphProvider = NotifierProvider<GraphController, GraphState>(
  GraphController.new,
);

class GraphState {
  const GraphState({
    this.functions = const [],
    this.series = const {},
    this.functionErrors = const {},
    this.range = const GraphRange(),
    this.autoY = true,
    this.manualYMin = -10,
    this.manualYMax = 10,
    this.angleMode = GraphAngleMode.radians,
    this.rangeError,
    this.inspectedX,
    this.inspectedValues = const {},
    this.viewResetRevision = 0,
    this.samplingIds = const {},
    this.activeGraphId,
    this.activeTitle,
    this.isDirty = false,
  });

  final List<GraphFunction> functions;
  final Map<String, GraphSeries> series;
  final Map<String, String> functionErrors;
  final GraphRange range;
  final bool autoY;
  final double manualYMin;
  final double manualYMax;
  final GraphAngleMode angleMode;
  final String? rangeError;
  final double? inspectedX;
  final Map<String, double?> inspectedValues;
  final int viewResetRevision;
  final Set<String> samplingIds;
  final String? activeGraphId;
  final String? activeTitle;
  final bool isDirty;

  bool get isSampling => samplingIds.isNotEmpty;
  bool get isSavedWorkspace => activeGraphId != null;

  GraphState copyWith({
    List<GraphFunction>? functions,
    Map<String, GraphSeries>? series,
    Map<String, String>? functionErrors,
    GraphRange? range,
    bool? autoY,
    double? manualYMin,
    double? manualYMax,
    GraphAngleMode? angleMode,
    Object? rangeError = _unset,
    Object? inspectedX = _unset,
    Map<String, double?>? inspectedValues,
    int? viewResetRevision,
    Set<String>? samplingIds,
    Object? activeGraphId = _unset,
    Object? activeTitle = _unset,
    bool? isDirty,
  }) {
    return GraphState(
      functions: functions ?? this.functions,
      series: series ?? this.series,
      functionErrors: functionErrors ?? this.functionErrors,
      range: range ?? this.range,
      autoY: autoY ?? this.autoY,
      manualYMin: manualYMin ?? this.manualYMin,
      manualYMax: manualYMax ?? this.manualYMax,
      angleMode: angleMode ?? this.angleMode,
      rangeError: identical(rangeError, _unset)
          ? this.rangeError
          : rangeError as String?,
      inspectedX: identical(inspectedX, _unset)
          ? this.inspectedX
          : inspectedX as double?,
      inspectedValues: inspectedValues ?? this.inspectedValues,
      viewResetRevision: viewResetRevision ?? this.viewResetRevision,
      samplingIds: samplingIds ?? this.samplingIds,
      activeGraphId: identical(activeGraphId, _unset)
          ? this.activeGraphId
          : activeGraphId as String?,
      activeTitle: identical(activeTitle, _unset)
          ? this.activeTitle
          : activeTitle as String?,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

const _unset = Object();

class GraphController extends Notifier<GraphState> {
  static const maxFunctions = 5;
  static const debounceDuration = Duration(milliseconds: 320);

  final _compiler = const GraphExpressionCompiler();
  final _sampler = GraphSampler();
  final _compiled = <String, GraphEvaluator>{};
  final _debounces = <String, Timer>{};
  var _idCounter = 0;
  var _requestGeneration = 0;
  var _viewportWidth = 720.0;
  var _viewportHeight = 390.0;

  @override
  GraphState build() {
    ref.onDispose(() {
      _requestGeneration++;
      for (final timer in _debounces.values) {
        timer.cancel();
      }
    });
    return const GraphState();
  }

  bool addFunction() {
    if (state.functions.length >= maxFunctions) return false;
    final id = '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';
    final function = GraphFunction(
      id: id,
      expression: '',
      visualIndex: state.functions.length % maxFunctions,
    );
    state = state.copyWith(
      functions: [...state.functions, function],
      isDirty: true,
    );
    return true;
  }

  void removeFunction(String id) {
    _debounces.remove(id)?.cancel();
    _compiled.remove(id);
    _requestGeneration++;
    state = state.copyWith(
      functions: state.functions.where((item) => item.id != id).toList(),
      series: Map.of(state.series)..remove(id),
      functionErrors: Map.of(state.functionErrors)..remove(id),
      inspectedValues: Map.of(state.inspectedValues)..remove(id),
      samplingIds: const {},
      isDirty: true,
    );
  }

  void updateExpression(String id, String expression) {
    _requestGeneration++;
    state = state.copyWith(
      functions: [
        for (final function in state.functions)
          if (function.id == id)
            function.copyWith(expression: expression)
          else
            function,
      ],
      series: Map.of(state.series)..remove(id),
      functionErrors: Map.of(state.functionErrors)..remove(id),
      samplingIds: const {},
      isDirty: true,
    );
    _compiled.remove(id);
    _debounces.remove(id)?.cancel();
    _debounces[id] = Timer(debounceDuration, () {
      _debounces.remove(id);
      _scheduleAll(compileMissing: true);
    });
  }

  void toggleVisibility(String id) {
    state = state.copyWith(
      functions: [
        for (final function in state.functions)
          if (function.id == id)
            function.copyWith(isVisible: !function.isVisible)
          else
            function,
      ],
      isDirty: true,
    );
  }

  bool applyRange({
    required String xMin,
    required String xMax,
    String? yMin,
    String? yMax,
  }) {
    final min = double.tryParse(xMin.replaceAll(',', '.'));
    final max = double.tryParse(xMax.replaceAll(',', '.'));
    if (min == null || max == null || !GraphRange.isValid(min, max)) {
      state = state.copyWith(rangeError: 'graphInvalidRange');
      return false;
    }
    var manualMin = state.manualYMin;
    var manualMax = state.manualYMax;
    if (!state.autoY) {
      final parsedYMin = double.tryParse((yMin ?? '').replaceAll(',', '.'));
      final parsedYMax = double.tryParse((yMax ?? '').replaceAll(',', '.'));
      if (parsedYMin == null ||
          parsedYMax == null ||
          !parsedYMin.isFinite ||
          !parsedYMax.isFinite ||
          parsedYMin >= parsedYMax) {
        state = state.copyWith(rangeError: 'graphInvalidYRange');
        return false;
      }
      manualMin = parsedYMin;
      manualMax = parsedYMax;
    }
    state = state.copyWith(
      range: GraphRange(min: min, max: max),
      manualYMin: manualMin,
      manualYMax: manualMax,
      rangeError: null,
      inspectedX: null,
      inspectedValues: const {},
      viewResetRevision: state.viewResetRevision + 1,
      isDirty: true,
    );
    _scheduleAll(compileMissing: true);
    return true;
  }

  void setAutoY(bool value) {
    if (state.autoY == value) return;
    state = state.copyWith(autoY: value, rangeError: null, isDirty: true);
  }

  void setAngleMode(GraphAngleMode value) {
    if (state.angleMode == value) return;
    state = state.copyWith(angleMode: value, inspectedX: null, isDirty: true);
    _scheduleAll(compileMissing: true);
  }

  void resetView() {
    state = state.copyWith(
      range: const GraphRange(),
      autoY: true,
      manualYMin: -10,
      manualYMax: 10,
      rangeError: null,
      inspectedX: null,
      inspectedValues: const {},
      viewResetRevision: state.viewResetRevision + 1,
      isDirty: true,
    );
    _scheduleAll(compileMissing: true);
  }

  void setViewportSize(double width, double height) {
    final widthChanged = (width - _viewportWidth).abs() > 120;
    final heightChanged = (height - _viewportHeight).abs() > 100;
    if (!widthChanged && !heightChanged) return;
    _viewportWidth = width;
    _viewportHeight = height;
    if (state.functions.any((item) => item.expression.trim().isNotEmpty)) {
      _scheduleAll(compileMissing: true);
    }
  }

  void inspectAt(double x) {
    final values = <String, double?>{};
    for (final function in state.functions) {
      if (!function.isVisible) continue;
      final value = _compiled[function.id]?.evaluate(
        x,
        angleMode: state.angleMode,
      );
      values[function.id] = value?.isFinite == true ? value : null;
    }
    state = state.copyWith(inspectedX: x, inspectedValues: values);
  }

  Future<bool> saveCurrent(String title, {bool asCopy = false}) async {
    final functions = state.functions
        .where((item) => item.expression.trim().isNotEmpty)
        .toList();
    final cleanTitle = title.trim();
    if (functions.isEmpty || cleanTitle.isEmpty) return false;
    final existing = state.activeGraphId == null
        ? null
        : ref.read(savedGraphsProvider.notifier).find(state.activeGraphId!);
    final updateExisting = existing != null && !asCopy;
    final graph = SavedGraph(
      id: updateExisting
          ? existing.id
          : DateTime.now().microsecondsSinceEpoch.toString(),
      title: cleanTitle,
      functions: functions,
      range: state.range,
      autoY: state.autoY,
      manualYMin: state.manualYMin,
      manualYMax: state.manualYMax,
      angleMode: state.angleMode,
      createdAt: updateExisting ? existing.createdAt : DateTime.now(),
    );
    await ref.read(savedGraphsProvider.notifier).upsert(graph);
    state = state.copyWith(
      activeGraphId: graph.id,
      activeTitle: graph.title,
      isDirty: false,
    );
    return true;
  }

  Future<bool> saveChanges() async {
    final title = state.activeTitle;
    if (title == null) return false;
    return saveCurrent(title);
  }

  void loadSaved(String id) {
    final graph = ref.read(savedGraphsProvider.notifier).find(id);
    if (graph == null) return;
    _cancelPending();
    _compiled.clear();
    state = GraphState(
      functions: graph.functions,
      range: graph.range,
      autoY: graph.autoY,
      manualYMin: graph.manualYMin,
      manualYMax: graph.manualYMax,
      angleMode: graph.angleMode,
      viewResetRevision: state.viewResetRevision + 1,
      activeGraphId: graph.id,
      activeTitle: graph.title,
    );
    _scheduleAll(compileMissing: true, preserveCleanState: true);
  }

  void newGraph() {
    _cancelPending();
    _compiled.clear();
    state = GraphState(viewResetRevision: state.viewResetRevision + 1);
  }

  Future<void> deleteActive() async {
    final id = state.activeGraphId;
    if (id == null) return;
    await ref.read(savedGraphsProvider.notifier).delete(id);
    newGraph();
  }

  void _cancelPending() {
    _requestGeneration++;
    for (final timer in _debounces.values) {
      timer.cancel();
    }
    _debounces.clear();
  }

  Future<void> _scheduleAll({
    required bool compileMissing,
    bool preserveCleanState = false,
  }) async {
    final functions = state.functions
        .where((item) => item.expression.trim().isNotEmpty)
        .toList();
    final generation = ++_requestGeneration;
    if (functions.isEmpty) {
      state = state.copyWith(
        series: const {},
        functionErrors: const {},
        samplingIds: const {},
      );
      return;
    }
    state = state.copyWith(
      samplingIds: Set.unmodifiable(functions.map((item) => item.id)),
    );
    await Future<void>.delayed(Duration.zero);
    if (!ref.mounted || generation != _requestGeneration) return;
    final range = state.range;
    final angleMode = state.angleMode;
    final nextSeries = <String, GraphSeries>{};
    final errors = <String, String>{};
    for (final function in functions) {
      try {
        var evaluator = _compiled[function.id];
        if (evaluator == null && compileMissing) {
          evaluator = _compiler.compile(function.expression);
          _compiled[function.id] = evaluator;
        }
        if (evaluator == null) continue;
        final sampled = _sampler.sample(
          functionId: function.id,
          evaluator: evaluator,
          range: range,
          angleMode: angleMode,
          expressionKey: function.expression,
          viewportWidth: _viewportWidth,
          viewportHeight: _viewportHeight,
        );
        nextSeries[function.id] = sampled;
        if (sampled.pointCount == 0) {
          errors[function.id] = 'graphNoDrawablePoints';
        }
      } on GraphExpressionException catch (error) {
        _compiled.remove(function.id);
        errors[function.id] = _errorKey(error.error);
      }
    }
    if (!ref.mounted || generation != _requestGeneration) return;
    state = state.copyWith(
      series: Map.unmodifiable(nextSeries),
      functionErrors: Map.unmodifiable(errors),
      samplingIds: const {},
      isDirty: preserveCleanState ? false : state.isDirty,
    );
  }

  String _errorKey(GraphExpressionError error) => switch (error) {
    GraphExpressionError.parentheses => 'parenthesesError',
    GraphExpressionError.unsupportedVariable => 'graphUnsupportedVariable',
    GraphExpressionError.unknownFunction => 'graphUnknownFunction',
    GraphExpressionError.invalid => 'graphInvalidFunction',
  };
}

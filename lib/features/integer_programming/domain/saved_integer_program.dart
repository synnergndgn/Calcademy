import 'package:calcademy/features/integer_programming/domain/integer_program.dart';
import 'package:calcademy/features/integer_programming/domain/mip_result.dart';

/// A light, JSON-friendly snapshot of a [MipResult]: enough to render a
/// saved-item card and to know whether a persisted result is still
/// optimal/feasible/etc., without persisting the full branch tree (which
/// can hold thousands of nodes and is only ever useful for the session
/// that produced it).
class MipResultSummary {
  const MipResultSummary({
    required this.statusKey,
    required this.nodesSolved,
    required this.maxDepthReached,
    required this.elapsedMicroseconds,
    this.objectiveValue,
    this.variableValues = const {},
    this.bestBound,
    this.absoluteGap,
    this.relativeGap,
    this.limitReasonKey,
  });

  /// A localization key such as `mipStatusOptimal`; resolved against
  /// [AppLocalizations] by the presentation layer.
  final String statusKey;
  final int nodesSolved;
  final int maxDepthReached;
  final int elapsedMicroseconds;
  final double? objectiveValue;
  final Map<String, double> variableValues;
  final double? bestBound;
  final double? absoluteGap;
  final double? relativeGap;
  final String? limitReasonKey;

  factory MipResultSummary.fromResult(MipResult result) {
    final incumbent = result is IncumbentMipResult ? result : null;
    return MipResultSummary(
      statusKey: switch (result) {
        OptimalIntegerSolution() => 'mipStatusOptimal',
        FeasibleIntegerSolution() => 'mipStatusFeasible',
        InfeasibleIntegerProgram() => 'mipStatusInfeasible',
        UnboundedRelaxation() => 'mipStatusUnbounded',
        NodeLimitReached() => 'mipStatusNodeLimit',
        IterationLimitReached() => 'mipStatusIterationLimit',
        NumericalFailure() => 'mipStatusNumericalFailure',
      },
      nodesSolved: result.nodesSolved,
      maxDepthReached: result.maxDepthReached,
      elapsedMicroseconds: result.elapsedMicroseconds,
      objectiveValue: incumbent?.objectiveValue,
      variableValues: incumbent?.variableValues ?? const {},
      bestBound: incumbent?.bestBound,
      absoluteGap: incumbent?.absoluteGap,
      relativeGap: incumbent?.relativeGap,
      limitReasonKey: switch (result) {
        FeasibleIntegerSolution(:final limitReason) => _limitReasonKey(
          limitReason,
        ),
        NodeLimitReached(:final reason) => _limitReasonKey(reason),
        IterationLimitReached() => 'mipLimitIteration',
        _ => null,
      },
    );
  }

  static String _limitReasonKey(LimitReason reason) => switch (reason) {
    LimitReason.nodeLimit => 'mipLimitNode',
    LimitReason.depthLimit => 'mipLimitDepth',
    LimitReason.iterationLimit => 'mipLimitIteration',
  };

  Map<String, Object?> toJson() => {
    'statusKey': statusKey,
    'nodesSolved': nodesSolved,
    'maxDepthReached': maxDepthReached,
    'elapsedMicroseconds': elapsedMicroseconds,
    'objectiveValue': objectiveValue,
    'variableValues': variableValues,
    'bestBound': bestBound,
    'absoluteGap': absoluteGap,
    'relativeGap': relativeGap,
    'limitReasonKey': limitReasonKey,
  };

  factory MipResultSummary.fromJson(Map<String, Object?> json) =>
      MipResultSummary(
        statusKey: json['statusKey']! as String,
        nodesSolved: json['nodesSolved']! as int,
        maxDepthReached: json['maxDepthReached']! as int,
        elapsedMicroseconds: json['elapsedMicroseconds']! as int,
        objectiveValue: (json['objectiveValue'] as num?)?.toDouble(),
        variableValues:
            (json['variableValues'] as Map?)?.map(
              (key, value) =>
                  MapEntry(key as String, (value as num).toDouble()),
            ) ??
            const {},
        bestBound: (json['bestBound'] as num?)?.toDouble(),
        absoluteGap: (json['absoluteGap'] as num?)?.toDouble(),
        relativeGap: (json['relativeGap'] as num?)?.toDouble(),
        limitReasonKey: json['limitReasonKey'] as String?,
      );
}

class SavedIntegerProgram {
  const SavedIntegerProgram({
    required this.id,
    required this.title,
    required this.program,
    required this.result,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final IntegerProgram program;
  final MipResultSummary? result;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedIntegerProgram copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
  }) => SavedIntegerProgram(
    id: id ?? this.id,
    title: title ?? this.title,
    program: program,
    result: result,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: DateTime.now(),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'program': program.toJson(),
    'result': result?.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SavedIntegerProgram.fromJson(Map<String, Object?> json) =>
      SavedIntegerProgram(
        id: json['id']! as String,
        title: json['title']! as String,
        program: IntegerProgram.fromJson(
          Map<String, Object?>.from(json['program']! as Map),
        ),
        result: json['result'] == null
            ? null
            : MipResultSummary.fromJson(
                Map<String, Object?>.from(json['result']! as Map),
              ),
        createdAt: DateTime.parse(json['createdAt']! as String),
        updatedAt: DateTime.parse(json['updatedAt']! as String),
      );
}

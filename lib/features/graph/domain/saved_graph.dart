import 'package:calcademy/features/graph/domain/graph_expression.dart';
import 'package:calcademy/features/graph/domain/graph_function.dart';
import 'package:calcademy/features/graph/domain/graph_range.dart';

class SavedGraph {
  const SavedGraph({
    required this.id,
    required this.title,
    required this.functions,
    required this.range,
    required this.autoY,
    required this.angleMode,
    required this.createdAt,
    this.manualYMin = -10,
    this.manualYMax = 10,
  });

  final String id;
  final String title;
  final List<GraphFunction> functions;
  final GraphRange range;
  final bool autoY;
  final double manualYMin;
  final double manualYMax;
  final GraphAngleMode angleMode;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'functions': functions.map((item) => item.toJson()).toList(),
    'range': range.toJson(),
    'autoY': autoY,
    'manualYMin': manualYMin,
    'manualYMax': manualYMax,
    'angleMode': angleMode.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavedGraph.fromJson(Map<String, Object?> json) {
    return SavedGraph(
      id: json['id']! as String,
      title: json['title']! as String,
      functions: (json['functions'] as List<Object?>? ?? const [])
          .whereType<Map<String, Object?>>()
          .map(GraphFunction.fromJson)
          .toList(),
      range: GraphRange.fromJson(
        Map<String, Object?>.from(json['range']! as Map),
      ),
      autoY: json['autoY'] as bool? ?? true,
      manualYMin: (json['manualYMin'] as num?)?.toDouble() ?? -10,
      manualYMax: (json['manualYMax'] as num?)?.toDouble() ?? 10,
      angleMode: json['angleMode'] == GraphAngleMode.degrees.name
          ? GraphAngleMode.degrees
          : GraphAngleMode.radians,
      createdAt: DateTime.parse(json['createdAt']! as String),
    );
  }
}

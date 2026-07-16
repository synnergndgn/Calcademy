import 'package:calcademy/features/settings/domain/app_settings.dart';

class CalculationRecord {
  const CalculationRecord({
    required this.id,
    required this.expression,
    required this.result,
    required this.createdAt,
    required this.angleMode,
    this.isSaved = false,
  });

  final String id;
  final String expression;
  final String result;
  final DateTime createdAt;
  final AngleMode angleMode;
  final bool isSaved;

  CalculationRecord copyWith({bool? isSaved}) => CalculationRecord(
    id: id,
    expression: expression,
    result: result,
    createdAt: createdAt,
    angleMode: angleMode,
    isSaved: isSaved ?? this.isSaved,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'expression': expression,
    'result': result,
    'createdAt': createdAt.toIso8601String(),
    'angleMode': angleMode.name,
    'isSaved': isSaved,
  };

  factory CalculationRecord.fromJson(Map<String, Object?> json) {
    return CalculationRecord(
      id: json['id']! as String,
      expression: json['expression']! as String,
      result: json['result']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      angleMode: json['angleMode'] == AngleMode.radians.name
          ? AngleMode.radians
          : AngleMode.degrees,
      isSaved: json['isSaved'] as bool? ?? false,
    );
  }
}

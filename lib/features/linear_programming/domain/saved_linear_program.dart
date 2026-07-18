import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program_result.dart';

class SavedLinearProgram {
  const SavedLinearProgram({
    required this.id,
    required this.title,
    required this.program,
    required this.status,
    required this.objectiveValue,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final LinearProgram program;
  final LinearProgramStatus status;
  final double? objectiveValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedLinearProgram copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
  }) => SavedLinearProgram(
    id: id ?? this.id,
    title: title ?? this.title,
    program: program,
    status: status,
    objectiveValue: objectiveValue,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: DateTime.now(),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'program': program.toJson(),
    'status': status.name,
    'objectiveValue': objectiveValue,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SavedLinearProgram.fromJson(Map<String, Object?> json) =>
      SavedLinearProgram(
        id: json['id']! as String,
        title: json['title']! as String,
        program: LinearProgram.fromJson(
          Map<String, Object?>.from(json['program']! as Map),
        ),
        status: LinearProgramStatus.values.byName(json['status']! as String),
        objectiveValue: (json['objectiveValue'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['createdAt']! as String),
        updatedAt: DateTime.parse(json['updatedAt']! as String),
      );
}

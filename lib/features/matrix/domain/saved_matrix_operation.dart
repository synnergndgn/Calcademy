import 'package:calcademy/features/matrix/domain/matrix_operation.dart';
import 'package:calcademy/features/matrix/domain/matrix_result.dart';
import 'package:calcademy/features/matrix/domain/matrix_value.dart';

class SavedMatrixOperation {
  const SavedMatrixOperation({
    required this.id,
    required this.title,
    required this.type,
    required this.inputs,
    required this.result,
    required this.createdAt,
    this.parameters = const {},
  });

  final String id;
  final String title;
  final MatrixOperationType type;
  final List<MatrixValue> inputs;
  final MatrixResult result;
  final Map<String, double> parameters;
  final DateTime createdAt;

  SavedMatrixOperation copyWith({
    String? title,
    MatrixOperationType? type,
    List<MatrixValue>? inputs,
    MatrixResult? result,
    Map<String, double>? parameters,
  }) => SavedMatrixOperation(
    id: id,
    title: title ?? this.title,
    type: type ?? this.type,
    inputs: inputs ?? this.inputs,
    result: result ?? this.result,
    parameters: parameters ?? this.parameters,
    createdAt: createdAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'inputs': inputs.map((matrix) => matrix.toJson()).toList(),
    'result': result.toJson(),
    'parameters': parameters,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavedMatrixOperation.fromJson(Map<String, Object?> json) {
    return SavedMatrixOperation(
      id: json['id']! as String,
      title: json['title']! as String,
      type: MatrixOperationType.values.firstWhere(
        (value) => value.name == json['type'],
      ),
      inputs: (json['inputs']! as List<Object?>)
          .map(
            (value) =>
                MatrixValue.fromJson(Map<String, Object?>.from(value! as Map)),
          )
          .toList(),
      result: MatrixResult.fromJson(
        Map<String, Object?>.from(json['result']! as Map),
      ),
      parameters: (json['parameters'] as Map<Object?, Object?>? ?? const {})
          .map(
            (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
          ),
      createdAt: DateTime.parse(json['createdAt']! as String),
    );
  }
}

class SavedCalculation {
  const SavedCalculation({
    required this.id,
    required this.title,
    required this.expression,
    required this.result,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String title;
  final String? note;
  final String expression;
  final String result;
  final DateTime createdAt;

  SavedCalculation copyWith({String? title, String? note}) => SavedCalculation(
    id: id,
    title: title ?? this.title,
    note: note ?? this.note,
    expression: expression,
    result: result,
    createdAt: createdAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'note': note,
    'expression': expression,
    'result': result,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavedCalculation.fromJson(Map<String, Object?> json) {
    return SavedCalculation(
      id: json['id']! as String,
      title: json['title']! as String,
      note: json['note'] as String?,
      expression: json['expression']! as String,
      result: json['result']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
    );
  }
}

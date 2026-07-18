class GraphFunction {
  const GraphFunction({
    required this.id,
    required this.expression,
    required this.visualIndex,
    this.isVisible = true,
  });

  final String id;
  final String expression;
  final bool isVisible;
  final int visualIndex;

  GraphFunction copyWith({String? expression, bool? isVisible}) {
    return GraphFunction(
      id: id,
      expression: expression ?? this.expression,
      isVisible: isVisible ?? this.isVisible,
      visualIndex: visualIndex,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'expression': expression,
    'isVisible': isVisible,
    'visualIndex': visualIndex,
  };

  factory GraphFunction.fromJson(Map<String, Object?> json) => GraphFunction(
    id: json['id']! as String,
    expression: json['expression']! as String,
    isVisible: json['isVisible'] as bool? ?? true,
    visualIndex: json['visualIndex'] as int? ?? 0,
  );
}

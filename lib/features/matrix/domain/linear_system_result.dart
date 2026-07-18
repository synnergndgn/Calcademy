import 'package:calcademy/features/matrix/domain/matrix_value.dart';

sealed class LinearSystemResult {
  const LinearSystemResult(this.reducedMatrix);

  final MatrixValue reducedMatrix;

  Map<String, Object?> toJson();

  factory LinearSystemResult.fromJson(Map<String, Object?> json) {
    final reduced = MatrixValue.fromJson(
      Map<String, Object?>.from(json['reducedMatrix']! as Map),
    );
    return switch (json['type']) {
      'unique' => UniqueSolution(
        (json['values']! as List<Object?>)
            .map((value) => (value as num).toDouble())
            .toList(),
        reduced,
      ),
      'infinite' => InfiniteSolutions(
        pivotColumns: (json['pivotColumns']! as List<Object?>).cast<int>(),
        freeColumns: (json['freeColumns']! as List<Object?>).cast<int>(),
        reducedMatrix: reduced,
      ),
      'none' => NoSolution(reduced),
      _ => NoSolution(reduced),
    };
  }
}

final class UniqueSolution extends LinearSystemResult {
  const UniqueSolution(this.values, super.reducedMatrix);

  final List<double> values;

  @override
  Map<String, Object?> toJson() => {
    'type': 'unique',
    'values': values,
    'reducedMatrix': reducedMatrix.toJson(),
  };
}

final class InfiniteSolutions extends LinearSystemResult {
  const InfiniteSolutions({
    required this.pivotColumns,
    required this.freeColumns,
    required MatrixValue reducedMatrix,
  }) : super(reducedMatrix);

  final List<int> pivotColumns;
  final List<int> freeColumns;

  @override
  Map<String, Object?> toJson() => {
    'type': 'infinite',
    'pivotColumns': pivotColumns,
    'freeColumns': freeColumns,
    'reducedMatrix': reducedMatrix.toJson(),
  };
}

final class NoSolution extends LinearSystemResult {
  const NoSolution(super.reducedMatrix);

  @override
  Map<String, Object?> toJson() => {
    'type': 'none',
    'reducedMatrix': reducedMatrix.toJson(),
  };
}

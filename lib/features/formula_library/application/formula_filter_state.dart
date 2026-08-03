import 'package:calcademy/features/formula_library/domain/formula_category.dart';

class FormulaFilterState {
  const FormulaFilterState({this.query = '', this.category});

  final String query;
  final FormulaCategory? category;

  FormulaFilterState copyWith({
    String? query,
    FormulaCategory? category,
    bool clearCategory = false,
  }) => FormulaFilterState(
    query: query ?? this.query,
    category: clearCategory ? null : category ?? this.category,
  );
}

import 'package:calcademy/features/formula_library/domain/formula_category.dart';

class FormulaFilterState {
  const FormulaFilterState({
    this.query = '',
    this.category,
    this.favoritesOnly = false,
  });

  final String query;
  final FormulaCategory? category;
  final bool favoritesOnly;

  FormulaFilterState copyWith({
    String? query,
    FormulaCategory? category,
    bool? favoritesOnly,
    bool clearCategory = false,
  }) => FormulaFilterState(
    query: query ?? this.query,
    category: clearCategory ? null : category ?? this.category,
    favoritesOnly: favoritesOnly ?? this.favoritesOnly,
  );
}

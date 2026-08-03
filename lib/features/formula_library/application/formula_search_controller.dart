import 'package:calcademy/features/formula_library/application/formula_filter_state.dart';
import 'package:calcademy/features/formula_library/domain/formula_category.dart';
import 'package:calcademy/features/formula_library/domain/formula_entry.dart';
import 'package:calcademy/features/formula_library/domain/formula_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final formulaSearchProvider =
    NotifierProvider<FormulaSearchController, FormulaFilterState>(
      FormulaSearchController.new,
    );

final filteredFormulasProvider = Provider.family<List<FormulaEntry>, String>((
  ref,
  languageCode,
) {
  final filter = ref.watch(formulaSearchProvider);
  return FormulaRegistry.search(
    query: filter.query,
    category: filter.category,
    languageCode: languageCode,
  );
});

class FormulaSearchController extends Notifier<FormulaFilterState> {
  @override
  FormulaFilterState build() => const FormulaFilterState();

  void setQuery(String value) => state = state.copyWith(query: value);

  void setCategory(FormulaCategory? value) => state = value == null
      ? state.copyWith(clearCategory: true)
      : state.copyWith(category: value);

  void reset() => state = const FormulaFilterState();
}

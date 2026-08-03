import 'package:calcademy/features/formula_library/application/formula_filter_state.dart';
import 'package:calcademy/features/formula_library/application/formula_favorites_controller.dart';
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
  final matches = FormulaRegistry.search(
    query: filter.query,
    category: filter.category,
    languageCode: languageCode,
  );
  if (!filter.favoritesOnly) return matches;
  final favorites = ref.watch(formulaFavoritesProvider);
  return matches
      .where((formula) => favorites.contains(formula.id))
      .toList(growable: false);
});

class FormulaSearchController extends Notifier<FormulaFilterState> {
  @override
  FormulaFilterState build() => const FormulaFilterState();

  void setQuery(String value) => state = state.copyWith(query: value);

  void setCategory(FormulaCategory? value) => state = value == null
      ? state.copyWith(clearCategory: true)
      : state.copyWith(category: value);

  void setFavoritesOnly(bool value) =>
      state = state.copyWith(favoritesOnly: value);

  void reset() => state = const FormulaFilterState();
}

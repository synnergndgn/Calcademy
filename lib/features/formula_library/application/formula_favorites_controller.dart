import 'package:calcademy/core/services/preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final formulaFavoritesProvider =
    NotifierProvider<FormulaFavoritesController, Set<String>>(
      FormulaFavoritesController.new,
    );

class FormulaFavoritesController extends Notifier<Set<String>> {
  static const storageKey = 'formula_library.favorite_ids';

  @override
  Set<String> build() =>
      ref.watch(sharedPreferencesProvider).getStringList(storageKey)?.toSet() ??
      <String>{};

  Future<void> toggle(String formulaId) async {
    final next = {...state};
    next.contains(formulaId) ? next.remove(formulaId) : next.add(formulaId);
    state = next;
    final sorted = next.toList()..sort();
    await ref.read(sharedPreferencesProvider).setStringList(storageKey, sorted);
  }
}

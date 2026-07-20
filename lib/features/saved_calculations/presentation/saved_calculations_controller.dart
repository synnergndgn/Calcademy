import 'package:calcademy/features/saved_calculations/application/saved_calculations_service.dart';
import 'package:calcademy/features/saved_calculations/data/saved_calculations_repository.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_failure.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_limits.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final savedCalculationsServiceProvider = Provider<SavedCalculationsService>(
  (ref) => SavedCalculationsService(),
);

final savedCalculationsProvider =
    NotifierProvider<SavedCalculationsController, SavedCalculationsState>(
      SavedCalculationsController.new,
    );

class SavedCalculationsState {
  const SavedCalculationsState({
    this.items = const [],
    this.query = '',
    this.scope = SavedCalculationsScope.all,
    this.module,
    this.sort = SavedCalculationsSort.newestFirst,
    this.error,
    this.skippedItemCount = 0,
  });

  final List<SavedCalculation> items;
  final String query;
  final SavedCalculationsScope scope;
  final SavedCalculationModule? module;
  final SavedCalculationsSort sort;
  final SavedCalculationsIssue? error;
  final int skippedItemCount;

  SavedCalculationsState copyWith({
    List<SavedCalculation>? items,
    String? query,
    SavedCalculationsScope? scope,
    SavedCalculationModule? module,
    bool clearModule = false,
    SavedCalculationsSort? sort,
    SavedCalculationsIssue? error,
    bool clearError = false,
    int? skippedItemCount,
  }) => SavedCalculationsState(
    items: items ?? this.items,
    query: query ?? this.query,
    scope: scope ?? this.scope,
    module: clearModule ? null : module ?? this.module,
    sort: sort ?? this.sort,
    error: clearError ? null : error ?? this.error,
    skippedItemCount: skippedItemCount ?? this.skippedItemCount,
  );
}

class SavedCalculationsController extends Notifier<SavedCalculationsState> {
  @override
  SavedCalculationsState build() => _load();

  List<SavedCalculation> get visibleItems {
    final current = state;
    return ref
        .read(savedCalculationsServiceProvider)
        .apply(
          items: current.items,
          query: current.query,
          scope: current.scope,
          module: current.module,
          sort: current.sort,
        );
  }

  Future<SavedCalculation> save(SavedCalculationDraft draft) async {
    if (state.items.length >= SavedCalculationsLimits.maxSavedItemCount) {
      throw const SavedCalculationsException(SavedCalculationsIssue.itemLimit);
    }
    final item = ref.read(savedCalculationsServiceProvider).create(draft);
    await ref.read(savedCalculationsRepositoryProvider).add(item);
    state = state.copyWith(items: [item, ...state.items], clearError: true);
    return item;
  }

  void setQuery(String query) {
    if (query.length > SavedCalculationsLimits.maxSearchQueryLength) {
      throw const SavedCalculationsException(
        SavedCalculationsIssue.searchQueryTooLong,
      );
    }
    state = state.copyWith(query: query);
  }

  void setScope(SavedCalculationsScope scope) {
    state = state.copyWith(scope: scope);
  }

  void setModule(SavedCalculationModule? module) {
    state = state.copyWith(module: module, clearModule: module == null);
  }

  void setSort(SavedCalculationsSort sort) {
    state = state.copyWith(sort: sort);
  }

  Future<void> toggleFavorite(String id) async {
    final item = state.items.firstWhere((item) => item.id == id);
    final updatedAt = DateTime.now().toUtc();
    await ref
        .read(savedCalculationsRepositoryProvider)
        .setFavorite(id, !item.isFavorite, updatedAt);
    state = state.copyWith(
      items: [
        for (final current in state.items)
          if (current.id == id)
            current.copyWith(
              isFavorite: !current.isFavorite,
              updatedAt: updatedAt,
            )
          else
            current,
      ],
      clearError: true,
    );
  }

  Future<void> delete(String id) async {
    await ref.read(savedCalculationsRepositoryProvider).delete(id);
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
      clearError: true,
    );
  }

  Future<void> clear() async {
    await ref.read(savedCalculationsRepositoryProvider).clear();
    state = state.copyWith(items: const [], clearError: true);
  }

  void reload() => state = _load();

  SavedCalculationsState _load() {
    try {
      final loaded = ref.read(savedCalculationsRepositoryProvider).load();
      return SavedCalculationsState(
        items: loaded.items,
        skippedItemCount: loaded.skippedItemCount,
      );
    } on SavedCalculationsException catch (error) {
      return SavedCalculationsState(error: error.issue);
    } on Object {
      return const SavedCalculationsState(
        error: SavedCalculationsIssue.storageRead,
      );
    }
  }
}

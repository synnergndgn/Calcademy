import 'dart:convert';

import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/graph/domain/saved_graph.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final graphRepositoryProvider = Provider<GraphRepository>(
  (ref) => GraphRepository(ref.watch(sharedPreferencesProvider)),
);

final savedGraphsProvider =
    NotifierProvider<SavedGraphsController, List<SavedGraph>>(
      SavedGraphsController.new,
    );

class SavedGraphsController extends Notifier<List<SavedGraph>> {
  GraphRepository get _repository => ref.read(graphRepositoryProvider);

  @override
  List<SavedGraph> build() => ref.watch(graphRepositoryProvider).load();

  SavedGraph? find(String id) {
    for (final graph in state) {
      if (graph.id == id) return graph;
    }
    return null;
  }

  Future<void> upsert(SavedGraph graph) async {
    final exists = state.any((item) => item.id == graph.id);
    state = exists
        ? [
            for (final item in state)
              if (item.id == graph.id) graph else item,
          ]
        : [graph, ...state];
    await _repository.save(state);
  }

  Future<void> delete(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _repository.save(state);
  }
}

class GraphRepository {
  const GraphRepository(this.preferences);

  static const _savedGraphsKey = 'graph.saved';
  final SharedPreferences preferences;

  List<SavedGraph> load() {
    final source = preferences.getString(_savedGraphsKey);
    if (source == null) return [];
    try {
      return (jsonDecode(source) as List<Object?>)
          .whereType<Map<String, Object?>>()
          .map(SavedGraph.fromJson)
          .toList();
    } on Object {
      return [];
    }
  }

  Future<void> save(List<SavedGraph> graphs) {
    return preferences.setString(
      _savedGraphsKey,
      jsonEncode(graphs.map((item) => item.toJson()).toList()),
    );
  }
}

import 'dart:convert';

import 'package:calcademy/features/graph/data/graph_repository.dart';
import 'package:calcademy/features/graph/domain/graph_expression.dart';
import 'package:calcademy/features/graph/domain/graph_function.dart';
import 'package:calcademy/features/graph/domain/graph_range.dart';
import 'package:calcademy/features/graph/domain/saved_graph.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'repository skips a corrupt graph and preserves valid workspaces',
    () async {
      final valid = SavedGraph(
        id: 'graph-valid',
        title: 'Valid',
        functions: const [
          GraphFunction(id: 'f1', expression: 'sin(x)', visualIndex: 0),
        ],
        range: const GraphRange(),
        autoY: true,
        angleMode: GraphAngleMode.radians,
        createdAt: DateTime.utc(2026, 8, 10),
      );
      SharedPreferences.setMockInitialValues({
        'graph.saved': jsonEncode([
          {'id': 'corrupt'},
          valid.toJson(),
        ]),
      });
      final repository = GraphRepository(await SharedPreferences.getInstance());

      expect(repository.load().map((item) => item.id), ['graph-valid']);
    },
  );

  test(
    'repository falls back for malformed and wrong-shaped payloads',
    () async {
      SharedPreferences.setMockInitialValues({'graph.saved': '{broken'});
      var repository = GraphRepository(await SharedPreferences.getInstance());
      expect(repository.load(), isEmpty);

      SharedPreferences.setMockInitialValues({
        'graph.saved': jsonEncode({'items': []}),
      });
      repository = GraphRepository(await SharedPreferences.getInstance());
      expect(repository.load(), isEmpty);
    },
  );
}

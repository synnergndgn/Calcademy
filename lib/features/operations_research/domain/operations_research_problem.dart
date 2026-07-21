import 'dart:collection';

enum OperationsResearchObjective { minimize, maximize }

enum TransportationInitialMethod { northWestCorner, leastCost }

class TransportationProblem {
  TransportationProblem({
    required List<List<double>> costs,
    required List<double> supply,
    required List<double> demand,
    this.objective = OperationsResearchObjective.minimize,
    this.initialMethod = TransportationInitialMethod.leastCost,
  }) : costs = UnmodifiableListView([
         for (final row in costs) UnmodifiableListView(row),
       ]),
       supply = UnmodifiableListView(supply),
       demand = UnmodifiableListView(demand);

  final List<List<double>> costs;
  final List<double> supply;
  final List<double> demand;
  final OperationsResearchObjective objective;
  final TransportationInitialMethod initialMethod;

  int get sourceCount => costs.length;
  int get destinationCount => costs.isEmpty ? 0 : costs.first.length;
}

class AssignmentProblem {
  AssignmentProblem({
    required List<List<double>> values,
    this.objective = OperationsResearchObjective.minimize,
  }) : values = UnmodifiableListView([
         for (final row in values) UnmodifiableListView(row),
       ]);

  final List<List<double>> values;
  final OperationsResearchObjective objective;

  int get rowCount => values.length;
  int get columnCount => values.isEmpty ? 0 : values.first.length;
}

import 'dart:collection';

enum SimplexPhase { primal, phaseOne, phaseTwo }

class SimplexTableau {
  SimplexTableau({
    required List<String> columnNames,
    required List<List<double>> rows,
    required List<int> basis,
  }) : columnNames = UnmodifiableListView(columnNames),
       rows = UnmodifiableListView(
         rows.map((row) => UnmodifiableListView(row)),
       ),
       basis = UnmodifiableListView(basis);

  final List<String> columnNames;
  final List<List<double>> rows;
  final List<int> basis;

  List<double> get objectiveRow => rows.last;
}

class SimplexIteration {
  const SimplexIteration({
    required this.number,
    required this.phase,
    required this.tableau,
    required this.explanation,
    this.enteringColumn,
    this.leavingRow,
    this.pivotValue,
    this.ratios = const [],
    this.rowOperations = const [],
  });

  final int number;
  final SimplexPhase phase;
  final SimplexTableau tableau;
  final int? enteringColumn;
  final int? leavingRow;
  final double? pivotValue;
  final List<double?> ratios;
  final List<String> rowOperations;
  final String explanation;
}

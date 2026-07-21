import 'dart:collection';

import 'package:calcademy/features/operations_research/application/operations_research_validation.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_limits.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_problem.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';

class TransportationSolver {
  const TransportationSolver();

  OperationsResearchResult solve(TransportationProblem problem) {
    final issue = OperationsResearchValidation.transportation(problem);
    if (issue != null) return OperationsResearchFailureResult(issue);
    try {
      final balanced = balanceTransportation(problem);
      final optimizationCosts = _optimizationCosts(
        balanced.values,
        problem.objective,
      );
      final initial = _buildInitial(
        balanced: balanced,
        optimizationCosts: optimizationCosts,
        method: problem.initialMethod,
      );
      final improved = _improveWithModi(
        optimizationCosts,
        initial.allocations,
        initial.basis,
      );
      final totalValue = _totalValue(balanced.values, improved.allocations);
      final warnings = <String>[
        if (balanced.dummyDestinationIndex != null) 'orWarningDummyDestination',
        if (balanced.dummySourceIndex != null) 'orWarningDummySource',
        if (initial.degenerate || improved.degenerate) 'orWarningDegenerate',
        if (!improved.optimal) 'orWarningInitialOnly',
      ];
      return TransportationResult(
        objective: problem.objective,
        initialMethod: problem.initialMethod,
        allocations: improved.allocations,
        totalValue: totalValue,
        originalSourceCount: balanced.originalSourceCount,
        originalDestinationCount: balanced.originalDestinationCount,
        balancedSourceCount: balanced.supply.length,
        balancedDestinationCount: balanced.demand.length,
        totalSupply: balanced.originalTotalSupply,
        totalDemand: balanced.originalTotalDemand,
        isOptimal: improved.optimal,
        isInitialOnly: !improved.optimal,
        iterations: improved.iterations,
        degenerate: initial.degenerate || improved.degenerate,
        warnings: warnings,
        dummySourceIndex: balanced.dummySourceIndex,
        dummyDestinationIndex: balanced.dummyDestinationIndex,
      );
    } on Object {
      return const OperationsResearchFailureResult(
        OperationsResearchIssue.solverFailure,
      );
    }
  }

  TransportationInitialSolution buildInitial(TransportationProblem problem) {
    final issue = OperationsResearchValidation.transportation(problem);
    if (issue != null) {
      throw StateError('Invalid transportation problem: ${issue.name}');
    }
    final balanced = balanceTransportation(problem);
    return _buildInitial(
      balanced: balanced,
      optimizationCosts: _optimizationCosts(balanced.values, problem.objective),
      method: problem.initialMethod,
    );
  }

  TransportationInitialSolution _buildInitial({
    required BalancedTransportationProblem balanced,
    required List<List<double>> optimizationCosts,
    required TransportationInitialMethod method,
  }) {
    final allocations = [
      for (var row = 0; row < balanced.supply.length; row++)
        List<double>.filled(balanced.demand.length, 0),
    ];
    final basis = <(int, int)>{};
    switch (method) {
      case TransportationInitialMethod.northWestCorner:
        _northWestCorner(balanced.supply, balanced.demand, allocations, basis);
      case TransportationInitialMethod.leastCost:
        _leastCost(
          balanced.supply,
          balanced.demand,
          optimizationCosts,
          allocations,
          basis,
        );
    }
    final requiredBasis = balanced.supply.length + balanced.demand.length - 1;
    final degenerate = basis.length < requiredBasis;
    _completeBasis(basis, balanced.supply.length, balanced.demand.length);
    return TransportationInitialSolution(
      allocations: allocations,
      basis: basis,
      value: _totalValue(balanced.values, allocations),
      degenerate: degenerate,
    );
  }

  void _northWestCorner(
    List<double> supply,
    List<double> demand,
    List<List<double>> allocations,
    Set<(int, int)> basis,
  ) {
    final remainingSupply = List<double>.from(supply);
    final remainingDemand = List<double>.from(demand);
    var row = 0;
    var column = 0;
    while (row < supply.length && column < demand.length) {
      final value = remainingSupply[row] < remainingDemand[column]
          ? remainingSupply[row]
          : remainingDemand[column];
      allocations[row][column] = value;
      basis.add((row, column));
      remainingSupply[row] -= value;
      remainingDemand[column] -= value;
      final rowDone =
          remainingSupply[row].abs() <= OperationsResearchLimits.tolerance;
      final columnDone =
          remainingDemand[column].abs() <= OperationsResearchLimits.tolerance;
      if (rowDone) row++;
      if (columnDone) column++;
    }
  }

  void _leastCost(
    List<double> supply,
    List<double> demand,
    List<List<double>> costs,
    List<List<double>> allocations,
    Set<(int, int)> basis,
  ) {
    final remainingSupply = List<double>.from(supply);
    final remainingDemand = List<double>.from(demand);
    final cells =
        <(int, int)>[
          for (var row = 0; row < supply.length; row++)
            for (var column = 0; column < demand.length; column++)
              (row, column),
        ]..sort((a, b) {
          final byCost = costs[a.$1][a.$2].compareTo(costs[b.$1][b.$2]);
          if (byCost != 0) return byCost;
          final byRow = a.$1.compareTo(b.$1);
          return byRow != 0 ? byRow : a.$2.compareTo(b.$2);
        });
    for (final cell in cells) {
      final row = cell.$1;
      final column = cell.$2;
      if (remainingSupply[row] <= OperationsResearchLimits.tolerance ||
          remainingDemand[column] <= OperationsResearchLimits.tolerance) {
        continue;
      }
      final value = remainingSupply[row] < remainingDemand[column]
          ? remainingSupply[row]
          : remainingDemand[column];
      allocations[row][column] = value;
      basis.add(cell);
      remainingSupply[row] -= value;
      remainingDemand[column] -= value;
    }
  }

  _ModiOutcome _improveWithModi(
    List<List<double>> costs,
    List<List<double>> initialAllocations,
    Set<(int, int)> initialBasis,
  ) {
    final rows = costs.length;
    final columns = costs.first.length;
    final allocations = [
      for (final row in initialAllocations) List<double>.from(row),
    ];
    final basis = Set<(int, int)>.from(initialBasis);
    _completeBasis(basis, rows, columns);
    var degenerate = false;
    for (
      var iteration = 0;
      iteration < OperationsResearchLimits.maxIterations;
      iteration++
    ) {
      final potentials = _potentials(costs, basis);
      (int, int)? entering;
      var bestReducedCost = -OperationsResearchLimits.tolerance;
      for (var row = 0; row < rows; row++) {
        for (var column = 0; column < columns; column++) {
          if (basis.contains((row, column))) continue;
          final reduced =
              costs[row][column] - potentials.$1[row] - potentials.$2[column];
          if (reduced < bestReducedCost) {
            bestReducedCost = reduced;
            entering = (row, column);
          }
        }
      }
      if (entering == null) {
        return _ModiOutcome(
          allocations: allocations,
          iterations: iteration,
          optimal: true,
          degenerate: degenerate,
        );
      }
      final cycle = _cycleForEntering(entering, basis, rows, columns);
      if (cycle == null || cycle.length < 4 || cycle.length.isOdd) {
        return _ModiOutcome(
          allocations: allocations,
          iterations: iteration,
          optimal: false,
          degenerate: degenerate,
        );
      }
      var theta = double.infinity;
      for (var index = 1; index < cycle.length; index += 2) {
        final cell = cycle[index];
        final value = allocations[cell.$1][cell.$2];
        if (value < theta) theta = value;
      }
      if (!theta.isFinite) {
        return _ModiOutcome(
          allocations: allocations,
          iterations: iteration,
          optimal: false,
          degenerate: degenerate,
        );
      }
      if (theta <= OperationsResearchLimits.tolerance) degenerate = true;
      basis.add(entering);
      (int, int)? leaving;
      for (var index = 0; index < cycle.length; index++) {
        final cell = cycle[index];
        if (index.isEven) {
          allocations[cell.$1][cell.$2] += theta;
        } else {
          allocations[cell.$1][cell.$2] -= theta;
          if (allocations[cell.$1][cell.$2].abs() <=
              OperationsResearchLimits.tolerance) {
            allocations[cell.$1][cell.$2] = 0;
            leaving ??= cell;
          }
        }
      }
      if (leaving == null) {
        return _ModiOutcome(
          allocations: allocations,
          iterations: iteration + 1,
          optimal: false,
          degenerate: degenerate,
        );
      }
      basis.remove(leaving);
    }
    return _ModiOutcome(
      allocations: allocations,
      iterations: OperationsResearchLimits.maxIterations,
      optimal: false,
      degenerate: degenerate,
    );
  }

  (List<double>, List<double>) _potentials(
    List<List<double>> costs,
    Set<(int, int)> basis,
  ) {
    final rowPotentials = List<double?>.filled(costs.length, null);
    final columnPotentials = List<double?>.filled(costs.first.length, null);
    rowPotentials[0] = 0;
    var changed = true;
    while (changed) {
      changed = false;
      for (final cell in basis) {
        final row = cell.$1;
        final column = cell.$2;
        if (rowPotentials[row] != null && columnPotentials[column] == null) {
          columnPotentials[column] = costs[row][column] - rowPotentials[row]!;
          changed = true;
        } else if (columnPotentials[column] != null &&
            rowPotentials[row] == null) {
          rowPotentials[row] = costs[row][column] - columnPotentials[column]!;
          changed = true;
        }
      }
    }
    return (
      rowPotentials.map((value) => value ?? 0).toList(),
      columnPotentials.map((value) => value ?? 0).toList(),
    );
  }

  List<(int, int)>? _cycleForEntering(
    (int, int) entering,
    Set<(int, int)> basis,
    int rows,
    int columns,
  ) {
    final nodeCount = rows + columns;
    final adjacency = List.generate(
      nodeCount,
      (_) => <({int node, (int, int) cell})>[],
    );
    for (final cell in basis) {
      final rowNode = cell.$1;
      final columnNode = rows + cell.$2;
      adjacency[rowNode].add((node: columnNode, cell: cell));
      adjacency[columnNode].add((node: rowNode, cell: cell));
    }
    final start = rows + entering.$2;
    final target = entering.$1;
    final parent = List<int>.filled(nodeCount, -1);
    final parentCell = List<(int, int)?>.filled(nodeCount, null);
    final queue = Queue<int>()..add(start);
    parent[start] = start;
    while (queue.isNotEmpty && parent[target] == -1) {
      final node = queue.removeFirst();
      for (final next in adjacency[node]) {
        if (parent[next.node] != -1) continue;
        parent[next.node] = node;
        parentCell[next.node] = next.cell;
        queue.add(next.node);
      }
    }
    if (parent[target] == -1) return null;
    final reversePath = <(int, int)>[];
    var current = target;
    while (current != start) {
      reversePath.add(parentCell[current]!);
      current = parent[current];
    }
    return [entering, ...reversePath.reversed];
  }

  void _completeBasis(Set<(int, int)> basis, int rows, int columns) {
    final dsu = _DisjointSet(rows + columns);
    final treeBasis = <(int, int)>{};
    for (final cell in basis) {
      if (dsu.union(cell.$1, rows + cell.$2)) treeBasis.add(cell);
    }
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        if (treeBasis.length >= rows + columns - 1) break;
        final cell = (row, column);
        if (treeBasis.contains(cell)) continue;
        if (dsu.union(row, rows + column)) treeBasis.add(cell);
      }
    }
    basis
      ..clear()
      ..addAll(treeBasis);
  }

  List<List<double>> _optimizationCosts(
    List<List<double>> values,
    OperationsResearchObjective objective,
  ) => [
    for (final row in values)
      [
        for (final value in row)
          objective == OperationsResearchObjective.minimize ? value : -value,
      ],
  ];

  double _totalValue(
    List<List<double>> values,
    List<List<double>> allocations,
  ) {
    var total = 0.0;
    for (var row = 0; row < values.length; row++) {
      for (var column = 0; column < values[row].length; column++) {
        total += values[row][column] * allocations[row][column];
      }
    }
    return total;
  }
}

class _ModiOutcome {
  const _ModiOutcome({
    required this.allocations,
    required this.iterations,
    required this.optimal,
    required this.degenerate,
  });

  final List<List<double>> allocations;
  final int iterations;
  final bool optimal;
  final bool degenerate;
}

class _DisjointSet {
  _DisjointSet(int size) : _parent = List.generate(size, (index) => index);

  final List<int> _parent;

  int find(int value) {
    if (_parent[value] != value) _parent[value] = find(_parent[value]);
    return _parent[value];
  }

  bool union(int first, int second) {
    final firstRoot = find(first);
    final secondRoot = find(second);
    if (firstRoot == secondRoot) return false;
    _parent[secondRoot] = firstRoot;
    return true;
  }
}

import 'package:calcademy/features/operations_research/domain/operations_research_limits.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_problem.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';

abstract final class OperationsResearchValidation {
  static OperationsResearchIssue? transportation(
    TransportationProblem problem,
  ) {
    final sources = problem.costs.length;
    if (sources < OperationsResearchLimits.minTransportationSources) {
      return OperationsResearchIssue.invalidSourceCount;
    }
    if (sources > OperationsResearchLimits.maxTransportationSources) {
      return OperationsResearchIssue.tooLarge;
    }
    final destinations = problem.costs.first.length;
    if (destinations < OperationsResearchLimits.minTransportationDestinations) {
      return OperationsResearchIssue.invalidDestinationCount;
    }
    if (destinations > OperationsResearchLimits.maxTransportationDestinations) {
      return OperationsResearchIssue.tooLarge;
    }
    if (problem.supply.length != sources ||
        problem.demand.length != destinations ||
        problem.costs.any((row) => row.length != destinations)) {
      return OperationsResearchIssue.invalidDimensions;
    }
    if (problem.costs.expand((row) => row).any((value) => !value.isFinite)) {
      return OperationsResearchIssue.invalidNumber;
    }
    if (problem.supply.any((value) => !value.isFinite) ||
        problem.demand.any((value) => !value.isFinite)) {
      return OperationsResearchIssue.invalidNumber;
    }
    if (problem.supply.any((value) => value < 0)) {
      return OperationsResearchIssue.negativeSupply;
    }
    if (problem.demand.any((value) => value < 0)) {
      return OperationsResearchIssue.negativeDemand;
    }
    final totalSupply = problem.supply.fold<double>(
      0,
      (sum, item) => sum + item,
    );
    final totalDemand = problem.demand.fold<double>(
      0,
      (sum, item) => sum + item,
    );
    if (totalSupply <= OperationsResearchLimits.tolerance) {
      return OperationsResearchIssue.zeroSupply;
    }
    if (totalDemand <= OperationsResearchLimits.tolerance) {
      return OperationsResearchIssue.zeroDemand;
    }
    if (problem.supply.any(
      (value) => value <= OperationsResearchLimits.tolerance,
    )) {
      return OperationsResearchIssue.zeroSupplyRow;
    }
    if (problem.demand.any(
      (value) => value <= OperationsResearchLimits.tolerance,
    )) {
      return OperationsResearchIssue.zeroDemandColumn;
    }
    return null;
  }

  static OperationsResearchIssue? assignment(AssignmentProblem problem) {
    final rows = problem.values.length;
    if (rows < OperationsResearchLimits.minAssignmentRows) {
      return OperationsResearchIssue.invalidAssignmentRowCount;
    }
    if (rows > OperationsResearchLimits.maxAssignmentRows) {
      return OperationsResearchIssue.tooLarge;
    }
    final columns = problem.values.first.length;
    if (columns < OperationsResearchLimits.minAssignmentColumns) {
      return OperationsResearchIssue.invalidAssignmentColumnCount;
    }
    if (columns > OperationsResearchLimits.maxAssignmentColumns) {
      return OperationsResearchIssue.tooLarge;
    }
    if (problem.values.any((row) => row.length != columns)) {
      return OperationsResearchIssue.invalidDimensions;
    }
    if (problem.values.expand((row) => row).any((value) => !value.isFinite)) {
      return OperationsResearchIssue.invalidNumber;
    }
    return null;
  }
}

class BalancedTransportationProblem {
  const BalancedTransportationProblem({
    required this.values,
    required this.supply,
    required this.demand,
    required this.originalSourceCount,
    required this.originalDestinationCount,
    required this.originalTotalSupply,
    required this.originalTotalDemand,
    this.dummySourceIndex,
    this.dummyDestinationIndex,
  });

  final List<List<double>> values;
  final List<double> supply;
  final List<double> demand;
  final int originalSourceCount;
  final int originalDestinationCount;
  final double originalTotalSupply;
  final double originalTotalDemand;
  final int? dummySourceIndex;
  final int? dummyDestinationIndex;
}

BalancedTransportationProblem balanceTransportation(
  TransportationProblem problem,
) {
  final values = [for (final row in problem.costs) List<double>.from(row)];
  final supply = List<double>.from(problem.supply);
  final demand = List<double>.from(problem.demand);
  final totalSupply = supply.fold<double>(0, (sum, item) => sum + item);
  final totalDemand = demand.fold<double>(0, (sum, item) => sum + item);
  int? dummySource;
  int? dummyDestination;
  if (totalSupply - totalDemand > OperationsResearchLimits.tolerance) {
    dummyDestination = demand.length;
    demand.add(totalSupply - totalDemand);
    for (final row in values) {
      row.add(0);
    }
  } else if (totalDemand - totalSupply > OperationsResearchLimits.tolerance) {
    dummySource = supply.length;
    supply.add(totalDemand - totalSupply);
    values.add(List<double>.filled(demand.length, 0));
  }
  return BalancedTransportationProblem(
    values: values,
    supply: supply,
    demand: demand,
    originalSourceCount: problem.sourceCount,
    originalDestinationCount: problem.destinationCount,
    originalTotalSupply: totalSupply,
    originalTotalDemand: totalDemand,
    dummySourceIndex: dummySource,
    dummyDestinationIndex: dummyDestination,
  );
}

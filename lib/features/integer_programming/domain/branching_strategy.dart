import 'dart:math' as math;

import 'package:calcademy/features/integer_programming/domain/branch_decision.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program.dart';
import 'package:calcademy/features/integer_programming/domain/mip_constants.dart';

/// How the next fractional integer/binary variable is picked at a node.
///
/// Both strategies are deterministic: ties are always broken by ascending
/// variable order (the order the variable appears in the model), so solving
/// the same model twice always explores the same tree.
enum BranchingStrategy { firstFractional, mostFractional }

/// Picks the variable to branch on, or `null` if every integer/binary
/// variable already has an (epsilon-tolerant) integer value at this node.
BranchDecision? selectBranchVariable({
  required IntegerProgram program,
  required Map<String, double> relaxationValues,
  required BranchingStrategy strategy,
}) {
  String? bestVariableId;
  String? bestVariableName;
  double bestValue = 0;
  double bestFractionality = -1;

  for (final variable in program.linearModel.variables) {
    if (!program.isIntegerOrBinary(variable.id)) continue;
    final value = relaxationValues[variable.name] ?? 0;
    final fractionality = math.min(value - value.floor(), value.ceil() - value);
    if (fractionality <= MipConstants.integerEpsilon) continue;

    final isBetter = switch (strategy) {
      BranchingStrategy.firstFractional => bestVariableId == null,
      BranchingStrategy.mostFractional =>
        fractionality > bestFractionality + MipConstants.mipEpsilon,
    };
    if (isBetter) {
      bestVariableId = variable.id;
      bestVariableName = variable.name;
      bestValue = value;
      bestFractionality = fractionality;
    }
  }

  if (bestVariableId == null) return null;
  return BranchDecision(
    variableId: bestVariableId,
    variableName: bestVariableName!,
    fractionalValue: bestValue,
    floorValue: bestValue.floorToDouble(),
    ceilValue: bestValue.ceilToDouble(),
  );
}

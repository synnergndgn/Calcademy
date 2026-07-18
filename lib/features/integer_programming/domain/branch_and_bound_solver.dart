import 'dart:math' as math;

import 'package:calcademy/features/integer_programming/domain/branch_decision.dart';
import 'package:calcademy/features/integer_programming/domain/branch_node.dart';
import 'package:calcademy/features/integer_programming/domain/branching_strategy.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program.dart';
import 'package:calcademy/features/integer_programming/domain/mip_constants.dart';
import 'package:calcademy/features/integer_programming/domain/mip_limits.dart';
import 'package:calcademy/features/integer_programming/domain/mip_result.dart';
import 'package:calcademy/features/integer_programming/domain/node_selection_strategy.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program_result.dart';
import 'package:calcademy/features/linear_programming/domain/simplex_solver.dart';

/// Solves a small/medium [IntegerProgram] with a plain, deterministic
/// Branch-and-Bound search. Every node's LP relaxation is solved by the
/// existing [SimplexSolver] - this class only adds and removes branching
/// bounds and tracks the tree, incumbent and prune statistics around it. No
/// cutting planes, warm starts or heuristics are used (see the module
/// README for what is deliberately out of scope for this release).
class BranchAndBoundSolver {
  const BranchAndBoundSolver({
    this.branchingStrategy = BranchingStrategy.mostFractional,
    this.nodeSelectionStrategy = NodeSelectionStrategy.depthFirst,
    this.limits = const MipLimits(),
    SimplexSolver? lpSolver,
  }) : _lpSolver = lpSolver ?? const SimplexSolver();

  final BranchingStrategy branchingStrategy;
  final NodeSelectionStrategy nodeSelectionStrategy;
  final MipLimits limits;
  final SimplexSolver _lpSolver;

  MipResult solve(IntegerProgram program) {
    final stopwatch = Stopwatch()..start();
    final direction = program.linearModel.direction;
    final relaxationModel = program.relaxationModel;

    var idCounter = 0;
    var orderCounter = 0;
    String nextId() => 'node${idCounter++}';

    final tree = <BranchNode>[];
    final pruneCounts = <PruneReason, int>{};
    void bumpPrune(PruneReason reason) =>
        pruneCounts[reason] = (pruneCounts[reason] ?? 0) + 1;
    final incumbentHistory = <IncumbentUpdate>[];
    final warnings = <String>[];

    Map<String, double>? incumbentValues;
    double? incumbentObjective;

    var nodesSolved = 0;
    var totalIterations = 0;
    var maxDepthReached = 0;
    var depthLimitTriggered = false;
    LimitReason? limitReason;
    final danglingBounds = <double>[];
    double? rootRelaxationObjective;

    final queue =
        NodeQueue(strategy: nodeSelectionStrategy, direction: direction)..add(
          PendingNode(
            id: nextId(),
            parentId: null,
            depth: 0,
            additionalConstraints: const [],
            estimatedBound: direction == ObjectiveDirection.maximize
                ? double.infinity
                : double.negativeInfinity,
            order: orderCounter++,
          ),
        );

    while (!queue.isEmpty) {
      if (nodesSolved >= limits.maxNodes) {
        limitReason = LimitReason.nodeLimit;
        break;
      }
      if (totalIterations >= limits.maxTotalIterations) {
        limitReason = LimitReason.iterationLimit;
        break;
      }

      final pending = queue.removeNext();
      final isRoot = pending.parentId == null;
      final augmented = _augment(
        relaxationModel,
        pending.additionalConstraints,
      );
      final lpResult = _lpSolver.solve(augmented);
      nodesSolved++;
      totalIterations += lpResult.iterationCount;
      if (pending.depth > maxDepthReached) maxDepthReached = pending.depth;

      if (lpResult.status == LinearProgramStatus.infeasible) {
        tree.add(
          _node(
            pending,
            NodeStatus.prunedInfeasible,
            pruneReason: 'mipPrunedInfeasible',
          ),
        );
        bumpPrune(PruneReason.infeasible);
        continue;
      }

      if (lpResult.status == LinearProgramStatus.unbounded) {
        if (isRoot) {
          stopwatch.stop();
          return UnboundedRelaxation(
            nodesSolved: nodesSolved,
            openNodes: queue.length,
            maxDepthReached: maxDepthReached,
            pruneCounts: pruneCounts,
            branchTree: [
              ...tree,
              _node(pending, NodeStatus.unbounded, pruneReason: 'mipUnbounded'),
            ],
            incumbentHistory: incumbentHistory,
            branchingStrategy: branchingStrategy,
            nodeSelectionStrategy: nodeSelectionStrategy,
            elapsedMicroseconds: stopwatch.elapsedMicroseconds,
            warnings: warnings,
          );
        }
        tree.add(
          _node(pending, NodeStatus.unbounded, pruneReason: 'mipUnbounded'),
        );
        bumpPrune(PruneReason.unbounded);
        warnings.add('mipWarningUnboundedNode');
        continue;
      }

      if (lpResult.status == LinearProgramStatus.numericError ||
          lpResult.status == LinearProgramStatus.iterationLimit) {
        if (isRoot) {
          stopwatch.stop();
          return NumericalFailure(
            nodesSolved: nodesSolved,
            openNodes: queue.length,
            maxDepthReached: maxDepthReached,
            pruneCounts: pruneCounts,
            branchTree: [
              ...tree,
              _node(
                pending,
                NodeStatus.error,
                pruneReason: 'mipNumericalFailure',
              ),
            ],
            incumbentHistory: incumbentHistory,
            branchingStrategy: branchingStrategy,
            nodeSelectionStrategy: nodeSelectionStrategy,
            elapsedMicroseconds: stopwatch.elapsedMicroseconds,
            warnings: warnings,
          );
        }
        tree.add(
          _node(pending, NodeStatus.error, pruneReason: 'mipNumericalFailure'),
        );
        bumpPrune(PruneReason.error);
        warnings.add('mipWarningNodeNumericalFailure');
        continue;
      }

      final feasible = lpResult as FeasibleLinearProgramResult;
      final bound = feasible.objectiveValue;
      if (isRoot) rootRelaxationObjective = bound;

      if (incumbentObjective != null) {
        final cannotImprove = direction == ObjectiveDirection.maximize
            ? bound <= incumbentObjective + MipConstants.mipEpsilon
            : bound >= incumbentObjective - MipConstants.mipEpsilon;
        if (cannotImprove) {
          tree.add(
            _node(
              pending,
              NodeStatus.prunedByBound,
              relaxationObjective: bound,
              relaxationValues: feasible.variableValues,
              pruneReason: 'mipPrunedByBound',
            ),
          );
          bumpPrune(PruneReason.bound);
          continue;
        }
      }

      final cleanedValues = <String, double>{};
      var allIntegral = true;
      for (final variable in program.linearModel.variables) {
        final raw = feasible.variableValues[variable.name] ?? 0;
        if (program.isIntegerOrBinary(variable.id)) {
          final rounded = raw.roundToDouble();
          if ((raw - rounded).abs() <= MipConstants.integerEpsilon) {
            cleanedValues[variable.name] = rounded;
          } else {
            allIntegral = false;
            cleanedValues[variable.name] = raw;
          }
        } else {
          cleanedValues[variable.name] = raw;
        }
      }

      if (allIntegral) {
        final improves =
            incumbentObjective == null ||
            (direction == ObjectiveDirection.maximize
                ? bound > incumbentObjective + MipConstants.mipEpsilon
                : bound < incumbentObjective - MipConstants.mipEpsilon);
        if (improves) {
          incumbentObjective = bound;
          incumbentValues = cleanedValues;
          incumbentHistory.add(
            IncumbentUpdate(
              nodeId: pending.id,
              objectiveValue: bound,
              variableValues: cleanedValues,
              order: pending.order,
            ),
          );
          tree.add(
            _node(
              pending,
              NodeStatus.integerFeasible,
              relaxationObjective: bound,
              relaxationValues: cleanedValues,
              pruneReason: 'mipClosedIntegerFeasible',
              isIncumbent: true,
            ),
          );
        } else {
          tree.add(
            _node(
              pending,
              NodeStatus.prunedIntegral,
              relaxationObjective: bound,
              relaxationValues: cleanedValues,
              pruneReason: 'mipPrunedIntegral',
            ),
          );
        }
        bumpPrune(PruneReason.integral);
        continue;
      }

      final decision = selectBranchVariable(
        program: program,
        relaxationValues: feasible.variableValues,
        strategy: branchingStrategy,
      );
      if (decision == null) {
        // Every integer/binary variable is within epsilon of an integer but
        // the strict rounding check above disagreed (can only happen right
        // at the epsilon boundary); treat the node as integral rather than
        // branching on nothing.
        tree.add(
          _node(
            pending,
            NodeStatus.prunedIntegral,
            relaxationObjective: bound,
            relaxationValues: cleanedValues,
            pruneReason: 'mipPrunedIntegral',
          ),
        );
        bumpPrune(PruneReason.integral);
        continue;
      }

      if (pending.depth + 1 > limits.maxDepth) {
        depthLimitTriggered = true;
        danglingBounds.add(bound);
        bumpPrune(PruneReason.depthLimit);
        tree.add(
          _node(
            pending,
            NodeStatus.fractional,
            relaxationObjective: bound,
            relaxationValues: feasible.variableValues,
            branchDecision: decision,
            pruneReason: 'mipDepthLimitReached',
          ),
        );
        continue;
      }

      tree.add(
        _node(
          pending,
          NodeStatus.fractional,
          relaxationObjective: bound,
          relaxationValues: feasible.variableValues,
          branchDecision: decision,
        ),
      );

      final floorOrder = orderCounter++;
      final ceilOrder = orderCounter++;
      final floorId = nextId();
      final ceilId = nextId();
      final ceilNode = PendingNode(
        id: ceilId,
        parentId: pending.id,
        depth: pending.depth + 1,
        additionalConstraints: [
          ...pending.additionalConstraints,
          decision.upperBranchConstraint,
        ],
        estimatedBound: bound,
        order: ceilOrder,
      );
      final floorNode = PendingNode(
        id: floorId,
        parentId: pending.id,
        depth: pending.depth + 1,
        additionalConstraints: [
          ...pending.additionalConstraints,
          decision.lowerBranchConstraint,
        ],
        estimatedBound: bound,
        order: floorOrder,
      );
      queue
        ..add(ceilNode)
        ..add(floorNode);
    }

    stopwatch.stop();
    final elapsed = stopwatch.elapsedMicroseconds;
    final openNodes = queue.remaining;
    final effectiveLimitReason =
        limitReason ?? (depthLimitTriggered ? LimitReason.depthLimit : null);

    if (effectiveLimitReason != null) {
      if (incumbentObjective != null && incumbentValues != null) {
        return FeasibleIntegerSolution(
          rootRelaxationObjective: rootRelaxationObjective,
          nodesSolved: nodesSolved,
          openNodes: openNodes.length,
          maxDepthReached: maxDepthReached,
          pruneCounts: pruneCounts,
          branchTree: tree,
          incumbentHistory: incumbentHistory,
          branchingStrategy: branchingStrategy,
          nodeSelectionStrategy: nodeSelectionStrategy,
          elapsedMicroseconds: elapsed,
          warnings: warnings,
          objectiveValue: incumbentObjective,
          variableValues: incumbentValues,
          bestBound: _globalBestBound(
            direction,
            openNodes,
            danglingBounds,
            incumbentObjective,
          ),
          limitReason: effectiveLimitReason,
        );
      }
      if (effectiveLimitReason == LimitReason.iterationLimit) {
        return IterationLimitReached(
          rootRelaxationObjective: rootRelaxationObjective,
          nodesSolved: nodesSolved,
          openNodes: openNodes.length,
          maxDepthReached: maxDepthReached,
          pruneCounts: pruneCounts,
          branchTree: tree,
          incumbentHistory: incumbentHistory,
          branchingStrategy: branchingStrategy,
          nodeSelectionStrategy: nodeSelectionStrategy,
          elapsedMicroseconds: elapsed,
          warnings: warnings,
        );
      }
      return NodeLimitReached(
        rootRelaxationObjective: rootRelaxationObjective,
        nodesSolved: nodesSolved,
        openNodes: openNodes.length,
        maxDepthReached: maxDepthReached,
        pruneCounts: pruneCounts,
        branchTree: tree,
        incumbentHistory: incumbentHistory,
        branchingStrategy: branchingStrategy,
        nodeSelectionStrategy: nodeSelectionStrategy,
        elapsedMicroseconds: elapsed,
        warnings: warnings,
        reason: effectiveLimitReason,
      );
    }

    if (incumbentObjective != null && incumbentValues != null) {
      return OptimalIntegerSolution(
        rootRelaxationObjective: rootRelaxationObjective,
        nodesSolved: nodesSolved,
        openNodes: openNodes.length,
        maxDepthReached: maxDepthReached,
        pruneCounts: pruneCounts,
        branchTree: tree,
        incumbentHistory: incumbentHistory,
        branchingStrategy: branchingStrategy,
        nodeSelectionStrategy: nodeSelectionStrategy,
        elapsedMicroseconds: elapsed,
        warnings: warnings,
        objectiveValue: incumbentObjective,
        variableValues: incumbentValues,
      );
    }

    return InfeasibleIntegerProgram(
      rootRelaxationObjective: rootRelaxationObjective,
      nodesSolved: nodesSolved,
      openNodes: openNodes.length,
      maxDepthReached: maxDepthReached,
      pruneCounts: pruneCounts,
      branchTree: tree,
      incumbentHistory: incumbentHistory,
      branchingStrategy: branchingStrategy,
      nodeSelectionStrategy: nodeSelectionStrategy,
      elapsedMicroseconds: elapsed,
      warnings: warnings,
    );
  }

  BranchNode _node(
    PendingNode pending,
    NodeStatus status, {
    double? relaxationObjective,
    Map<String, double>? relaxationValues,
    BranchDecision? branchDecision,
    String? pruneReason,
    bool isIncumbent = false,
  }) => BranchNode(
    id: pending.id,
    parentId: pending.parentId,
    depth: pending.depth,
    additionalConstraints: pending.additionalConstraints,
    status: status,
    order: pending.order,
    relaxationObjective: relaxationObjective,
    relaxationValues: relaxationValues,
    branchDecision: branchDecision,
    pruneReason: pruneReason,
    isIncumbent: isIncumbent,
  );

  double _globalBestBound(
    ObjectiveDirection direction,
    List<PendingNode> openNodes,
    List<double> danglingBounds,
    double incumbentObjective,
  ) {
    final candidates = [
      ...openNodes.map((node) => node.estimatedBound),
      ...danglingBounds,
    ];
    if (candidates.isEmpty) return incumbentObjective;
    return direction == ObjectiveDirection.maximize
        ? candidates.reduce(math.max)
        : candidates.reduce(math.min);
  }

  /// Combines a node's ancestor branching decisions into at most two extra
  /// bound rows per variable (the tightest lower and upper bound seen along
  /// the path), then appends them to [base] through the unchecked
  /// constructor so a deep tree never runs into the LP editor's own
  /// constraint-count ceiling.
  LinearProgram _augment(LinearProgram base, List<BranchConstraint> path) {
    if (path.isEmpty) return base;
    final lowerBounds = <String, double>{};
    final upperBounds = <String, double>{};
    for (final constraint in path) {
      if (constraint.direction == BranchDirection.upperBranch) {
        final current = lowerBounds[constraint.variableId];
        lowerBounds[constraint.variableId] = current == null
            ? constraint.bound
            : math.max(current, constraint.bound);
      } else {
        final current = upperBounds[constraint.variableId];
        upperBounds[constraint.variableId] = current == null
            ? constraint.bound
            : math.min(current, constraint.bound);
      }
    }

    final indexById = {
      for (var index = 0; index < base.variables.length; index++)
        base.variables[index].id: index,
    };
    final nameById = {
      for (final variable in base.variables) variable.id: variable.name,
    };

    LinearConstraint bound(
      String variableId,
      double value,
      ConstraintRelation relation,
      String tag,
    ) {
      final index = indexById[variableId]!;
      final symbol = relation == ConstraintRelation.lessOrEqual ? '≤' : '≥';
      return LinearConstraint(
        id: 'branch-$variableId-$tag',
        name: '${nameById[variableId]} $symbol ${value.toStringAsFixed(0)}',
        coefficients: [
          for (var column = 0; column < base.variables.length; column++)
            column == index ? 1.0 : 0.0,
        ],
        relation: relation,
        rhs: value,
      );
    }

    final extra = <LinearConstraint>[
      for (final entry in lowerBounds.entries)
        bound(entry.key, entry.value, ConstraintRelation.greaterOrEqual, 'ge'),
      for (final entry in upperBounds.entries)
        bound(entry.key, entry.value, ConstraintRelation.lessOrEqual, 'le'),
    ];

    return LinearProgram.unchecked(
      title: base.title,
      direction: base.direction,
      variables: base.variables,
      objective: base.objective,
      constraints: [...base.constraints, ...extra],
    );
  }
}

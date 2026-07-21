import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart'
    show parseLpNumber;
import 'package:calcademy/features/operations_research/domain/goal_programming_problem.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_limits.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';
import 'package:calcademy/features/operations_research/presentation/operations_research_controller.dart';
import 'package:calcademy/features/operations_research/presentation/operations_research_input_widgets.dart';
import 'package:calcademy/features/operations_research/presentation/operations_research_result_card.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoalProgrammingTab extends ConsumerStatefulWidget {
  const GoalProgrammingTab({super.key});

  @override
  ConsumerState<GoalProgrammingTab> createState() => _GoalProgrammingTabState();
}

class _GoalProgrammingTabState extends ConsumerState<GoalProgrammingTab> {
  var _variables = 2;
  var _hardCount = 1;
  var _goalCount = 1;
  final _hardCoefficients = <List<TextEditingController>>[];
  final _hardRhs = <TextEditingController>[];
  final _hardRelations = <GoalConstraintRelation>[];
  final _goalCoefficients = <List<TextEditingController>>[];
  final _goalTargets = <TextEditingController>[];
  final _underWeights = <TextEditingController>[];
  final _overWeights = <TextEditingController>[];
  final _goalRelations = <GoalTargetRelation>[];

  @override
  void initState() {
    super.initState();
    _initializeEditors();
  }

  void _initializeEditors() {
    for (var index = 0; index < _hardCount; index++) {
      _addHardConstraint();
    }
    for (var index = 0; index < _goalCount; index++) {
      _addGoal();
    }
  }

  TextEditingController _number([String value = '0']) =>
      TextEditingController(text: value);

  void _addHardConstraint() {
    _hardCoefficients.add([
      for (var index = 0; index < _variables; index++)
        _number(index == 0 ? '1' : '0'),
    ]);
    _hardRhs.add(_number('10'));
    _hardRelations.add(GoalConstraintRelation.lessOrEqual);
  }

  void _addGoal() {
    _goalCoefficients.add([
      for (var index = 0; index < _variables; index++) _number('1'),
    ]);
    _goalTargets.add(_number('10'));
    _underWeights.add(_number('1'));
    _overWeights.add(_number('1'));
    _goalRelations.add(GoalTargetRelation.equal);
  }

  void _resizeVariables(int value) {
    for (final row in [..._hardCoefficients, ..._goalCoefficients]) {
      while (row.length < value) {
        row.add(_number());
      }
      while (row.length > value) {
        row.removeLast().dispose();
      }
    }
    _variables = value;
  }

  void _resizeHardConstraints(int value) {
    while (_hardCoefficients.length < value) {
      _addHardConstraint();
    }
    while (_hardCoefficients.length > value) {
      for (final controller in _hardCoefficients.removeLast()) {
        controller.dispose();
      }
      _hardRhs.removeLast().dispose();
      _hardRelations.removeLast();
    }
    _hardCount = value;
  }

  void _resizeGoals(int value) {
    while (_goalCoefficients.length < value) {
      _addGoal();
    }
    while (_goalCoefficients.length > value) {
      for (final controller in _goalCoefficients.removeLast()) {
        controller.dispose();
      }
      _goalTargets.removeLast().dispose();
      _underWeights.removeLast().dispose();
      _overWeights.removeLast().dispose();
      _goalRelations.removeLast();
    }
    _goalCount = value;
  }

  Future<void> _solve() async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final problem = GoalProgrammingProblem(
        variableCount: _variables,
        hardConstraints: [
          for (var row = 0; row < _hardCount; row++)
            GoalHardConstraint(
              coefficients: [
                for (final controller in _hardCoefficients[row])
                  parseLpNumber(controller.text),
              ],
              relation: _hardRelations[row],
              rhs: parseLpNumber(_hardRhs[row].text),
            ),
        ],
        goals: [
          for (var row = 0; row < _goalCount; row++)
            GoalTarget(
              coefficients: [
                for (final controller in _goalCoefficients[row])
                  parseLpNumber(controller.text),
              ],
              relation: _goalRelations[row],
              target: parseLpNumber(_goalTargets[row].text),
              underWeight: parseLpNumber(_underWeights[row].text),
              overWeight: parseLpNumber(_overWeights[row].text),
            ),
        ],
      );
      await ref
          .read(operationsResearchProvider.notifier)
          .solveGoalProgramming(problem);
    } on FormatException {
      ref
          .read(operationsResearchProvider.notifier)
          .reportIssue(OperationsResearchIssue.invalidNumber);
    }
  }

  void _clear() {
    for (final row in _hardCoefficients) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    for (final controller in _hardRhs) {
      controller.dispose();
    }
    for (final row in _goalCoefficients) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    for (final controller in [
      ..._goalTargets,
      ..._underWeights,
      ..._overWeights,
    ]) {
      controller.dispose();
    }
    _hardCoefficients.clear();
    _hardRhs.clear();
    _hardRelations.clear();
    _goalCoefficients.clear();
    _goalTargets.clear();
    _underWeights.clear();
    _overWeights.clear();
    _goalRelations.clear();
    setState(() {
      _variables = 2;
      _hardCount = 1;
      _goalCount = 1;
      _initializeEditors();
    });
    ref.read(operationsResearchProvider.notifier).clear();
  }

  @override
  void dispose() {
    for (final row in [..._hardCoefficients, ..._goalCoefficients]) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    for (final controller in [
      ..._hardRhs,
      ..._goalTargets,
      ..._underWeights,
      ..._overWeights,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(operationsResearchProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            OrCountSelector(
              label: l10n.t('orDecisionVariables'),
              value: _variables,
              minimum: OperationsResearchLimits.minGoalVariables,
              maximum: OperationsResearchLimits.maxGoalVariables,
              onChanged: (value) {
                setState(() => _resizeVariables(value));
                ref.read(operationsResearchProvider.notifier).clear();
              },
              increaseKey: const Key('or-goal-add-variable'),
            ),
            OrCountSelector(
              label: l10n.t('orHardConstraints'),
              value: _hardCount,
              minimum: OperationsResearchLimits.minHardConstraints,
              maximum: OperationsResearchLimits.maxHardConstraints,
              onChanged: (value) {
                setState(() => _resizeHardConstraints(value));
                ref.read(operationsResearchProvider.notifier).clear();
              },
              increaseKey: const Key('or-goal-add-hard'),
            ),
            OrCountSelector(
              label: l10n.t('orGoals'),
              value: _goalCount,
              minimum: OperationsResearchLimits.minGoals,
              maximum: OperationsResearchLimits.maxGoals,
              onChanged: (value) {
                setState(() => _resizeGoals(value));
                ref.read(operationsResearchProvider.notifier).clear();
              },
              increaseKey: const Key('or-goal-add-goal'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.t('orNonNegativeVariables'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.t('orHardConstraints'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (_hardCount == 0) Text(l10n.t('orNoHardConstraints')),
        if (_hardCount > 0)
          SingleChildScrollView(
            key: const Key('or-goal-hard-grid-scroll'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Column(
              children: [
                for (var row = 0; row < _hardCount; row++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        SizedBox(width: 38, child: Text('H${row + 1}')),
                        for (var column = 0; column < _variables; column++) ...[
                          OrMatrixField(
                            controller: _hardCoefficients[row][column],
                            label: 'x${column + 1}',
                            fieldKey: Key('or-goal-hard-$row-$column'),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                        ],
                        SizedBox(
                          width: 96,
                          child:
                              DropdownButtonFormField<GoalConstraintRelation>(
                                key: Key('or-goal-hard-relation-$row'),
                                initialValue: _hardRelations[row],
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                    value: GoalConstraintRelation.lessOrEqual,
                                    child: Text('≤'),
                                  ),
                                  DropdownMenuItem(
                                    value: GoalConstraintRelation.equal,
                                    child: Text('='),
                                  ),
                                  DropdownMenuItem(
                                    value:
                                        GoalConstraintRelation.greaterOrEqual,
                                    child: Text('≥'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _hardRelations[row] = value);
                                  }
                                },
                              ),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        OrMatrixField(
                          controller: _hardRhs[row],
                          label: l10n.t('lpRhs'),
                          fieldKey: Key('or-goal-hard-rhs-$row'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.t('orGoals'), style: Theme.of(context).textTheme.titleMedium),
        SingleChildScrollView(
          key: const Key('or-goal-grid-scroll'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Column(
            children: [
              for (var row = 0; row < _goalCount; row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      SizedBox(width: 38, child: Text('G${row + 1}')),
                      for (var column = 0; column < _variables; column++) ...[
                        OrMatrixField(
                          controller: _goalCoefficients[row][column],
                          label: 'x${column + 1}',
                          fieldKey: Key('or-goal-coefficient-$row-$column'),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                      ],
                      SizedBox(
                        width: 142,
                        child: DropdownButtonFormField<GoalTargetRelation>(
                          key: Key('or-goal-relation-$row'),
                          initialValue: _goalRelations[row],
                          isExpanded: true,
                          items: [
                            for (final value in GoalTargetRelation.values)
                              DropdownMenuItem(
                                value: value,
                                child: Text(
                                  l10n.t(switch (value) {
                                    GoalTargetRelation.equal => 'orGoalEquals',
                                    GoalTargetRelation.atLeast =>
                                      'orGoalAtLeast',
                                    GoalTargetRelation.atMost => 'orGoalAtMost',
                                  }),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _goalRelations[row] = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      OrMatrixField(
                        controller: _goalTargets[row],
                        label: l10n.t('orTarget'),
                        fieldKey: Key('or-goal-target-$row'),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      OrMatrixField(
                        controller: _underWeights[row],
                        label: l10n.t('orUnderWeight'),
                        fieldKey: Key('or-goal-under-weight-$row'),
                        width: 150,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      OrMatrixField(
                        controller: _overWeights[row],
                        label: l10n.t('orOverWeight'),
                        fieldKey: Key('or-goal-over-weight-$row'),
                        width: 150,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('or-goal-solve'),
                onPressed: state.loading ? null : _solve,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.t('orSolve')),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton(
              onPressed: state.loading ? null : _clear,
              child: Text(l10n.t('orClear')),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.loading)
          const Center(child: CircularProgressIndicator())
        else if (state.result != null)
          OperationsResearchResultCard(result: state.result!),
      ],
    );
  }
}

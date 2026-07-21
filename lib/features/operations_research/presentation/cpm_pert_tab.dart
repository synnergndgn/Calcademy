import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart'
    show parseLpNumber;
import 'package:calcademy/features/operations_research/domain/operations_research_limits.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';
import 'package:calcademy/features/operations_research/domain/project_network_problem.dart';
import 'package:calcademy/features/operations_research/presentation/operations_research_controller.dart';
import 'package:calcademy/features/operations_research/presentation/operations_research_input_widgets.dart';
import 'package:calcademy/features/operations_research/presentation/operations_research_result_card.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CpmPertTab extends ConsumerStatefulWidget {
  const CpmPertTab({super.key});

  @override
  ConsumerState<CpmPertTab> createState() => _CpmPertTabState();
}

class _CpmPertTabState extends ConsumerState<CpmPertTab> {
  var _mode = ProjectScheduleMode.cpm;
  var _activityCount = 3;
  final _ids = <TextEditingController>[];
  final _durations = <TextEditingController>[];
  final _optimistic = <TextEditingController>[];
  final _mostLikely = <TextEditingController>[];
  final _pessimistic = <TextEditingController>[];
  final _predecessors = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    for (var index = 0; index < _activityCount; index++) {
      _addActivity(index);
    }
  }

  void _addActivity(int index) {
    _ids.add(TextEditingController(text: _defaultId(index)));
    _durations.add(TextEditingController(text: '${index + 1}'));
    _optimistic.add(TextEditingController(text: '${index + 1}'));
    _mostLikely.add(TextEditingController(text: '${index + 1}'));
    _pessimistic.add(TextEditingController(text: '${index + 1}'));
    _predecessors.add(
      TextEditingController(text: index == 0 ? '' : _defaultId(index - 1)),
    );
  }

  String _defaultId(int index) => index < 26
      ? String.fromCharCode('A'.codeUnitAt(0) + index)
      : 'A${index + 1}';

  void _resize(int value) {
    while (_ids.length < value) {
      _addActivity(_ids.length);
    }
    while (_ids.length > value) {
      _ids.removeLast().dispose();
      _durations.removeLast().dispose();
      _optimistic.removeLast().dispose();
      _mostLikely.removeLast().dispose();
      _pessimistic.removeLast().dispose();
      _predecessors.removeLast().dispose();
    }
    _activityCount = value;
  }

  List<String> _parsePredecessors(String source) => source
      .split(RegExp(r'[,;]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  Future<void> _solve() async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final problem = ProjectNetworkProblem(
        mode: _mode,
        activities: [
          for (var index = 0; index < _activityCount; index++)
            ProjectActivity(
              id: _ids[index].text.trim(),
              predecessors: _parsePredecessors(_predecessors[index].text),
              duration: _mode == ProjectScheduleMode.cpm
                  ? parseLpNumber(_durations[index].text)
                  : null,
              optimistic: _mode == ProjectScheduleMode.pert
                  ? parseLpNumber(_optimistic[index].text)
                  : null,
              mostLikely: _mode == ProjectScheduleMode.pert
                  ? parseLpNumber(_mostLikely[index].text)
                  : null,
              pessimistic: _mode == ProjectScheduleMode.pert
                  ? parseLpNumber(_pessimistic[index].text)
                  : null,
            ),
        ],
      );
      await ref
          .read(operationsResearchProvider.notifier)
          .solveProjectNetwork(problem);
    } on FormatException {
      ref
          .read(operationsResearchProvider.notifier)
          .reportIssue(OperationsResearchIssue.invalidNumber);
    }
  }

  void _clear() {
    for (final controller in [
      ..._ids,
      ..._durations,
      ..._optimistic,
      ..._mostLikely,
      ..._pessimistic,
      ..._predecessors,
    ]) {
      controller.dispose();
    }
    _ids.clear();
    _durations.clear();
    _optimistic.clear();
    _mostLikely.clear();
    _pessimistic.clear();
    _predecessors.clear();
    setState(() {
      _mode = ProjectScheduleMode.cpm;
      _activityCount = 3;
      for (var index = 0; index < _activityCount; index++) {
        _addActivity(index);
      }
    });
    ref.read(operationsResearchProvider.notifier).clear();
  }

  @override
  void dispose() {
    for (final controller in [
      ..._ids,
      ..._durations,
      ..._optimistic,
      ..._mostLikely,
      ..._pessimistic,
      ..._predecessors,
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
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OrCountSelector(
              label: l10n.t('orActivities'),
              value: _activityCount,
              minimum: OperationsResearchLimits.minActivities,
              maximum: OperationsResearchLimits.maxActivities,
              onChanged: (value) {
                setState(() => _resize(value));
                ref.read(operationsResearchProvider.notifier).clear();
              },
              increaseKey: const Key('or-network-add-activity'),
            ),
            SegmentedButton<ProjectScheduleMode>(
              key: const Key('or-network-mode-selector'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ProjectScheduleMode.cpm,
                  label: Text('CPM', key: Key('or-network-mode-cpm')),
                ),
                ButtonSegment(
                  value: ProjectScheduleMode.pert,
                  label: Text('PERT', key: Key('or-network-mode-pert')),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                setState(() => _mode = selection.first);
                ref.read(operationsResearchProvider.notifier).clear();
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.t('orActivityTable'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          key: const Key('or-network-grid-scroll'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Column(
            children: [
              for (var row = 0; row < _activityCount; row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 84,
                        child: TextField(
                          key: Key('or-network-id-$row'),
                          controller: _ids[row],
                          decoration: InputDecoration(
                            labelText: l10n.t('orActivityId'),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      if (_mode == ProjectScheduleMode.cpm)
                        OrMatrixField(
                          controller: _durations[row],
                          label: l10n.t('orDuration'),
                          fieldKey: Key('or-network-duration-$row'),
                          width: 92,
                        )
                      else ...[
                        OrMatrixField(
                          controller: _optimistic[row],
                          label: l10n.t('orOptimistic'),
                          fieldKey: Key('or-network-optimistic-$row'),
                          width: 120,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        OrMatrixField(
                          controller: _mostLikely[row],
                          label: l10n.t('orMostLikely'),
                          fieldKey: Key('or-network-most-likely-$row'),
                          width: 130,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        OrMatrixField(
                          controller: _pessimistic[row],
                          label: l10n.t('orPessimistic'),
                          fieldKey: Key('or-network-pessimistic-$row'),
                          width: 120,
                        ),
                      ],
                      const SizedBox(width: AppSpacing.xxs),
                      SizedBox(
                        width: 150,
                        child: TextField(
                          key: Key('or-network-predecessors-$row'),
                          controller: _predecessors[row],
                          decoration: InputDecoration(
                            labelText: l10n.t('orPredecessors'),
                            hintText: 'A,B',
                            isDense: true,
                          ),
                        ),
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
                key: const Key('or-network-solve'),
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

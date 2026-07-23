import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program.dart'
    show parseLpNumber;
import 'package:calcademy/features/operations_research/domain/operations_research_limits.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_problem.dart';
import 'package:calcademy/features/operations_research/domain/operations_research_result.dart';
import 'package:calcademy/features/operations_research/presentation/operations_research_controller.dart';
import 'package:calcademy/features/operations_research/presentation/operations_research_input_widgets.dart';
import 'package:calcademy/features/operations_research/presentation/operations_research_result_card.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransportationTab extends ConsumerStatefulWidget {
  const TransportationTab({super.key});

  @override
  ConsumerState<TransportationTab> createState() => _TransportationTabState();
}

class _TransportationTabState extends ConsumerState<TransportationTab> {
  static const _rowHeaderWidth = 64.0;

  var _sources = 2;
  var _destinations = 2;
  var _objective = OperationsResearchObjective.minimize;
  var _method = TransportationInitialMethod.leastCost;
  final _costs = <List<TextEditingController>>[];
  final _supply = <TextEditingController>[];
  final _demand = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    _resize(_sources, _destinations);
  }

  void _resize(int sources, int destinations) {
    while (_costs.length < sources) {
      _costs.add([
        for (var column = 0; column < destinations; column++)
          TextEditingController(text: '0'),
      ]);
      _supply.add(TextEditingController(text: '1'));
    }
    while (_costs.length > sources) {
      for (final controller in _costs.removeLast()) {
        controller.dispose();
      }
      _supply.removeLast().dispose();
    }
    for (final row in _costs) {
      while (row.length < destinations) {
        row.add(TextEditingController(text: '0'));
      }
      while (row.length > destinations) {
        row.removeLast().dispose();
      }
    }
    while (_demand.length < destinations) {
      _demand.add(TextEditingController(text: '1'));
    }
    while (_demand.length > destinations) {
      _demand.removeLast().dispose();
    }
    _sources = sources;
    _destinations = destinations;
  }

  @override
  void dispose() {
    for (final row in _costs) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    for (final controller in _supply) {
      controller.dispose();
    }
    for (final controller in _demand) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _solve() async {
    try {
      final problem = TransportationProblem(
        costs: [
          for (final row in _costs)
            [for (final controller in row) parseLpNumber(controller.text)],
        ],
        supply: [
          for (final controller in _supply) parseLpNumber(controller.text),
        ],
        demand: [
          for (final controller in _demand) parseLpNumber(controller.text),
        ],
        objective: _objective,
        initialMethod: _method,
      );
      await ref
          .read(operationsResearchProvider.notifier)
          .solveTransportation(problem);
    } on Object {
      ref
          .read(operationsResearchProvider.notifier)
          .reportIssue(OperationsResearchIssue.invalidNumber);
    }
  }

  void _clear() {
    for (final row in _costs) {
      for (final controller in row) {
        controller.text = '0';
      }
    }
    for (final controller in _supply) {
      controller.text = '1';
    }
    for (final controller in _demand) {
      controller.text = '1';
    }
    ref.read(operationsResearchProvider.notifier).clear();
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
              label: l10n.t('orSources'),
              value: _sources,
              minimum: OperationsResearchLimits.minTransportationSources,
              maximum: OperationsResearchLimits.maxTransportationSources,
              onChanged: (value) =>
                  setState(() => _resize(value, _destinations)),
              increaseKey: const Key('or-transport-add-source'),
            ),
            OrCountSelector(
              label: l10n.t('orDestinations'),
              value: _destinations,
              minimum: OperationsResearchLimits.minTransportationDestinations,
              maximum: OperationsResearchLimits.maxTransportationDestinations,
              onChanged: (value) => setState(() => _resize(_sources, value)),
              increaseKey: const Key('or-transport-add-destination'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        OrSelectorsLayout(
          children: [
            DropdownButtonFormField<OperationsResearchObjective>(
              key: const Key('or-transport-objective'),
              isExpanded: true,
              initialValue: _objective,
              decoration: InputDecoration(labelText: l10n.t('orObjective')),
              items: [
                for (final value in OperationsResearchObjective.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text(
                      l10n.t(
                        value == OperationsResearchObjective.minimize
                            ? 'orMinimizeCost'
                            : 'orMaximizeProfit',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _objective = value);
              },
            ),
            DropdownButtonFormField<TransportationInitialMethod>(
              key: const Key('or-transport-method'),
              isExpanded: true,
              initialValue: _method,
              decoration: InputDecoration(labelText: l10n.t('orInitialMethod')),
              items: [
                for (final value in TransportationInitialMethod.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text(
                      l10n.t(
                        value == TransportationInitialMethod.northWestCorner
                            ? 'orNorthWestCorner'
                            : 'orLeastCost',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _method = value);
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.t('orCostMatrix'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          key: const Key('or-transport-grid-scroll'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var row = 0; row < _sources; row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      SizedBox(
                        width: _rowHeaderWidth,
                        child: Text(
                          'S${row + 1}',
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                      for (
                        var column = 0;
                        column < _destinations;
                        column++
                      ) ...[
                        OrMatrixField(
                          fieldKey: Key('or-transport-cost-$row-$column'),
                          controller: _costs[row][column],
                          label: 'D${column + 1}',
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                      ],
                      OrMatrixField(
                        fieldKey: Key('or-transport-supply-$row'),
                        controller: _supply[row],
                        label: l10n.t('orSupply'),
                        width: 84,
                        labelKey: Key('or-transport-supply-label-$row'),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  SizedBox(
                    width: _rowHeaderWidth,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        l10n.t('orDemandShort'),
                        key: const Key('or-transport-demand-label'),
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                  for (var column = 0; column < _destinations; column++) ...[
                    OrMatrixField(
                      fieldKey: Key('or-transport-demand-$column'),
                      controller: _demand[column],
                      label: 'D${column + 1}',
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _TransportationActions(
          loading: state.loading,
          onSolve: _solve,
          onClear: _clear,
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

class _TransportationActions extends StatelessWidget {
  const _TransportationActions({
    required this.loading,
    required this.onSolve,
    required this.onClear,
  });

  final bool loading;
  final VoidCallback onSolve;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final stack =
        MediaQuery.textScalerOf(context).scale(1) >= 1.6 ||
        MediaQuery.sizeOf(context).width < 360;
    final solve = FilledButton.icon(
      key: const Key('or-transport-solve'),
      onPressed: loading ? null : onSolve,
      icon: const Icon(Icons.play_arrow_rounded),
      label: Text(context.l10n.t('orSolve')),
    );
    final clear = OutlinedButton(
      key: const Key('or-transport-clear'),
      onPressed: loading ? null : onClear,
      child: Text(context.l10n.t('orClear')),
    );
    if (stack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          solve,
          const SizedBox(height: AppSpacing.xs),
          clear,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: solve),
        const SizedBox(width: AppSpacing.sm),
        clear,
      ],
    );
  }
}

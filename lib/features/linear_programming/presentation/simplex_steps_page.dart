import 'package:calcademy/features/linear_programming/domain/linear_program_result.dart';
import 'package:calcademy/features/linear_programming/domain/simplex_tableau.dart';
import 'package:calcademy/features/linear_programming/presentation/tableau_view.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class SimplexStepsPage extends StatefulWidget {
  const SimplexStepsPage({super.key, required this.result});
  final LinearProgramResult result;

  @override
  State<SimplexStepsPage> createState() => _SimplexStepsPageState();
}

class _SimplexStepsPageState extends State<SimplexStepsPage> {
  var _index = 0;
  var _all = false;

  @override
  Widget build(BuildContext context) {
    final iterations = widget.result.iterations;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.t('lpSteps'))),
      body: iterations.isEmpty
          ? Center(child: Text(context.l10n.t('lpNoIterations')))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ExpansionTile(
                    title: Text(context.l10n.t('lpStandardization')),
                    children: [
                      for (final step in widget.result.standardizationSteps)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.transform_rounded),
                          title: Text(_localizedStep(context, step)),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 4,
                    alignment: WrapAlignment.center,
                    children: [
                      IconButton(
                        tooltip: context.l10n.t('lpFirst'),
                        onPressed: () => setState(() => _index = 0),
                        icon: const Icon(Icons.first_page),
                      ),
                      IconButton(
                        tooltip: context.l10n.t('lpPrevious'),
                        onPressed: _index == 0
                            ? null
                            : () => setState(() => _index--),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('${_index + 1} / ${iterations.length}'),
                      IconButton(
                        tooltip: context.l10n.t('lpNext'),
                        onPressed: _index == iterations.length - 1
                            ? null
                            : () => setState(() => _index++),
                        icon: const Icon(Icons.chevron_right),
                      ),
                      IconButton(
                        tooltip: context.l10n.t('lpLast'),
                        onPressed: () =>
                            setState(() => _index = iterations.length - 1),
                        icon: const Icon(Icons.last_page),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _all = !_all),
                        icon: const Icon(Icons.view_list),
                        label: Text(
                          context.l10n.t(_all ? 'lpOneByOne' : 'lpAllSteps'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _all
                      ? ListView.builder(
                          itemCount: iterations.length,
                          itemBuilder: (_, index) =>
                              _IterationCard(iteration: iterations[index]),
                        )
                      : ListView(
                          children: [
                            _IterationCard(iteration: iterations[_index]),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}

class _IterationCard extends StatelessWidget {
  const _IterationCard({required this.iteration});
  final SimplexIteration iteration;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.l10n.t('lpIteration')} ${iteration.number} · ${context.l10n.t('lp${iteration.phase.name}')} ',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(_localizedStep(context, iteration.explanation)),
          if (iteration.pivotValue != null)
            Text('${context.l10n.t('lpPivot')}: ${iteration.pivotValue}'),
          if (iteration.ratios.isNotEmpty)
            Text(
              '${context.l10n.t('lpRatios')}: ${iteration.ratios.map((v) => v?.toStringAsPrecision(4) ?? '—').join(', ')}',
            ),
          for (final operation in iteration.rowOperations)
            Text('• ${_localizedStep(context, operation)}'),
          const SizedBox(height: 8),
          TableauView(iteration: iteration),
        ],
      ),
    ),
  );
}

String _localizedStep(BuildContext context, String encoded) {
  final parts = encoded.split('|');
  var value = context.l10n.t(parts.first);
  for (var index = 1; index < parts.length; index++) {
    value = value.replaceFirst('{$index}', parts[index]);
  }
  return value;
}

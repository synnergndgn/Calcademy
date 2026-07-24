import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/matrix/domain/matrix_number_formatter.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/statistics_saved_adapter.dart';
import 'package:calcademy/features/statistics/domain/statistics_result.dart';
import 'package:calcademy/features/statistics/presentation/statistics_controller.dart';
import 'package:calcademy/features/statistics/presentation/statistics_result_card.dart';
import 'package:calcademy/features/statistics/presentation/statistics_widgets.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DistributionTab extends ConsumerStatefulWidget {
  const DistributionTab({super.key, this.restore});

  /// Inputs rebuilt from a saved record; seeds the fields (still editable)
  /// and recomputes automatically.
  final StatisticsRestore? restore;

  @override
  ConsumerState<DistributionTab> createState() => _DistributionTabState();
}

class _DistributionTabState extends ConsumerState<DistributionTab> {
  final _mean = TextEditingController(text: '0');
  final _standardDeviation = TextEditingController(text: '1');
  final _x = TextEditingController(text: '0');
  final _lower = TextEditingController(text: '-1');
  final _upper = TextEditingController(text: '1');
  final _n = TextEditingController(text: '10');
  final _p = TextEditingController(text: '0.5');
  final _k = TextEditingController(text: '5');
  final _lambda = TextEditingController(text: '3');
  var _kind = DistributionKind.normal;
  var _normalOperation = NormalOperation.lessOrEqual;
  var _discreteOperation = DiscreteOperation.equal;

  @override
  void initState() {
    super.initState();
    final restore = widget.restore;
    if (restore == null ||
        restore.mode != StatisticsRestoreMode.distribution ||
        restore.distributionKind == null) {
      return;
    }
    _kind = restore.distributionKind!;
    final fields = restore.fields;
    void seed(
      TextEditingController controller,
      String key, {
      bool asInt = false,
    }) {
      final value = fields[key];
      if (value == null) return;
      controller.text = asInt ? '${value.round()}' : formatMatrixNumber(value);
    }

    switch (_kind) {
      case DistributionKind.normal:
        _normalOperation =
            restore.normalOperation ?? NormalOperation.lessOrEqual;
        seed(_mean, 'mean');
        seed(_standardDeviation, 'sigma');
        seed(_x, 'x');
        seed(_lower, 'lower');
        seed(_upper, 'upper');
      case DistributionKind.binomial:
        _discreteOperation =
            restore.discreteOperation ?? DiscreteOperation.equal;
        seed(_n, 'n', asInt: true);
        seed(_p, 'p');
        seed(_k, 'k', asInt: true);
      case DistributionKind.poisson:
        _discreteOperation =
            restore.discreteOperation ?? DiscreteOperation.equal;
        seed(_lambda, 'lambda');
        seed(_k, 'k', asInt: true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _calculate();
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _mean,
      _standardDeviation,
      _x,
      _lower,
      _upper,
      _n,
      _p,
      _k,
      _lambda,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _calculate() {
    ref.read(statisticsWorkspaceProvider.notifier).calculate(() {
      final service = ref.read(probabilityDistributionServiceProvider);
      return switch (_kind) {
        DistributionKind.normal => service.normal(
          mean: _double(_mean.text),
          standardDeviation: _double(_standardDeviation.text),
          operation: _normalOperation,
          x: _normalOperation == NormalOperation.between
              ? null
              : _double(_x.text),
          lower: _normalOperation == NormalOperation.between
              ? _double(_lower.text)
              : null,
          upper: _normalOperation == NormalOperation.between
              ? _double(_upper.text)
              : null,
        ),
        DistributionKind.binomial => service.binomial(
          n: _integer(_n.text, StatisticsIssue.invalidN),
          probabilityOfSuccess: _double(_p.text),
          k: _integer(_k.text, StatisticsIssue.invalidK),
          operation: _discreteOperation,
        ),
        DistributionKind.poisson => service.poisson(
          lambda: _double(_lambda.text),
          k: _integer(_k.text, StatisticsIssue.invalidK),
          operation: _discreteOperation,
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = ref.watch(
      statisticsWorkspaceProvider.select((state) => state.result),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<DistributionKind>(
          key: const Key('stats-distribution-kind'),
          initialValue: _kind,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.t('statsDistribution')),
          items: [
            for (final kind in DistributionKind.values)
              DropdownMenuItem(
                value: kind,
                child: Text(l10n.t(_kindKey(kind))),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _kind = value);
            ref.read(statisticsWorkspaceProvider.notifier).clear();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<Object>(
          key: const Key('stats-distribution-operation'),
          initialValue: _kind == DistributionKind.normal
              ? _normalOperation
              : _discreteOperation,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.t('statsOperation')),
          items: _kind == DistributionKind.normal
              ? [
                  for (final operation in NormalOperation.values)
                    DropdownMenuItem<Object>(
                      value: operation,
                      child: Text(l10n.t(_normalOperationKey(operation))),
                    ),
                ]
              : [
                  for (final operation in DiscreteOperation.values)
                    DropdownMenuItem<Object>(
                      value: operation,
                      child: Text(l10n.t(_discreteOperationKey(operation))),
                    ),
                ],
          onChanged: (value) => setState(() {
            if (value is NormalOperation) _normalOperation = value;
            if (value is DiscreteOperation) _discreteOperation = value;
          }),
        ),
        const SizedBox(height: AppSpacing.sm),
        StatisticsFieldGrid(children: _fields(l10n)),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          key: const Key('stats-distribution-calculate'),
          onPressed: _calculate,
          icon: const Icon(Icons.calculate_rounded),
          label: Text(l10n.t('statsCalculate')),
        ),
        if (result != null) ...[
          const SizedBox(height: AppSpacing.md),
          StatisticsResultCard(result: result),
        ],
      ],
    );
  }

  List<Widget> _fields(AppLocalizations l10n) => switch (_kind) {
    DistributionKind.normal => [
      _field('stats-normal-mean', _mean, l10n.t('statsMeanMu')),
      _field(
        'stats-normal-std',
        _standardDeviation,
        l10n.t('statsStandardDeviationSigma'),
      ),
      if (_normalOperation != NormalOperation.between)
        _field('stats-normal-x', _x, l10n.t('statsXValue')),
      if (_normalOperation == NormalOperation.between) ...[
        _field('stats-normal-lower', _lower, l10n.t('statsLowerA')),
        _field('stats-normal-upper', _upper, l10n.t('statsUpperB')),
      ],
    ],
    DistributionKind.binomial => [
      _field('stats-binomial-n', _n, 'n', decimal: false),
      _field('stats-binomial-p', _p, 'p'),
      _field('stats-discrete-k', _k, 'k', decimal: false),
    ],
    DistributionKind.poisson => [
      _field('stats-poisson-lambda', _lambda, 'λ'),
      _field('stats-discrete-k', _k, 'k', decimal: false),
    ],
  };

  static TextField _field(
    String key,
    TextEditingController controller,
    String label, {
    bool decimal = true,
  }) => TextField(
    key: Key(key),
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(
      decimal: decimal,
      signed: true,
    ),
    decoration: InputDecoration(labelText: label),
  );

  static double _double(String text) {
    try {
      return parseStatisticsDouble(text);
    } on FormatException {
      throw const StatisticsValidationException(StatisticsIssue.invalidNumber);
    }
  }

  static int _integer(String text, StatisticsIssue issue) {
    try {
      return parseStatisticsInt(text);
    } on FormatException {
      throw StatisticsValidationException(issue);
    }
  }

  static String _kindKey(DistributionKind kind) => switch (kind) {
    DistributionKind.normal => 'statsNormalDistribution',
    DistributionKind.binomial => 'statsBinomialDistribution',
    DistributionKind.poisson => 'statsPoissonDistribution',
  };

  static String _normalOperationKey(NormalOperation operation) =>
      switch (operation) {
        NormalOperation.lessOrEqual => 'statsNormalLessOrEqual',
        NormalOperation.greaterOrEqual => 'statsNormalGreaterOrEqual',
        NormalOperation.between => 'statsNormalBetween',
      };

  static String _discreteOperationKey(DiscreteOperation operation) =>
      switch (operation) {
        DiscreteOperation.equal => 'statsDiscreteEqual',
        DiscreteOperation.lessOrEqual => 'statsDiscreteLessOrEqual',
        DiscreteOperation.greaterOrEqual => 'statsDiscreteGreaterOrEqual',
      };
}

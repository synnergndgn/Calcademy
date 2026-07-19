import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/statistics/domain/statistics_limits.dart';
import 'package:calcademy/features/statistics/domain/statistics_result.dart';
import 'package:calcademy/features/statistics/presentation/statistics_controller.dart';
import 'package:calcademy/features/statistics/presentation/statistics_result_card.dart';
import 'package:calcademy/features/statistics/presentation/statistics_widgets.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfidenceIntervalTab extends ConsumerStatefulWidget {
  const ConfidenceIntervalTab({super.key});

  @override
  ConsumerState<ConfidenceIntervalTab> createState() =>
      _ConfidenceIntervalTabState();
}

class _ConfidenceIntervalTabState extends ConsumerState<ConfidenceIntervalTab> {
  final _sampleMean = TextEditingController(text: '10');
  final _spread = TextEditingController(text: '2');
  final _sampleSize = TextEditingController(text: '25');
  final _successes = TextEditingController(text: '40');
  var _kind = ConfidenceIntervalKind.knownSigmaMean;
  var _confidenceLevel = 0.95;

  @override
  void dispose() {
    _sampleMean.dispose();
    _spread.dispose();
    _sampleSize.dispose();
    _successes.dispose();
    super.dispose();
  }

  void _calculate() {
    ref.read(statisticsWorkspaceProvider.notifier).calculate(() {
      final service = ref.read(confidenceIntervalServiceProvider);
      final n = _integer(_sampleSize.text, StatisticsIssue.invalidSampleSize);
      return switch (_kind) {
        ConfidenceIntervalKind.knownSigmaMean => service.knownSigmaMean(
          sampleMean: _double(_sampleMean.text),
          sigma: _double(_spread.text),
          sampleSize: n,
          confidenceLevel: _confidenceLevel,
        ),
        ConfidenceIntervalKind.unknownSigmaMean => service.unknownSigmaMean(
          sampleMean: _double(_sampleMean.text),
          sampleStandardDeviation: _double(_spread.text),
          sampleSize: n,
          confidenceLevel: _confidenceLevel,
        ),
        ConfidenceIntervalKind.proportion => service.proportion(
          successes: _integer(
            _successes.text,
            StatisticsIssue.invalidSuccesses,
          ),
          sampleSize: n,
          confidenceLevel: _confidenceLevel,
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
        DropdownButtonFormField<ConfidenceIntervalKind>(
          key: const Key('stats-confidence-kind'),
          initialValue: _kind,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.t('statsIntervalType')),
          items: [
            for (final kind in ConfidenceIntervalKind.values)
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
        DropdownButtonFormField<double>(
          key: const Key('stats-confidence-level'),
          initialValue: _confidenceLevel,
          decoration: InputDecoration(
            labelText: l10n.t('statsConfidenceLevel'),
          ),
          items: [
            for (final level in StatisticsLimits.supportedConfidenceLevels)
              DropdownMenuItem(
                value: level,
                child: Text('${(level * 100).round()}%'),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _confidenceLevel = value);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        StatisticsFieldGrid(children: _fields(l10n)),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          key: const Key('stats-confidence-calculate'),
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

  List<Widget> _fields(AppLocalizations l10n) {
    if (_kind == ConfidenceIntervalKind.proportion) {
      return [
        _field(
          'stats-successes',
          _successes,
          l10n.t('statsSuccesses'),
          decimal: false,
        ),
        _field(
          'stats-ci-n',
          _sampleSize,
          l10n.t('statsSampleSize'),
          decimal: false,
        ),
      ];
    }
    return [
      _field('stats-sample-mean', _sampleMean, l10n.t('statsSampleMean')),
      _field(
        'stats-ci-spread',
        _spread,
        _kind == ConfidenceIntervalKind.knownSigmaMean
            ? l10n.t('statsKnownSigma')
            : l10n.t('statsSampleStandardDeviation'),
      ),
      _field(
        'stats-ci-n',
        _sampleSize,
        l10n.t('statsSampleSize'),
        decimal: false,
      ),
    ];
  }

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

  static String _kindKey(ConfidenceIntervalKind kind) => switch (kind) {
    ConfidenceIntervalKind.knownSigmaMean => 'statsKnownSigmaMean',
    ConfidenceIntervalKind.unknownSigmaMean => 'statsUnknownSigmaMean',
    ConfidenceIntervalKind.proportion => 'statsProportionInterval',
  };
}

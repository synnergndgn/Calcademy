import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/statistics/presentation/statistics_controller.dart';
import 'package:calcademy/features/statistics/presentation/statistics_result_card.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DescriptiveStatisticsTab extends ConsumerStatefulWidget {
  const DescriptiveStatisticsTab({super.key});

  @override
  ConsumerState<DescriptiveStatisticsTab> createState() =>
      _DescriptiveStatisticsTabState();
}

class _DescriptiveStatisticsTabState
    extends ConsumerState<DescriptiveStatisticsTab> {
  final _data = TextEditingController();

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  void _calculate() {
    ref
        .read(statisticsWorkspaceProvider.notifier)
        .calculate(
          () => ref
              .read(descriptiveStatisticsServiceProvider)
              .calculate(_data.text),
        );
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
        TextField(
          key: const Key('stats-data-input'),
          controller: _data,
          minLines: 3,
          maxLines: 7,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: InputDecoration(
            labelText: l10n.t('statsDataset'),
            hintText: '1, 2, 3, 4, 5',
            helperText: l10n.t('statsDatasetHelp'),
            helperMaxLines: 3,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          key: const Key('stats-descriptive-calculate'),
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
}

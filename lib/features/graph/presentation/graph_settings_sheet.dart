import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/graph/domain/graph_expression.dart';
import 'package:calcademy/features/graph/domain/graph_range.dart';
import 'package:calcademy/features/graph/presentation/graph_controller.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GraphSettingsPanel extends ConsumerStatefulWidget {
  const GraphSettingsPanel({super.key});

  @override
  ConsumerState<GraphSettingsPanel> createState() => _GraphSettingsPanelState();
}

class _GraphSettingsPanelState extends ConsumerState<GraphSettingsPanel> {
  final _xMin = TextEditingController();
  final _xMax = TextEditingController();
  final _yMin = TextEditingController();
  final _yMax = TextEditingController();
  GraphRange? _lastRange;
  double? _lastYMin;
  double? _lastYMax;
  int? _lastViewResetRevision;

  @override
  void dispose() {
    _xMin.dispose();
    _xMax.dispose();
    _yMin.dispose();
    _yMax.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(
      graphProvider.select(
        (state) => (
          range: state.range,
          autoY: state.autoY,
          manualYMin: state.manualYMin,
          manualYMax: state.manualYMax,
          angleMode: state.angleMode,
          rangeError: state.rangeError,
          viewResetRevision: state.viewResetRevision,
        ),
      ),
    );
    _syncControllers(
      settings.range,
      settings.manualYMin,
      settings.manualYMax,
      settings.viewResetRevision,
    );
    final controller = ref.read(graphProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.t('graphViewSettings'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.t('graphAngleMode'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<GraphAngleMode>(
              segments: const [
                ButtonSegment(
                  value: GraphAngleMode.radians,
                  label: Text('RAD'),
                ),
                ButtonSegment(
                  value: GraphAngleMode.degrees,
                  label: Text('DEG'),
                ),
              ],
              selected: {settings.angleMode},
              onSelectionChanged: (value) =>
                  controller.setAngleMode(value.first),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('graphXMin'),
                    controller: _xMin,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(context.l10n.t('graphXMin')),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    key: const Key('graphXMax'),
                    controller: _xMax,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(context.l10n.t('graphXMax')),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.t('graphXRangeHint'),
              key: const Key('graph-x-range-hint'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.t('graphYScale'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(context.l10n.t('graphAutoScale')),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(context.l10n.t('graphManualScale')),
                ),
              ],
              selected: {settings.autoY},
              onSelectionChanged: (value) => controller.setAutoY(value.first),
            ),
            if (!settings.autoY) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _yMin,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: InputDecoration(
                        labelText: context.l10n.t('graphYMin'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _yMax,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: InputDecoration(
                        labelText: context.l10n.t('graphYMax'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (settings.rangeError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.t(settings.rangeError!),
                key: const Key('graph-range-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                TextButton.icon(
                  key: const Key('graph-reset-range'),
                  onPressed: controller.resetView,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(context.l10n.t('graphReset')),
                ),
                FilledButton.icon(
                  key: const Key('applyGraphRange'),
                  onPressed: () => controller.applyRange(
                    xMin: _xMin.text,
                    xMax: _xMax.text,
                    yMin: _yMin.text,
                    yMax: _yMax.text,
                  ),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(context.l10n.t('apply')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _syncControllers(
    GraphRange range,
    double yMin,
    double yMax,
    int viewResetRevision,
  ) {
    if (!identical(_lastRange, range) ||
        _lastViewResetRevision != viewResetRevision) {
      _lastRange = range;
      _lastViewResetRevision = viewResetRevision;
      _setText(_xMin, _format(range.min));
      _setText(_xMax, _format(range.max));
    }
    if (_lastYMin != yMin) {
      _lastYMin = yMin;
      _setText(_yMin, _format(yMin));
    }
    if (_lastYMax != yMax) {
      _lastYMax = yMax;
      _setText(_yMax, _format(yMax));
    }
  }

  void _setText(TextEditingController controller, String text) {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  String _format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

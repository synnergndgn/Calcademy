import 'package:calcademy/app/ads/consent_providers.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/calcademy_design.dart';
import 'package:calcademy/core/widgets/page_body.dart';
import 'package:calcademy/features/history/presentation/history_controller.dart';
import 'package:calcademy/features/saved/presentation/saved_controller.dart';
import 'package:calcademy/features/settings/domain/app_settings.dart';
import 'package:calcademy/features/settings/presentation/settings_controller.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    return CalcademyScaffold(
      title: Text(context.l10n.t('settings')),
      body: PageBody(
        child: ListView(
          padding: PageBody.scrollPadding(context, top: AppSpacing.sm),
          children: [
            StudyHeader(
              compact: true,
              eyebrow: context.l10n.t('systemPreferences'),
              title: context.l10n.t('settingsWorkspaceTitle'),
              subtitle: context.l10n.t('settingsWorkspaceBody'),
              formula: 'display / behavior / data',
            ),
            const SizedBox(height: AppSpacing.xl),
            GroupedSettingsSection(
              title: context.l10n.t('appearance'),
              icon: Icons.palette_outlined,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _ThemePreviewGrid(
                    currentMode: settings.themeMode,
                    onChanged: controller.setThemeMode,
                  ),
                ),
              ],
            ),
            GroupedSettingsSection(
              title: context.l10n.t('language'),
              icon: Icons.translate_rounded,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      ChoiceChip(
                        label: Text(context.l10n.t('turkish')),
                        selected: settings.languageCode == 'tr',
                        onSelected: (_) => controller.setLanguage('tr'),
                      ),
                      ChoiceChip(
                        label: Text(context.l10n.t('english')),
                        selected: settings.languageCode == 'en',
                        onSelected: (_) => controller.setLanguage('en'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            GroupedSettingsSection(
              title: context.l10n.t('calculatorBehavior'),
              icon: Icons.tune_rounded,
              children: [
                ListTile(
                  leading: const Icon(Icons.straighten_rounded),
                  title: Text(context.l10n.t('defaultAngle')),
                  subtitle: Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      ChoiceChip(
                        label: Text(context.l10n.t('degrees')),
                        selected: settings.angleMode == AngleMode.degrees,
                        onSelected: (_) =>
                            controller.setAngleMode(AngleMode.degrees),
                      ),
                      ChoiceChip(
                        label: Text(context.l10n.t('radians')),
                        selected: settings.angleMode == AngleMode.radians,
                        onSelected: (_) =>
                            controller.setAngleMode(AngleMode.radians),
                      ),
                    ],
                  ),
                ),
                SwitchListTile(
                  title: Text(context.l10n.t('haptics')),
                  secondary: const Icon(Icons.vibration_rounded),
                  value: settings.hapticsEnabled,
                  onChanged: controller.setHaptics,
                ),
                SwitchListTile(
                  title: Text(context.l10n.t('keySound')),
                  secondary: const Icon(Icons.volume_up_outlined),
                  value: settings.keySoundEnabled,
                  onChanged: controller.setKeySound,
                ),
                SwitchListTile(
                  title: Text(context.l10n.t('scientificNotation')),
                  secondary: const Icon(Icons.science_outlined),
                  value: settings.scientificNotation,
                  onChanged: controller.setScientificNotation,
                ),
                ListTile(
                  leading: const Icon(Icons.pin_outlined),
                  title: Text(context.l10n.t('precision')),
                  subtitle: Slider(
                    value: settings.decimalPrecision.toDouble(),
                    min: 4,
                    max: 15,
                    divisions: 11,
                    label: '${settings.decimalPrecision}',
                    onChanged: (value) =>
                        controller.setPrecision(value.round()),
                  ),
                  trailing: Text('${settings.decimalPrecision}'),
                ),
              ],
            ),
            if (ref.watch(adConsentStateProvider).privacyOptionsRequired)
              GroupedSettingsSection(
                title: context.l10n.t('data'),
                icon: Icons.storage_outlined,
                children: [
                  if (ref.watch(adConsentStateProvider).privacyOptionsRequired)
                    ListTile(
                      key: const Key('settings-privacy-options-tile'),
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: Text(context.l10n.t('adPrivacyOptions')),
                      subtitle: Text(
                        context.l10n.t('adPrivacyOptionsSubtitle'),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => ref
                          .read(adConsentStateProvider.notifier)
                          .showPrivacyOptions(),
                    ),
                ],
              ),
            GroupedSettingsSection(
              title: context.l10n.t('dataManagement'),
              icon: Icons.delete_outline_rounded,
              destructive: true,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.delete_sweep_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(context.l10n.t('clearHistory')),
                  onTap: () => _confirm(
                    context,
                    context.l10n.t('clearHistoryQuestion'),
                    () => ref.read(historyProvider.notifier).clear(),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.bookmark_remove_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(context.l10n.t('clearSaved')),
                  onTap: () => _confirm(
                    context,
                    context.l10n.t('clearSavedQuestion'),
                    () => ref.read(savedProvider.notifier).clear(),
                  ),
                ),
              ],
            ),
            GroupedSettingsSection(
              title: context.l10n.t('aboutLegal'),
              icon: Icons.info_outline_rounded,
              children: [
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: Text(context.l10n.t('about')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/about'),
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(context.l10n.t('privacy')),
                  subtitle: Text(context.l10n.t('privacyBody')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/about'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    String message,
    Future<void> Function() action,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.t('clear')),
          ),
        ],
      ),
    );
    if (result == true) await action();
  }
}

class _ThemePreviewGrid extends StatelessWidget {
  const _ThemePreviewGrid({required this.currentMode, required this.onChanged});

  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final columns = constraints.maxWidth >= 420 && textScale <= 1.3 ? 3 : 1;
      final width =
          (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
      final previews = [
        (
          label: context.l10n.t('system'),
          icon: Icons.brightness_auto_rounded,
          mode: ThemeMode.system,
        ),
        (
          label: context.l10n.t('light'),
          icon: Icons.light_mode_rounded,
          mode: ThemeMode.light,
        ),
        (
          label: context.l10n.t('dark'),
          icon: Icons.dark_mode_rounded,
          mode: ThemeMode.dark,
        ),
      ];
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final preview in previews)
            SizedBox(
              width: width,
              child: _ThemePreviewTile(
                label: preview.label,
                icon: preview.icon,
                mode: preview.mode,
                selected: currentMode == preview.mode,
                onTap: onChanged,
              ),
            ),
        ],
      );
    },
  );
}

class _ThemePreviewTile extends StatelessWidget {
  const _ThemePreviewTile({
    required this.label,
    required this.icon,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final ThemeMode mode;
  final bool selected;
  final ValueChanged<ThemeMode> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onTap(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected
                ? colors.primaryContainer
                : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: mode == ThemeMode.dark
                      ? const Color(0xFF17201C)
                      : const Color(0xFFFBFAF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Icon(icon, color: colors.primary)),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

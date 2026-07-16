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
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _Heading(context.l10n.t('theme')),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(context.l10n.t('system')),
                icon: const Icon(Icons.brightness_auto_rounded),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(context.l10n.t('light')),
                icon: const Icon(Icons.light_mode_rounded),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(context.l10n.t('dark')),
                icon: const Icon(Icons.dark_mode_rounded),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (value) => controller.setThemeMode(value.first),
          ),
          _Heading(context.l10n.t('language')),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'tr',
                label: Text(context.l10n.t('turkish')),
              ),
              ButtonSegment(
                value: 'en',
                label: Text(context.l10n.t('english')),
              ),
            ],
            selected: {settings.languageCode},
            onSelectionChanged: (value) => controller.setLanguage(value.first),
          ),
          _Heading(context.l10n.t('defaultAngle')),
          SegmentedButton<AngleMode>(
            segments: [
              ButtonSegment(
                value: AngleMode.degrees,
                label: Text(context.l10n.t('degrees')),
              ),
              ButtonSegment(
                value: AngleMode.radians,
                label: Text(context.l10n.t('radians')),
              ),
            ],
            selected: {settings.angleMode},
            onSelectionChanged: (value) => controller.setAngleMode(value.first),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
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
          ),
          _Heading(context.l10n.t('data')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: Text(context.l10n.t('clearHistory')),
                  onTap: () => _confirm(
                    context,
                    context.l10n.t('clearHistoryQuestion'),
                    () => ref.read(historyProvider.notifier).clear(),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.bookmark_remove_outlined),
                  title: Text(context.l10n.t('clearSaved')),
                  onTap: () => _confirm(
                    context,
                    context.l10n.t('clearSavedQuestion'),
                    () => ref.read(savedProvider.notifier).clear(),
                  ),
                ),
              ],
            ),
          ),
          _Heading(context.l10n.t('about')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(context.l10n.t('about')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/about'),
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(context.l10n.t('privacy')),
                  subtitle: Text(context.l10n.t('privacyBody')),
                ),
              ],
            ),
          ),
        ],
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

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    ),
  );
}

import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/ai_assistant/application/ai_assistant_controller.dart';
import 'package:calcademy/features/settings/presentation/settings_controller.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opt-in for sending assistant questions off the device.
///
/// Renders only for an account that could actually use the remote assistant
/// and has not consented yet, so a free or signed-out user is never asked to
/// approve something that would not happen anyway.
class AiRemoteConsentCard extends ConsumerWidget {
  const AiRemoteConsentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligible = ref.watch(remoteAssistantEligibleProvider);
    final consented = ref.watch(settingsProvider).remoteAssistantEnabled;
    if (!eligible || consented) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Card(
      key: const Key('ai-remote-consent'),
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_outlined),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.l10n.t('aiAssistantRemoteConsentTitle'),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.t('aiAssistantRemoteConsentBody'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  key: const Key('ai-remote-consent-decline'),
                  onPressed: () => ref
                      .read(settingsProvider.notifier)
                      .setRemoteAssistantEnabled(false),
                  child: Text(
                    context.l10n.t('aiAssistantRemoteConsentDecline'),
                  ),
                ),
                FilledButton(
                  key: const Key('ai-remote-consent-accept'),
                  onPressed: () => ref
                      .read(settingsProvider.notifier)
                      .setRemoteAssistantEnabled(true),
                  child: Text(context.l10n.t('aiAssistantRemoteConsentAccept')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

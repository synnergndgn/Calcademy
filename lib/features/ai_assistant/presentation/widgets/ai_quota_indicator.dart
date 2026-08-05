import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/ai_assistant/application/ai_assistant_controller.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows the remaining remote allowance so the limit is visible before the
/// user hits it rather than only when a request is refused.
///
/// Display only — the backend reserves the allowance, so nothing here can
/// grant an extra request. It renders only in remote mode, since a purely
/// local assistant has no limit to report.
class AiQuotaIndicator extends ConsumerWidget {
  const AiQuotaIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(canUseRemoteAssistantProvider)) {
      return const SizedBox.shrink();
    }
    final quota =
        ref.watch(aiAssistantControllerProvider).quota ??
        ref.watch(initialRemoteAssistantQuotaProvider).value;
    if (quota == null) return const SizedBox.shrink();

    final remaining = quota.remainingToday;
    if (remaining == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final exhausted = remaining == 0;
    final color = exhausted
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return Padding(
      key: const Key('ai-quota-indicator'),
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            exhausted ? Icons.hourglass_disabled : Icons.speed_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              context.l10n
                  .t('usageRemaining')
                  .replaceFirst('{count}', '$remaining'),
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

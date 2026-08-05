import 'package:calcademy/features/ai_assistant/application/ai_assistant_controller.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiScopeNoticeCard extends ConsumerWidget {
  const AiScopeNoticeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRemote = ref.watch(canUseRemoteAssistantProvider);
    return Card(
      key: const Key('ai-scope-notice'),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: ListTile(
        leading: Icon(
          isRemote ? Icons.cloud_outlined : Icons.privacy_tip_outlined,
        ),
        title: Text(context.l10n.t('aiAssistantScopeNotice')),
        subtitle: Text(
          context.l10n.t(
            isRemote
                ? 'aiAssistantRemoteModeNotice'
                : 'aiAssistantLocalModeNotice',
          ),
        ),
      ),
    );
  }
}

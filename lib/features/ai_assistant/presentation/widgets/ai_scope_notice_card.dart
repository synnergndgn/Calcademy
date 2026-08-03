import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AiScopeNoticeCard extends StatelessWidget {
  const AiScopeNoticeCard({super.key});

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('ai-scope-notice'),
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: ListTile(
      leading: const Icon(Icons.privacy_tip_outlined),
      title: Text(context.l10n.t('aiAssistantScopeNotice')),
      subtitle: Text(context.l10n.t('aiAssistantLocalModeNotice')),
    ),
  );
}

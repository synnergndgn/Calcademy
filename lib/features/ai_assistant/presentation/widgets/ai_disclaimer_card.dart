import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AiDisclaimerCard extends StatelessWidget {
  const AiDisclaimerCard({super.key, this.text});

  final String? text;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('ai-financial-disclaimer'),
    color: Theme.of(context).colorScheme.errorContainer,
    child: ListTile(
      leading: const Icon(Icons.info_outline_rounded),
      title: Text(text ?? context.l10n.t('aiAssistantFinancialDisclaimer')),
    ),
  );
}

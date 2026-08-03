import 'package:calcademy/app/tools/calcademy_tool.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AiToolSuggestionCard extends StatelessWidget {
  const AiToolSuggestionCard({
    super.key,
    required this.tool,
    required this.reason,
    required this.onOpen,
  });

  final CalcademyTool tool;
  final String reason;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return Card(
      key: Key('ai-tool-card-${tool.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.t('aiAssistantSuggestedTool'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tool.title(languageCode),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(reason),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: Key('ai-open-tool-${tool.id}'),
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(context.l10n.t('aiAssistantOpenTool')),
            ),
          ],
        ),
      ),
    );
  }
}

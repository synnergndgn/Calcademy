import 'package:calcademy/features/formula_library/domain/formula_entry.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AiFormulaSuggestionCard extends StatelessWidget {
  const AiFormulaSuggestionCard({
    super.key,
    required this.formula,
    required this.onOpen,
  });

  final FormulaEntry formula;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return Card(
      key: Key('ai-formula-card-${formula.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.t('aiAssistantSuggestedFormula'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formula.title(languageCode),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(formula.description(languageCode)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: Key('ai-open-formula-${formula.id}'),
              onPressed: onOpen,
              icon: const Icon(Icons.menu_book_rounded),
              label: Text(context.l10n.t('aiAssistantOpenFormula')),
            ),
          ],
        ),
      ),
    );
  }
}

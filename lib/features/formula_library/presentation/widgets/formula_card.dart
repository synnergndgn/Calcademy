import 'package:calcademy/app/tools/calcademy_tool_registry.dart';
import 'package:calcademy/features/formula_library/domain/formula_entry.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class FormulaCard extends StatelessWidget {
  const FormulaCard({
    super.key,
    required this.formula,
    required this.favorite,
    required this.onTap,
    required this.onFavorite,
  });

  final FormulaEntry formula;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final tool = formula.relatedTools.isEmpty
        ? null
        : CalcademyToolRegistry.byId(formula.relatedTools.first.toolId);
    return Card(
      key: Key('formula-card-${formula.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      formula.title(language),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    key: Key('formula-favorite-${formula.id}'),
                    tooltip: context.l10n.t(
                      favorite ? 'removeFavorite' : 'favoriteFormula',
                    ),
                    onPressed: onFavorite,
                    icon: Icon(
                      favorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                    ),
                  ),
                ],
              ),
              Text(
                formula.category.localized(language),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formula.description(language),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              SelectableText(
                formula.formulaText,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontFamily: 'monospace'),
              ),
              if (tool != null) ...[
                const SizedBox(height: 12),
                Chip(
                  avatar: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(tool.title(language)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:calcademy/features/formula_library/domain/formula_category.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class FormulaCategoryFilter extends StatelessWidget {
  const FormulaCategoryFilter({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final FormulaCategory? selected;
  final ValueChanged<FormulaCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            key: const Key('formula-category-all'),
            label: Text(context.l10n.t('allCategories')),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          for (final category in FormulaCategory.values) ...[
            ChoiceChip(
              key: Key('formula-category-${category.name}'),
              label: Text(category.localized(language)),
              selected: selected == category,
              onSelected: (_) => onSelected(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

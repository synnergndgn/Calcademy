import 'package:calcademy/features/formula_library/domain/formula_variable.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class FormulaVariableTable extends StatelessWidget {
  const FormulaVariableTable({super.key, required this.variables});

  final List<FormulaVariable> variables;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(context.l10n.t('symbol'))),
          DataColumn(label: Text(context.l10n.t('meaning'))),
          DataColumn(label: Text(context.l10n.t('description'))),
        ],
        rows: [
          for (final variable in variables)
            DataRow(
              cells: [
                DataCell(SelectableText(variable.symbol)),
                DataCell(
                  Text(language == 'tr' ? variable.nameTr : variable.nameEn),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Text(
                      language == 'tr'
                          ? variable.descriptionTr
                          : variable.descriptionEn,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

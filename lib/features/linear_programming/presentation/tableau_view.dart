import 'package:calcademy/features/linear_programming/domain/linear_program.dart';
import 'package:calcademy/features/linear_programming/domain/simplex_tableau.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class TableauView extends StatelessWidget {
  const TableauView({super.key, required this.iteration});
  final SimplexIteration iteration;

  @override
  Widget build(BuildContext context) {
    final tableau = iteration.tableau;
    return Semantics(
      label: context.l10n.t('lpTableau'),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text(context.l10n.t('lpBasic'))),
              for (final name in tableau.columnNames)
                DataColumn(label: Text(name)),
              const DataColumn(label: Text('RHS')),
            ],
            rows: [
              for (var row = 0; row < tableau.rows.length; row++)
                DataRow(
                  cells: [
                    DataCell(
                      Text(
                        row == tableau.rows.length - 1
                            ? 'z'
                            : tableau.columnNames[tableau.basis[row]],
                      ),
                    ),
                    for (
                      var column = 0;
                      column < tableau.columnNames.length;
                      column++
                    )
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border:
                                iteration.enteringColumn == column ||
                                    iteration.leavingRow == row
                                ? Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            formatLpNumber(tableau.rows[row][column]),
                          ),
                        ),
                      ),
                    DataCell(Text(formatLpNumber(tableau.rows[row].last))),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

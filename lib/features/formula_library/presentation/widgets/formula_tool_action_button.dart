import 'package:calcademy/features/formula_library/domain/formula_tool_link.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FormulaToolActionButton extends StatelessWidget {
  const FormulaToolActionButton({super.key, required this.link});

  final FormulaToolLink link;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    return FilledButton.icon(
      key: Key('formula-tool-${link.toolId}'),
      onPressed: () => context.push(link.route),
      icon: const Icon(Icons.open_in_new_rounded),
      label: Text(language == 'tr' ? link.labelTr : link.labelEn),
    );
  }
}

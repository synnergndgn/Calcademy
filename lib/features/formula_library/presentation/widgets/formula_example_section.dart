import 'package:calcademy/features/formula_library/domain/formula_example.dart';
import 'package:flutter/material.dart';

class FormulaExampleSection extends StatelessWidget {
  const FormulaExampleSection({super.key, required this.examples});

  final List<FormulaExample> examples;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    return Column(
      key: const Key('formula-examples'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final example in examples)
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language == 'tr' ? example.titleTr : example.titleEn,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final value in example.givenValues.entries)
                    SelectableText('${value.key}: ${value.value}'),
                  const SizedBox(height: 8),
                  for (final (index, step)
                      in (language == 'tr' ? example.stepsTr : example.stepsEn)
                          .indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${index + 1}. $step'),
                    ),
                  const Divider(),
                  SelectableText(
                    example.result,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

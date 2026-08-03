import 'package:calcademy/features/formula_library/domain/formula_category.dart';
import 'package:calcademy/features/formula_library/domain/formula_example.dart';
import 'package:calcademy/features/formula_library/domain/formula_tool_link.dart';
import 'package:calcademy/features/formula_library/domain/formula_variable.dart';

enum FormulaDifficulty { basic, intermediate, advanced }

class FormulaEntry {
  const FormulaEntry({
    required this.id,
    required this.titleEn,
    required this.titleTr,
    required this.category,
    required this.formulaText,
    required this.plainTextFormula,
    required this.descriptionEn,
    required this.descriptionTr,
    required this.variables,
    required this.examples,
    required this.tags,
    required this.relatedTools,
    required this.difficulty,
    this.subcategory,
    this.supportedLocales = const {'en', 'tr'},
    this.notes,
    this.warning,
  });

  final String id;
  final String titleEn;
  final String titleTr;
  final FormulaCategory category;
  final String? subcategory;
  final String formulaText;
  final String plainTextFormula;
  final String descriptionEn;
  final String descriptionTr;
  final List<FormulaVariable> variables;
  final List<FormulaExample> examples;
  final List<String> tags;
  final List<FormulaToolLink> relatedTools;
  final FormulaDifficulty difficulty;
  final Set<String> supportedLocales;
  final String? notes;
  final String? warning;

  String title(String languageCode) => languageCode == 'tr' ? titleTr : titleEn;
  String description(String languageCode) =>
      languageCode == 'tr' ? descriptionTr : descriptionEn;
}

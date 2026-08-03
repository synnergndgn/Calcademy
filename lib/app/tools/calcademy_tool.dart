import 'package:calcademy/features/formula_library/domain/formula_category.dart';

class CalcademyTool {
  const CalcademyTool({
    required this.id,
    required this.titleEn,
    required this.titleTr,
    required this.route,
    required this.descriptionEn,
    required this.descriptionTr,
    required this.supportedFormulaCategories,
    this.supportsPrefill = false,
    this.inputSchema,
  });

  final String id;
  final String titleEn;
  final String titleTr;
  final String route;
  final String descriptionEn;
  final String descriptionTr;
  final Set<FormulaCategory> supportedFormulaCategories;
  final bool supportsPrefill;
  final Map<String, String>? inputSchema;

  String title(String languageCode) => languageCode == 'tr' ? titleTr : titleEn;
}

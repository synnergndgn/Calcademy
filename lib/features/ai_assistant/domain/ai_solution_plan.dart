import 'package:calcademy/features/ai_assistant/domain/ai_problem_intent.dart';

class AiSolutionPlan {
  const AiSolutionPlan({
    required this.intent,
    required this.confidence,
    required this.summaryEn,
    required this.summaryTr,
    required this.stepsEn,
    required this.stepsTr,
    required this.relatedToolIds,
    required this.relatedFormulaIds,
    required this.canOpenTool,
    required this.canOpenFormula,
    this.extractedInputs,
    this.warning,
  });

  final AiProblemIntent intent;
  final double confidence;
  final String summaryEn;
  final String summaryTr;
  final List<String> stepsEn;
  final List<String> stepsTr;
  final List<String> relatedToolIds;
  final List<String> relatedFormulaIds;
  final Map<String, Object?>? extractedInputs;
  final bool canOpenTool;
  final bool canOpenFormula;
  final String? warning;

  String summary(String languageCode) =>
      languageCode == 'tr' ? summaryTr : summaryEn;

  List<String> steps(String languageCode) =>
      languageCode == 'tr' ? stepsTr : stepsEn;
}

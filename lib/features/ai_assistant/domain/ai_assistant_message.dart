import 'package:calcademy/features/ai_assistant/domain/ai_assistant_role.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_solution_plan.dart';

class AiAssistantMessage {
  const AiAssistantMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.relatedToolIds = const [],
    this.relatedFormulaIds = const [],
    this.solutionPlan,
    this.safetyNotice,
  });

  final String id;
  final AiAssistantRole role;
  final String text;
  final DateTime createdAt;
  final List<String> relatedToolIds;
  final List<String> relatedFormulaIds;
  final AiSolutionPlan? solutionPlan;
  final String? safetyNotice;
}

import 'package:calcademy/features/ai_assistant/domain/ai_assistant_message.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_solution_plan.dart';

class AiAssistantResult {
  const AiAssistantResult({
    required this.success,
    this.messages = const [],
    this.plan,
    this.error,
  });

  final bool success;
  final List<AiAssistantMessage> messages;
  final AiSolutionPlan? plan;
  final String? error;
}

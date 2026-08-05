import 'package:calcademy/app/premium/usage_quota.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_assistant_message.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_solution_plan.dart';

class AiAssistantResult {
  const AiAssistantResult({
    required this.success,
    this.messages = const [],
    this.plan,
    this.error,
    this.quota,
  });

  final bool success;
  final List<AiAssistantMessage> messages;
  final AiSolutionPlan? plan;
  final String? error;

  /// The caller's remaining remote allowance as the backend reported it, or
  /// `null` when the request never reached the backend. The local pipeline
  /// never sets this.
  final UsageQuota? quota;
}

import 'package:calcademy/features/ai_assistant/application/ai_problem_classifier.dart';
import 'package:calcademy/features/ai_assistant/application/ai_response_composer.dart';
import 'package:calcademy/features/ai_assistant/application/ai_tool_planner.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_assistant_result.dart';
import 'package:calcademy/features/ai_assistant/infrastructure/ai_assistant_service.dart';

class MockAiAssistantService implements AiAssistantService {
  const MockAiAssistantService({
    this.classifier = const AiProblemClassifier(),
    this.planner = const AiToolPlanner(),
    this.composer = const AiResponseComposer(),
  });

  final AiProblemClassifier classifier;
  final AiToolPlanner planner;
  final AiResponseComposer composer;

  @override
  Future<AiAssistantResult> analyze(
    String input, {
    required String languageCode,
  }) async {
    final intent = classifier.classify(input);
    final planning = planner.createPlan(intent, input);
    final message = composer.compose(planning.plan, languageCode);
    return AiAssistantResult(
      success: true,
      messages: [message],
      plan: planning.plan,
    );
  }
}

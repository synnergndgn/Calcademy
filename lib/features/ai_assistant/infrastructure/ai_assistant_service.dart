import 'package:calcademy/features/ai_assistant/domain/ai_assistant_result.dart';

abstract interface class AiAssistantService {
  Future<AiAssistantResult> analyze(
    String input, {
    required String languageCode,
  });
}

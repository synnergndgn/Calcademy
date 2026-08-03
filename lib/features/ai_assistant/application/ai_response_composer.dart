import 'package:calcademy/features/ai_assistant/domain/ai_assistant_message.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_assistant_role.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_problem_intent.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_solution_plan.dart';

class AiResponseComposer {
  const AiResponseComposer();

  AiAssistantMessage compose(AiSolutionPlan plan, String languageCode) {
    final isTurkish = languageCode == 'tr';
    final isOutOfScope =
        plan.intent == AiProblemIntent.outOfScope ||
        plan.intent == AiProblemIntent.unsupported;
    final text = isOutOfScope
        ? (isTurkish
              ? 'Bu asistan yalnızca Calcademy içindeki hesaplama, formül ve öğrenme araçlarıyla yardımcı olmak için tasarlanmıştır.'
              : 'This assistant is designed to help only with Calcademy calculation, formula, and learning tools.')
        : _supportedText(plan, languageCode);
    final safetyNotice = plan.intent == AiProblemIntent.finance
        ? (isTurkish
              ? 'Finansal hesaplamalar yalnızca bilgilendirme ve eğitim amaçlıdır; finansal tavsiye değildir.'
              : 'Financial calculations are for informational and educational purposes only and are not financial advice.')
        : null;
    final now = DateTime.now();
    return AiAssistantMessage(
      id: 'assistant-${now.microsecondsSinceEpoch}',
      role: AiAssistantRole.assistant,
      text: text,
      createdAt: now,
      relatedToolIds: plan.relatedToolIds,
      relatedFormulaIds: plan.relatedFormulaIds,
      solutionPlan: plan,
      safetyNotice: safetyNotice,
    );
  }

  String _supportedText(AiSolutionPlan plan, String languageCode) {
    final steps = plan.steps(languageCode);
    if (steps.isEmpty) return plan.summary(languageCode);
    final buffer = StringBuffer(plan.summary(languageCode));
    for (var index = 0; index < steps.length; index++) {
      buffer.write('\n${index + 1}. ${steps[index]}');
    }
    return buffer.toString();
  }
}

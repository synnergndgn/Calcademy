import 'package:calcademy/features/ai_assistant/domain/ai_problem_intent.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_solution_plan.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_tool_call_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AiProblemIntent exposes the supported intent mapping', () {
    expect(AiProblemIntent.values, contains(AiProblemIntent.matrix));
    expect(AiProblemIntent.values, contains(AiProblemIntent.finance));
    expect(AiProblemIntent.values, contains(AiProblemIntent.outOfScope));
  });

  test('AiSolutionPlan preserves bilingual plan metadata', () {
    const plan = AiSolutionPlan(
      intent: AiProblemIntent.matrix,
      confidence: 0.9,
      summaryEn: 'Matrix plan',
      summaryTr: 'Matris planı',
      stepsEn: ['Open matrix'],
      stepsTr: ['Matrisi aç'],
      relatedToolIds: ['matrix'],
      relatedFormulaIds: ['determinant-2x2'],
      canOpenTool: true,
      canOpenFormula: true,
    );
    expect(plan.summary('en'), 'Matrix plan');
    expect(plan.summary('tr'), 'Matris planı');
    expect(plan.steps('tr'), ['Matrisi aç']);
  });

  test('AiToolCallPlan keeps route and future prefill metadata', () {
    const plan = AiToolCallPlan(
      toolId: 'scientific_calculator',
      route: '/calculator',
      displayName: 'Scientific Calculator',
      reasonEn: 'Calculate locally.',
      reasonTr: 'Yerel hesapla.',
      prefillPayload: {'expression': '2+2'},
      prefillSupported: true,
    );
    expect(plan.route, '/calculator');
    expect(plan.prefillSupported, isTrue);
    expect(plan.prefillPayload, {'expression': '2+2'});
  });
}

import 'package:calcademy/app/tools/calcademy_tool_registry.dart';
import 'package:calcademy/features/ai_assistant/application/ai_tool_planner.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_problem_intent.dart';
import 'package:calcademy/features/formula_library/domain/formula_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const planner = AiToolPlanner();

  test('every supported plan references valid registry entries', () {
    const intents = [
      AiProblemIntent.scientificCalculation,
      AiProblemIntent.graphing,
      AiProblemIntent.matrix,
      AiProblemIntent.equationSolving,
      AiProblemIntent.calculus,
      AiProblemIntent.statistics,
      AiProblemIntent.finance,
      AiProblemIntent.linearProgramming,
      AiProblemIntent.integerProgramming,
      AiProblemIntent.operationsResearch,
    ];
    for (final intent in intents) {
      final result = planner.createPlan(intent, intent.name);
      expect(result.plan.relatedToolIds, isNotEmpty, reason: intent.name);
      for (final id in result.plan.relatedToolIds) {
        expect(
          CalcademyToolRegistry.byId(id),
          isNotNull,
          reason: '$intent/$id',
        );
      }
      for (final id in result.plan.relatedFormulaIds) {
        expect(FormulaRegistry.byId(id), isNotNull, reason: '$intent/$id');
      }
      for (final toolPlan in result.toolPlans) {
        expect(toolPlan.route, startsWith('/'));
        expect(
          CalcademyToolRegistry.byId(toolPlan.toolId)?.route,
          toolPlan.route,
        );
      }
    }
  });

  test('formula lookup suggestions are valid registry formulas', () {
    final result = planner.createPlan(
      AiProblemIntent.formulaLookup,
      'standard deviation formula',
    );
    expect(result.plan.relatedFormulaIds, contains('standard-deviation'));
    for (final id in result.plan.relatedFormulaIds) {
      expect(FormulaRegistry.byId(id), isNotNull);
    }
  });
}

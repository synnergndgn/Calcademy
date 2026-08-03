import 'package:calcademy/app/tools/calcademy_tool_registry.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_assistant_limits.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_problem_intent.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_solution_plan.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_tool_call_plan.dart';
import 'package:calcademy/features/formula_library/domain/formula_registry.dart';

class AiPlanningResult {
  const AiPlanningResult({required this.plan, required this.toolPlans});

  final AiSolutionPlan plan;
  final List<AiToolCallPlan> toolPlans;
}

class AiToolPlanner {
  const AiToolPlanner();

  AiPlanningResult createPlan(AiProblemIntent intent, String input) {
    final config = _configFor(intent);
    final toolIds = [if (config.toolId case final String id) id];
    final formulaIds = intent == AiProblemIntent.formulaLookup
        ? _searchFormulaIds(input)
        : config.formulaIds
              .where((id) => FormulaRegistry.byId(id) != null)
              .take(AiAssistantLimits.maxFormulaSuggestions)
              .toList(growable: false);
    final toolPlans = toolIds
        .map(CalcademyToolRegistry.byId)
        .whereType()
        .map(
          (tool) => AiToolCallPlan(
            toolId: tool.id,
            route: tool.route,
            displayName: tool.titleEn,
            reasonEn: config.reasonEn,
            reasonTr: config.reasonTr,
            prefillSupported: tool.supportsPrefill,
          ),
        )
        .toList(growable: false);
    return AiPlanningResult(
      toolPlans: toolPlans,
      plan: AiSolutionPlan(
        intent: intent,
        confidence: intent == AiProblemIntent.unsupported ? 0 : 0.9,
        summaryEn: config.summaryEn,
        summaryTr: config.summaryTr,
        stepsEn: config.stepsEn,
        stepsTr: config.stepsTr,
        relatedToolIds: toolPlans.map((item) => item.toolId).toList(),
        relatedFormulaIds: formulaIds,
        canOpenTool: toolPlans.isNotEmpty,
        canOpenFormula: formulaIds.isNotEmpty,
        warning: intent == AiProblemIntent.finance ? 'financial' : null,
      ),
    );
  }

  List<String> _searchFormulaIds(String input) {
    final matches = FormulaRegistry.search(query: input);
    if (matches.isNotEmpty) {
      return matches
          .take(AiAssistantLimits.maxFormulaSuggestions)
          .map((item) => item.id)
          .toList(growable: false);
    }
    final ignored = {'formula', 'formül', 'formul', 'how', 'what', 'nedir'};
    final tokens = input
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9çğıöşü-]+'))
        .where((token) => token.length > 2 && !ignored.contains(token));
    final ids = <String>[];
    for (final token in tokens) {
      for (final formula in FormulaRegistry.search(query: token)) {
        if (!ids.contains(formula.id)) ids.add(formula.id);
        if (ids.length == AiAssistantLimits.maxFormulaSuggestions) return ids;
      }
    }
    return ids;
  }

  _IntentConfig _configFor(AiProblemIntent intent) => switch (intent) {
    AiProblemIntent.scientificCalculation => const _IntentConfig(
      toolId: 'scientific_calculator',
      formulaIds: ['distance-formula'],
      summaryEn: 'Use Calcademy’s Scientific Calculator for this calculation.',
      summaryTr:
          'Bu hesaplama için Calcademy Bilimsel Hesap Makinesi’ni kullanın.',
      reasonEn: 'It evaluates numerical and scientific expressions locally.',
      reasonTr: 'Sayısal ve bilimsel ifadeleri cihazda hesaplar.',
    ),
    AiProblemIntent.graphing => const _IntentConfig(
      toolId: 'graph_plotter',
      formulaIds: ['slope', 'tangent-line'],
      summaryEn: 'Use the Graph Plotter to draw and inspect the function.',
      summaryTr:
          'Fonksiyonu çizmek ve incelemek için Grafik Çizici’yi kullanın.',
      reasonEn: 'It plots real single-variable functions.',
      reasonTr: 'Gerçek tek değişkenli fonksiyonları çizer.',
    ),
    AiProblemIntent.matrix => const _IntentConfig(
      toolId: 'matrix',
      formulaIds: ['determinant-2x2', 'inverse-2x2', 'cramers-rule'],
      summaryEn: 'Use the Matrices & Linear Algebra tool for this problem.',
      summaryTr: 'Bu problem için Matrisler ve Lineer Cebir aracını kullanın.',
      reasonEn: 'It supports determinants, inverses, and row operations.',
      reasonTr: 'Determinant, ters matris ve satır işlemlerini destekler.',
    ),
    AiProblemIntent.equationSolving => const _IntentConfig(
      toolId: 'equation_solver',
      formulaIds: ['quadratic-formula', 'cramers-rule'],
      summaryEn: 'Use Equation Solver to find roots or solve a system.',
      summaryTr:
          'Kökleri veya bir sistemi çözmek için Denklem Çözücü’yü kullanın.',
      reasonEn: 'It solves equations and linear systems.',
      reasonTr: 'Denklemleri ve lineer sistemleri çözer.',
    ),
    AiProblemIntent.calculus => const _IntentConfig(
      toolId: 'calculus',
      formulaIds: [
        'power-rule-derivative',
        'definite-integral',
        'tangent-line',
      ],
      summaryEn: 'Use the Calculus workspace for this analysis.',
      summaryTr: 'Bu analiz için Kalkülüs çalışma alanını kullanın.',
      reasonEn: 'It differentiates, integrates, and analyzes functions.',
      reasonTr: 'Fonksiyonların türevini, integralini ve analizini yapar.',
    ),
    AiProblemIntent.statistics => const _IntentConfig(
      toolId: 'statistics',
      formulaIds: ['arithmetic-mean', 'standard-deviation', 'z-score'],
      summaryEn: 'Use Statistics to summarize the data and select a method.',
      summaryTr:
          'Verileri özetlemek ve yöntem seçmek için İstatistik aracını kullanın.',
      reasonEn: 'It calculates descriptive statistics and distributions.',
      reasonTr: 'Betimsel istatistikleri ve dağılımları hesaplar.',
    ),
    AiProblemIntent.finance => const _IntentConfig(
      toolId: 'financial_calculator',
      formulaIds: [
        'net-present-value',
        'internal-rate-return',
        'compound-interest',
      ],
      summaryEn: 'Use Financial Calculator for an educational calculation.',
      summaryTr:
          'Eğitim amaçlı hesaplama için Finansal Hesap Makinesi’ni kullanın.',
      reasonEn: 'It evaluates time value, cash flows, and loans.',
      reasonTr:
          'Paranın zaman değerini, nakit akışlarını ve kredileri hesaplar.',
    ),
    AiProblemIntent.linearProgramming => const _IntentConfig(
      toolId: 'linear_programming',
      formulaIds: ['lp-objective', 'constraint-standard-form'],
      summaryEn:
          'Define decision variables, an objective, and constraints first.',
      summaryTr:
          'Önce karar değişkenlerini, amaç fonksiyonunu ve kısıtları tanımlayın.',
      reasonEn: 'It models and solves continuous linear programs.',
      reasonTr: 'Sürekli doğrusal programları modeller ve çözer.',
    ),
    AiProblemIntent.integerProgramming => const _IntentConfig(
      toolId: 'integer_programming',
      formulaIds: ['lp-objective', 'constraint-standard-form'],
      summaryEn: 'Use Integer Programming when decisions must be discrete.',
      summaryTr:
          'Kararlar kesikli olduğunda Tam Sayılı Programlama’yı kullanın.',
      reasonEn: 'It models discrete optimization decisions.',
      reasonTr: 'Kesikli optimizasyon kararlarını modeller.',
    ),
    AiProblemIntent.operationsResearch => const _IntentConfig(
      toolId: 'operations_research',
      formulaIds: [
        'transportation-balance',
        'assignment-objective',
        'cpm-es-ef',
      ],
      summaryEn: 'Choose the matching Operations Research model.',
      summaryTr: 'Uygun Yöneylem Araştırması modelini seçin.',
      reasonEn:
          'It supports transportation, assignment, CPM/PERT, and goal models.',
      reasonTr: 'Taşıma, atama, CPM/PERT ve hedef modellerini destekler.',
    ),
    AiProblemIntent.formulaLookup => const _IntentConfig(
      summaryEn: 'Review the matching formulas in Calcademy’s Formula Library.',
      summaryTr:
          'Eşleşen formülleri Calcademy Formül Kütüphanesi’nde inceleyin.',
      reasonEn: 'The Formula Library explains supported formulas.',
      reasonTr: 'Formül Kütüphanesi desteklenen formülleri açıklar.',
    ),
    AiProblemIntent.unsupported ||
    AiProblemIntent.outOfScope => const _IntentConfig(
      summaryEn:
          'This request is outside the supported Calcademy assistance scope.',
      summaryTr: 'Bu istek desteklenen Calcademy yardım kapsamının dışındadır.',
      reasonEn: '',
      reasonTr: '',
      stepsEn: [],
      stepsTr: [],
    ),
  };
}

class _IntentConfig {
  const _IntentConfig({
    required this.summaryEn,
    required this.summaryTr,
    required this.reasonEn,
    required this.reasonTr,
    this.toolId,
    this.formulaIds = const [],
    this.stepsEn = const [
      'Identify the known values and the requested result.',
      'Open the suggested Calcademy tool or formula.',
      'Enter the values, calculate, and review the method and units.',
    ],
    this.stepsTr = const [
      'Bilinen değerleri ve istenen sonucu belirleyin.',
      'Önerilen Calcademy aracını veya formülü açın.',
      'Değerleri girin, hesaplayın; yöntemi ve birimleri kontrol edin.',
    ],
  });

  final String? toolId;
  final List<String> formulaIds;
  final String summaryEn;
  final String summaryTr;
  final String reasonEn;
  final String reasonTr;
  final List<String> stepsEn;
  final List<String> stepsTr;
}

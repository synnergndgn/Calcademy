import 'package:calcademy/app/tools/calcademy_tool.dart';
import 'package:calcademy/app/tools/calcademy_tool_route.dart';
import 'package:calcademy/features/formula_library/domain/formula_category.dart';

abstract final class CalcademyToolRegistry {
  static const tools = <CalcademyTool>[
    CalcademyTool(
      id: 'scientific_calculator',
      titleEn: 'Scientific Calculator',
      titleTr: 'Bilimsel Hesap Makinesi',
      route: CalcademyToolRoute.calculator,
      descriptionEn: 'Evaluate numerical and scientific expressions.',
      descriptionTr: 'Sayısal ve bilimsel ifadeleri hesaplayın.',
      supportedFormulaCategories: {
        FormulaCategory.mathematics,
        FormulaCategory.algebra,
      },
      supportsPrefill: true,
      inputSchema: {'expression': 'string'},
    ),
    CalcademyTool(
      id: 'graph_plotter',
      titleEn: 'Graph Plotter',
      titleTr: 'Grafik Çizici',
      route: CalcademyToolRoute.graph,
      descriptionEn: 'Plot real single-variable functions.',
      descriptionTr: 'Gerçek tek değişkenli fonksiyonları çizin.',
      supportedFormulaCategories: {
        FormulaCategory.mathematics,
        FormulaCategory.algebra,
        FormulaCategory.calculus,
      },
    ),
    CalcademyTool(
      id: 'matrix',
      titleEn: 'Matrices & Linear Algebra',
      titleTr: 'Matrisler ve Lineer Cebir',
      route: CalcademyToolRoute.matrix,
      descriptionEn: 'Calculate matrix operations and linear systems.',
      descriptionTr: 'Matris işlemlerini ve lineer sistemleri hesaplayın.',
      supportedFormulaCategories: {FormulaCategory.linearAlgebra},
    ),
    CalcademyTool(
      id: 'equation_solver',
      titleEn: 'Equation Solver',
      titleTr: 'Denklem Çözücü',
      route: CalcademyToolRoute.equationSolver,
      descriptionEn: 'Solve equations and linear systems.',
      descriptionTr: 'Denklemleri ve lineer sistemleri çözün.',
      supportedFormulaCategories: {FormulaCategory.algebra},
    ),
    CalcademyTool(
      id: 'calculus',
      titleEn: 'Calculus',
      titleTr: 'Kalkülüs',
      route: CalcademyToolRoute.calculus,
      descriptionEn: 'Differentiate, integrate, and analyze functions.',
      descriptionTr: 'Fonksiyonların türevini, integralini ve analizini yapın.',
      supportedFormulaCategories: {FormulaCategory.calculus},
    ),
    CalcademyTool(
      id: 'statistics',
      titleEn: 'Statistics',
      titleTr: 'İstatistik',
      route: CalcademyToolRoute.statistics,
      descriptionEn: 'Analyze data and probability distributions.',
      descriptionTr: 'Verileri ve olasılık dağılımlarını analiz edin.',
      supportedFormulaCategories: {FormulaCategory.statisticsProbability},
    ),
    CalcademyTool(
      id: 'financial_calculator',
      titleEn: 'Financial Calculator',
      titleTr: 'Finansal Hesap Makinesi',
      route: CalcademyToolRoute.financialCalculator,
      descriptionEn: 'Evaluate time value, cash flows, and loans.',
      descriptionTr:
          'Paranın zaman değerini, nakit akışlarını ve kredileri değerlendirin.',
      supportedFormulaCategories: {
        FormulaCategory.finance,
        FormulaCategory.engineeringEconomy,
      },
    ),
    CalcademyTool(
      id: 'linear_programming',
      titleEn: 'Linear Programming',
      titleTr: 'Doğrusal Programlama',
      route: CalcademyToolRoute.linearProgramming,
      descriptionEn: 'Model and solve continuous linear programs.',
      descriptionTr: 'Sürekli doğrusal programları modelleyin ve çözün.',
      supportedFormulaCategories: {
        FormulaCategory.optimization,
        FormulaCategory.operationsResearch,
      },
    ),
    CalcademyTool(
      id: 'integer_programming',
      titleEn: 'Integer Programming',
      titleTr: 'Tam Sayılı Programlama',
      route: CalcademyToolRoute.integerProgramming,
      descriptionEn: 'Model discrete optimization decisions.',
      descriptionTr: 'Kesikli optimizasyon kararlarını modelleyin.',
      supportedFormulaCategories: {
        FormulaCategory.optimization,
        FormulaCategory.operationsResearch,
      },
    ),
    CalcademyTool(
      id: 'operations_research',
      titleEn: 'Operations Research',
      titleTr: 'Yöneylem Araştırması',
      route: CalcademyToolRoute.operationsResearch,
      descriptionEn: 'Solve networks, assignments, and transportation models.',
      descriptionTr: 'Ağ, atama ve taşıma modellerini çözün.',
      supportedFormulaCategories: {FormulaCategory.operationsResearch},
    ),
    CalcademyTool(
      id: 'saved',
      titleEn: 'Saved',
      titleTr: 'Kaydedilenler',
      route: CalcademyToolRoute.saved,
      descriptionEn: 'Open locally saved work.',
      descriptionTr: 'Yerel olarak kaydedilen çalışmaları açın.',
      supportedFormulaCategories: {
        FormulaCategory.mathematics,
        FormulaCategory.algebra,
        FormulaCategory.calculus,
        FormulaCategory.linearAlgebra,
        FormulaCategory.statisticsProbability,
        FormulaCategory.finance,
        FormulaCategory.engineeringEconomy,
        FormulaCategory.optimization,
        FormulaCategory.operationsResearch,
      },
    ),
  ];

  static final Map<String, CalcademyTool> _byId = {
    for (final tool in tools) tool.id: tool,
  };

  static CalcademyTool? byId(String id) => _byId[id];
}

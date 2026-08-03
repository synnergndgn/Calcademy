import 'package:flutter/material.dart';

enum AcademyModuleCategory {
  mathematics('categoryMathematics'),
  optimization('categoryOptimization'),
  data('categoryDataStatistics'),
  finance('categoryFinance'),
  workspace('categoryWorkspace');

  const AcademyModuleCategory(this.localizationKey);

  final String localizationKey;
}

class AcademyModule {
  const AcademyModule({
    required this.id,
    required this.titleKey,
    required this.icon,
    required this.category,
    this.route,
    this.descriptionKey = 'plannedFeature',
    this.searchTerms = const [],
    this.available = false,
  });

  final String id;
  final String titleKey;
  final IconData icon;
  final AcademyModuleCategory category;
  final String? route;
  final String descriptionKey;
  final List<String> searchTerms;
  final bool available;
}

const academyModules = [
  AcademyModule(
    id: 'ai-assistant',
    titleKey: 'aiAssistantTitle',
    icon: Icons.auto_awesome_rounded,
    category: AcademyModuleCategory.workspace,
    route: '/assistant',
    descriptionKey: 'aiAssistantSubtitle',
    searchTerms: ['ai', 'assistant', 'asistan', 'yardım', 'çözüm', 'problem'],
    available: true,
  ),
  AcademyModule(
    id: 'formula-library',
    titleKey: 'formulaLibraryTitle',
    icon: Icons.menu_book_rounded,
    category: AcademyModuleCategory.workspace,
    route: '/formulas',
    descriptionKey: 'formulaLibrarySubtitle',
    searchTerms: ['formula', 'formül', 'library', 'kütüphane', 'npv', 'nbd'],
    available: true,
  ),
  AcademyModule(
    id: 'saved',
    titleKey: 'saved',
    icon: Icons.bookmarks_rounded,
    category: AcademyModuleCategory.workspace,
    route: '/saved',
    descriptionKey: 'savedCalculationsDescription',
    searchTerms: [
      'saved',
      'save',
      'saved calculations',
      'kaydedilenler',
      'kaydedilen hesaplamalar',
      'kayıtlı',
      'favori',
    ],
    available: true,
  ),
  AcademyModule(
    id: 'calculator',
    titleKey: 'calculator',
    icon: Icons.calculate_rounded,
    category: AcademyModuleCategory.mathematics,
    route: '/calculator',
    descriptionKey: 'calculatorDescription',
    searchTerms: ['calculator', 'hesap makinesi', 'scientific', 'bilimsel'],
    available: true,
  ),
  AcademyModule(
    id: 'graphing',
    titleKey: 'graphing',
    icon: Icons.show_chart_rounded,
    category: AcademyModuleCategory.mathematics,
    route: '/graph',
    descriptionKey: 'graphDescription',
    searchTerms: ['graph', 'grafik', 'plot', 'çizim'],
    available: true,
  ),
  AcademyModule(
    id: 'matrices',
    titleKey: 'matrices',
    icon: Icons.grid_on_rounded,
    category: AcademyModuleCategory.mathematics,
    route: '/matrix',
    descriptionKey: 'matrixDescription',
    searchTerms: ['matrix', 'matris', 'linear algebra', 'lineer cebir'],
    available: true,
  ),
  AcademyModule(
    id: 'equations',
    titleKey: 'equations',
    icon: Icons.functions_rounded,
    category: AcademyModuleCategory.mathematics,
    route: '/equation-solver',
    descriptionKey: 'equationSolverDescription',
    searchTerms: [
      'equation',
      'denklem',
      'solver',
      'çözücü',
      'algebra',
      'cebir',
    ],
    available: true,
  ),
  AcademyModule(
    id: 'calculus',
    titleKey: 'calculus',
    icon: Icons.area_chart_rounded,
    category: AcademyModuleCategory.mathematics,
    route: '/calculus',
    descriptionKey: 'calculusDescription',
    searchTerms: ['calculus', 'kalkülüs', 'derivative', 'türev', 'integral'],
    available: true,
  ),
  AcademyModule(
    id: 'statistics',
    titleKey: 'statistics',
    icon: Icons.bar_chart_rounded,
    category: AcademyModuleCategory.data,
    route: '/statistics',
    descriptionKey: 'statisticsDescription',
    searchTerms: ['statistics', 'istatistik', 'probability', 'olasılık'],
    available: true,
  ),
  AcademyModule(
    id: 'financial-calculator',
    titleKey: 'financialCalculator',
    icon: Icons.account_balance_wallet_rounded,
    category: AcademyModuleCategory.finance,
    route: '/financial-calculator',
    descriptionKey: 'financialCalculatorDescription',
    searchTerms: ['finance', 'finans', 'npv', 'nbd', 'irr', 'faiz'],
    available: true,
  ),
  AcademyModule(
    id: 'linear-programming',
    titleKey: 'linearProgramming',
    icon: Icons.polyline_rounded,
    category: AcademyModuleCategory.optimization,
    route: '/linear-programming',
    descriptionKey: 'linearProgrammingDescription',
    searchTerms: [
      'lp',
      'linear programming',
      'doğrusal programlama',
      'optimization',
      'optimizasyon',
    ],
    available: true,
  ),
  AcademyModule(
    id: 'integer-programming',
    titleKey: 'integerProgramming',
    icon: Icons.scatter_plot_rounded,
    category: AcademyModuleCategory.optimization,
    route: '/integer-programming',
    descriptionKey: 'integerProgrammingDescription',
    searchTerms: ['ip', 'integer programming', 'tam sayılı programlama', 'mip'],
    available: true,
  ),
  AcademyModule(
    id: 'operations-research',
    titleKey: 'operationsResearch',
    icon: Icons.route_rounded,
    category: AcademyModuleCategory.optimization,
    route: '/operations-research',
    descriptionKey: 'operationsResearchDescription',
    searchTerms: [
      'operations research',
      'yöneylem araştırması',
      'or',
      'cpm',
      'pert',
    ],
    available: true,
  ),
  AcademyModule(
    id: 'nonlinear-optimization',
    titleKey: 'nonlinearOptimization',
    icon: Icons.hub_rounded,
    category: AcademyModuleCategory.optimization,
    searchTerms: ['nonlinear', 'nonlineer', 'optimization', 'optimizasyon'],
  ),
  AcademyModule(
    id: 'dynamic-programming',
    titleKey: 'dynamicProgramming',
    icon: Icons.account_tree_rounded,
    category: AcademyModuleCategory.optimization,
    searchTerms: ['dynamic programming', 'dinamik programlama'],
  ),
  AcademyModule(
    id: 'numerical-methods',
    titleKey: 'numericalMethods',
    icon: Icons.timeline_rounded,
    category: AcademyModuleCategory.mathematics,
    searchTerms: ['numerical methods', 'sayısal yöntemler'],
  ),
];

const quickAccessModuleIds = [
  'ai-assistant',
  'calculator',
  'graphing',
  'matrices',
  'equations',
  'formula-library',
  'saved',
];

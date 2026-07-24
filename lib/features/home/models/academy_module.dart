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
    this.available = false,
  });

  final String id;
  final String titleKey;
  final IconData icon;
  final AcademyModuleCategory category;
  final String? route;
  final String descriptionKey;
  final bool available;
}

const academyModules = [
  AcademyModule(
    id: 'calculator',
    titleKey: 'calculator',
    icon: Icons.calculate_rounded,
    category: AcademyModuleCategory.mathematics,
    route: '/calculator',
    descriptionKey: 'calculatorDescription',
    available: true,
  ),
  AcademyModule(
    id: 'graphing',
    titleKey: 'graphing',
    icon: Icons.show_chart_rounded,
    category: AcademyModuleCategory.mathematics,
    route: '/graph',
    descriptionKey: 'graphDescription',
    available: true,
  ),
  AcademyModule(
    id: 'matrices',
    titleKey: 'matrices',
    icon: Icons.grid_on_rounded,
    category: AcademyModuleCategory.mathematics,
    route: '/matrix',
    descriptionKey: 'matrixDescription',
    available: true,
  ),
  AcademyModule(
    id: 'equations',
    titleKey: 'equations',
    icon: Icons.functions_rounded,
    category: AcademyModuleCategory.mathematics,
    route: '/equation-solver',
    descriptionKey: 'equationSolverDescription',
    available: true,
  ),
  AcademyModule(
    id: 'calculus',
    titleKey: 'calculus',
    icon: Icons.area_chart_rounded,
    category: AcademyModuleCategory.mathematics,
    route: '/calculus',
    descriptionKey: 'calculusDescription',
    available: true,
  ),
  AcademyModule(
    id: 'statistics',
    titleKey: 'statistics',
    icon: Icons.bar_chart_rounded,
    category: AcademyModuleCategory.data,
    route: '/statistics',
    descriptionKey: 'statisticsDescription',
    available: true,
  ),
  AcademyModule(
    id: 'financial-calculator',
    titleKey: 'financialCalculator',
    icon: Icons.account_balance_wallet_rounded,
    category: AcademyModuleCategory.finance,
    route: '/financial-calculator',
    descriptionKey: 'financialCalculatorDescription',
    available: true,
  ),
  AcademyModule(
    id: 'linear-programming',
    titleKey: 'linearProgramming',
    icon: Icons.polyline_rounded,
    category: AcademyModuleCategory.optimization,
    route: '/linear-programming',
    descriptionKey: 'linearProgrammingDescription',
    available: true,
  ),
  AcademyModule(
    id: 'integer-programming',
    titleKey: 'integerProgramming',
    icon: Icons.scatter_plot_rounded,
    category: AcademyModuleCategory.optimization,
    route: '/integer-programming',
    descriptionKey: 'integerProgrammingDescription',
    available: true,
  ),
  AcademyModule(
    id: 'operations-research',
    titleKey: 'operationsResearch',
    icon: Icons.route_rounded,
    category: AcademyModuleCategory.optimization,
    route: '/operations-research',
    descriptionKey: 'operationsResearchDescription',
    available: true,
  ),
  AcademyModule(
    id: 'nonlinear-optimization',
    titleKey: 'nonlinearOptimization',
    icon: Icons.hub_rounded,
    category: AcademyModuleCategory.optimization,
  ),
  AcademyModule(
    id: 'dynamic-programming',
    titleKey: 'dynamicProgramming',
    icon: Icons.account_tree_rounded,
    category: AcademyModuleCategory.optimization,
  ),
  AcademyModule(
    id: 'numerical-methods',
    titleKey: 'numericalMethods',
    icon: Icons.timeline_rounded,
    category: AcademyModuleCategory.mathematics,
  ),
];

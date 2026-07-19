import 'package:flutter/material.dart';

class AcademyModule {
  const AcademyModule({
    required this.id,
    required this.titleKey,
    required this.icon,
    this.route,
    this.descriptionKey = 'plannedFeature',
    this.available = false,
  });

  final String id;
  final String titleKey;
  final IconData icon;
  final String? route;
  final String descriptionKey;
  final bool available;
}

const academyModules = [
  AcademyModule(
    id: 'calculator',
    titleKey: 'calculator',
    icon: Icons.calculate_rounded,
    route: '/calculator',
    descriptionKey: 'calculatorDescription',
    available: true,
  ),
  AcademyModule(
    id: 'graphing',
    titleKey: 'graphing',
    icon: Icons.show_chart_rounded,
    route: '/graph',
    descriptionKey: 'graphDescription',
    available: true,
  ),
  AcademyModule(
    id: 'matrices',
    titleKey: 'matrices',
    icon: Icons.grid_on_rounded,
    route: '/matrix',
    descriptionKey: 'matrixDescription',
    available: true,
  ),
  AcademyModule(
    id: 'equations',
    titleKey: 'equations',
    icon: Icons.functions_rounded,
    route: '/equation-solver',
    descriptionKey: 'equationSolverDescription',
    available: true,
  ),
  AcademyModule(
    id: 'calculus',
    titleKey: 'calculus',
    icon: Icons.area_chart_rounded,
    route: '/calculus',
    descriptionKey: 'calculusDescription',
    available: true,
  ),
  AcademyModule(
    id: 'statistics',
    titleKey: 'statistics',
    icon: Icons.bar_chart_rounded,
  ),
  AcademyModule(
    id: 'linear-programming',
    titleKey: 'linearProgramming',
    icon: Icons.polyline_rounded,
    route: '/linear-programming',
    descriptionKey: 'linearProgrammingDescription',
    available: true,
  ),
  AcademyModule(
    id: 'integer-programming',
    titleKey: 'integerProgramming',
    icon: Icons.scatter_plot_rounded,
    route: '/integer-programming',
    descriptionKey: 'integerProgrammingDescription',
    available: true,
  ),
  AcademyModule(
    id: 'nonlinear-optimization',
    titleKey: 'nonlinearOptimization',
    icon: Icons.hub_rounded,
  ),
  AcademyModule(
    id: 'dynamic-programming',
    titleKey: 'dynamicProgramming',
    icon: Icons.account_tree_rounded,
  ),
  AcademyModule(
    id: 'numerical-methods',
    titleKey: 'numericalMethods',
    icon: Icons.timeline_rounded,
  ),
];

import 'package:flutter/material.dart';

class AcademyModule {
  const AcademyModule({
    required this.id,
    required this.titleKey,
    required this.icon,
    this.available = false,
  });

  final String id;
  final String titleKey;
  final IconData icon;
  final bool available;
}

const academyModules = [
  AcademyModule(
    id: 'calculator',
    titleKey: 'calculator',
    icon: Icons.calculate_rounded,
    available: true,
  ),
  AcademyModule(
    id: 'graphing',
    titleKey: 'graphing',
    icon: Icons.show_chart_rounded,
  ),
  AcademyModule(
    id: 'matrices',
    titleKey: 'matrices',
    icon: Icons.grid_on_rounded,
  ),
  AcademyModule(
    id: 'equations',
    titleKey: 'equations',
    icon: Icons.functions_rounded,
  ),
  AcademyModule(
    id: 'calculus',
    titleKey: 'calculus',
    icon: Icons.area_chart_rounded,
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
  ),
  AcademyModule(
    id: 'integer-programming',
    titleKey: 'integerProgramming',
    icon: Icons.scatter_plot_rounded,
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

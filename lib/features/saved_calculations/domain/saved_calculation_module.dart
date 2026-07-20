enum SavedCalculationModule {
  scientificCalculator(
    id: 'scientific-calculator',
    titleKey: 'calculator',
    route: '/calculator',
  ),
  graphPlotter(id: 'graph-plotter', titleKey: 'graphing', route: '/graph'),
  financialCalculator(
    id: 'financial-calculator',
    titleKey: 'financialCalculator',
    route: '/financial-calculator',
  ),
  statistics(id: 'statistics', titleKey: 'statistics', route: '/statistics'),
  calculus(id: 'calculus', titleKey: 'calculus', route: '/calculus'),
  equationSolver(
    id: 'equation-solver',
    titleKey: 'equations',
    route: '/equation-solver',
  ),
  matrix(id: 'matrix', titleKey: 'matrices', route: '/matrix'),
  linearProgramming(
    id: 'linear-programming',
    titleKey: 'linearProgramming',
    route: '/linear-programming',
  ),
  integerProgramming(
    id: 'integer-programming',
    titleKey: 'integerProgramming',
    route: '/integer-programming',
  ),
  unknown(id: 'unknown', titleKey: 'savedUnknownModule', route: null);

  const SavedCalculationModule({
    required this.id,
    required this.titleKey,
    required this.route,
  });

  final String id;
  final String titleKey;
  final String? route;

  static SavedCalculationModule fromId(String id) => values.firstWhere(
    (module) => module.id == id,
    orElse: () => SavedCalculationModule.unknown,
  );
}

enum SavedCalculationsScope { all, favorites }

enum SavedCalculationsSort { newestFirst, oldestFirst, favoritesFirst }

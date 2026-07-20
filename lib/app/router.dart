import 'package:calcademy/app/navigation_shell.dart';
import 'package:calcademy/features/calculator/presentation/calculator_page.dart';
import 'package:calcademy/features/history/presentation/history_page.dart';
import 'package:calcademy/features/graph/presentation/graph_page.dart';
import 'package:calcademy/features/home/presentation/coming_soon_page.dart';
import 'package:calcademy/features/home/presentation/home_page.dart';
import 'package:calcademy/features/home/presentation/splash_page.dart';
import 'package:calcademy/features/matrix/presentation/matrix_home_page.dart';
import 'package:calcademy/features/linear_programming/presentation/linear_program_page.dart';
import 'package:calcademy/features/integer_programming/presentation/integer_program_home_page.dart';
import 'package:calcademy/features/equation_solver/presentation/equation_solver_page.dart';
import 'package:calcademy/features/calculus/presentation/calculus_page.dart';
import 'package:calcademy/features/statistics/presentation/statistics_page.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_calculator_page.dart';
import 'package:calcademy/features/saved/presentation/saved_page.dart';
import 'package:calcademy/features/saved_calculations/presentation/saved_calculations_page.dart';
import 'package:calcademy/features/settings/presentation/about_page.dart';
import 'package:calcademy/features/settings/presentation/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
    ShellRoute(
      builder: (context, state, child) => NavigationShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryPage(),
        ),
        GoRoute(path: '/saved', builder: (context, state) => const SavedPage()),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/calculator',
      builder: (context, state) => CalculatorPage(
        initialExpression: state.uri.queryParameters['expression'],
      ),
    ),
    GoRoute(
      path: '/graph',
      builder: (context, state) => GraphPage(
        savedGraphId: state.uri.queryParameters['graphId'],
        shareOnOpen: state.uri.queryParameters['share'] == '1',
      ),
    ),
    GoRoute(
      path: '/matrix',
      builder: (context, state) =>
          MatrixHomePage(savedMatrixId: state.uri.queryParameters['savedId']),
    ),
    GoRoute(
      path: '/linear-programming',
      builder: (context, state) =>
          LinearProgramPage(savedId: state.uri.queryParameters['savedId']),
    ),
    GoRoute(
      path: '/integer-programming',
      builder: (context, state) =>
          IntegerProgramHomePage(savedId: state.uri.queryParameters['savedId']),
    ),
    GoRoute(
      path: '/equation-solver',
      builder: (context, state) => const EquationSolverPage(),
    ),
    GoRoute(
      path: '/calculus',
      builder: (context, state) => const CalculusPage(),
    ),
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsPage(),
    ),
    GoRoute(
      path: '/financial-calculator',
      builder: (context, state) => const FinancialCalculatorPage(),
    ),
    GoRoute(
      path: '/saved-calculations',
      builder: (context, state) => const SavedCalculationsPage(),
    ),
    GoRoute(
      path: '/coming-soon/:moduleId',
      builder: (context, state) =>
          ComingSoonPage(moduleId: state.pathParameters['moduleId']!),
    ),
    GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
  ],
);

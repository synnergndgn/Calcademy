import 'package:calcademy/app/navigation_shell.dart';
import 'package:calcademy/features/calculator/presentation/calculator_page.dart';
import 'package:calcademy/features/history/presentation/history_page.dart';
import 'package:calcademy/features/home/presentation/coming_soon_page.dart';
import 'package:calcademy/features/home/presentation/home_page.dart';
import 'package:calcademy/features/home/presentation/splash_page.dart';
import 'package:calcademy/features/saved/presentation/saved_page.dart';
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
      path: '/coming-soon/:moduleId',
      builder: (context, state) =>
          ComingSoonPage(moduleId: state.pathParameters['moduleId']!),
    ),
    GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
  ],
);

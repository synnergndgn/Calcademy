import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/integer_programming/domain/branch_and_bound_solver.dart';
import 'package:calcademy/features/integer_programming/presentation/branch_tree_page.dart';
import 'package:calcademy/features/integer_programming/presentation/integer_program_controller.dart';
import 'package:calcademy/features/integer_programming/presentation/integer_program_home_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the editor, templates and solve button', (tester) async {
    await _pump(tester);
    expect(find.text('Integer Programming'), findsWidgets);
    expect(find.text('New model'), findsWidgets);
    expect(find.text('0-1 Knapsack'), findsWidgets);
    expect(find.byKey(const Key('mip-solve')), findsOneWidget);
  });

  testWidgets('a variable defaults to integer and can be switched to binary', (
    tester,
  ) async {
    await _pump(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Integer'), findsWidgets);
    await tester.tap(find.text('Binary').first);
    await tester.pump();
    expect(find.text('This variable can only be 0 or 1.'), findsOneWidget);
  });

  testWidgets('adds a constraint only via the explicit control', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('1/20'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add constraint'));
    await tester.pumpAndSettle();
    expect(find.text('2/20'), findsOneWidget);
  });

  testWidgets('the model summary reflects variable types', (tester) async {
    await _pump(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Model summary'));
    await tester.pumpAndSettle();
    expect(find.textContaining('∈ Z₊'), findsWidgets);
  });

  testWidgets('solving the knapsack template shows the optimal solution', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.widgetWithText(ActionChip, '0-1 Knapsack'));
    await tester.pump();
    final solveFinder = find.byKey(const Key('mip-solve'));
    await tester.ensureVisible(solveFinder);
    await tester.pumpAndSettle();
    await tester.tap(solveFinder);
    await tester.pumpAndSettle();
    final resultFinder = find.text('Optimal integer solution');
    await tester.ensureVisible(resultFinder);
    await tester.pumpAndSettle();
    expect(resultFinder, findsOneWidget);
    expect(find.text('Z = 22'), findsOneWidget);
  });

  testWidgets(
    'opens the branch tree after solving and shows at least one node',
    (tester) async {
      await _pump(tester);
      await tester.tap(find.widgetWithText(ActionChip, '0-1 Knapsack'));
      await tester.pump();
      final solveFinder = find.byKey(const Key('mip-solve'));
      await tester.ensureVisible(solveFinder);
      await tester.pumpAndSettle();
      await tester.tap(solveFinder);
      await tester.pumpAndSettle();

      final treeButton = find.widgetWithText(
        FilledButton,
        'Branch-and-Bound tree',
      );
      await tester.ensureVisible(treeButton);
      await tester.pumpAndSettle();
      await tester.tap(treeButton);
      await tester.pumpAndSettle();
      expect(find.byType(BranchTreePage), findsOneWidget);
      expect(find.textContaining('Node'), findsWidgets);
    },
  );

  testWidgets('adding a constraint refreshes the live model summary', (
    tester,
  ) async {
    await _pump(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add constraint'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Model summary'));
    await tester.pumpAndSettle();
    expect(find.textContaining('C2'), findsWidgets);
  });

  testWidgets('large text scale does not overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('builds under a dark theme', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          integerProgramSolveExecutorProvider.overrideWithValue(
            (program) async => const BranchAndBoundSolver().solve(program),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const IntegerProgramHomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(WidgetTester tester) async {
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        // Solve in-place instead of spawning a real OS isolate: identical
        // solver logic, but deterministic and fast under flutter test's
        // fake-async harness. See integer_program_controller.dart.
        integerProgramSolveExecutorProvider.overrideWithValue(
          (program) async => const BranchAndBoundSolver().solve(program),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const IntegerProgramHomePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

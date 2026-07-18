import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/integer_programming/domain/branch_and_bound_solver.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program_examples.dart';
import 'package:calcademy/features/integer_programming/presentation/branch_tree_page.dart';
import 'package:calcademy/features/integer_programming/presentation/integer_program_controller.dart';
import 'package:calcademy/features/integer_programming/presentation/integer_program_home_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(
  Widget home, {
  ThemeData? theme,
  Locale locale = const Locale('tr'),
}) => MaterialApp(
  theme: theme ?? AppTheme.light(),
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);

Future<void> _pumpHome(
  WidgetTester tester, {
  ThemeData? theme,
  Locale locale = const Locale('tr'),
}) async {
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        integerProgramSolveExecutorProvider.overrideWithValue(
          (program) async => const BranchAndBoundSolver().solve(program),
        ),
      ],
      child: _app(const IntegerProgramHomePage(), theme: theme, locale: locale),
    ),
  );
  await tester.pumpAndSettle();
}

void _setViewport(WidgetTester tester, Size size, {double textScale = 1.0}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in [320.0, 360.0, 412.0]) {
    testWidgets(
      'home page renders without overflow at ${width.toInt()}px (TR)',
      (tester) async {
        _setViewport(tester, Size(width, 690));
        await _pumpHome(tester);
        expect(tester.takeException(), isNull);

        // Walk the entire page; any RenderFlex overflow throws during layout.
        for (var i = 0; i < 6; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -500));
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets(
    'variable and constraint editors survive 200% text scale at 320px',
    (tester) async {
      _setViewport(tester, const Size(320, 690), textScale: 2.0);
      await _pumpHome(tester);
      expect(tester.takeException(), isNull);
      for (var i = 0; i < 8; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -500));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('type selector fits at 320px with 1.6 text scale in Turkish', (
    tester,
  ) async {
    _setViewport(tester, const Size(320, 690), textScale: 1.6);
    await _pumpHome(tester);
    // The editor card may not be laid out yet (ListView builds lazily), so
    // scroll in fixed steps until the selector text enters the tree.
    for (var i = 0; i < 8 && find.text('Tam sayı').evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    expect(find.text('Tam sayı'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide screens centre the workspace instead of stretching it', (
    tester,
  ) async {
    _setViewport(tester, const Size(1280, 800));
    await _pumpHome(tester);
    final listRect = tester.getRect(find.byType(ListView).first);
    expect(listRect.width, lessThanOrEqualTo(840));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'branch tree caps indentation for deep nodes and scrolls cleanly',
    (tester) async {
      _setViewport(tester, const Size(360, 690));
      // fractionalRelaxation branches once; force a deeper tree with the
      // pure integer example, then render whatever depth it produced. The
      // indent cap itself is asserted geometrically below.
      final result = const BranchAndBoundSolver().solve(
        IntegerProgramExamples.pureIntegerProduction,
      );
      await tester.pumpWidget(
        _app(
          BranchTreePage(
            result: result,
            program: IntegerProgramExamples.pureIntegerProduction,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Every node card must start within the viewport regardless of depth.
      final cards = find.byType(Card);
      for (var i = 0; i < cards.evaluate().length; i++) {
        final rect = tester.getRect(cards.at(i));
        expect(rect.left, lessThan(200), reason: 'card $i indented off-screen');
      }

      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('solution panel renders long status texts unclipped at 320px', (
    tester,
  ) async {
    _setViewport(tester, const Size(320, 690));
    await _pumpHome(tester);
    final chip = find.widgetWithText(ActionChip, '0-1 Sırt Çantası');
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pump();
    final solveFinder = find.byKey(const Key('mip-solve'));
    await tester.ensureVisible(solveFinder);
    await tester.pumpAndSettle();
    await tester.tap(solveFinder);
    await tester.pumpAndSettle();
    final resultFinder = find.text('Optimal tam sayı çözümü');
    await tester.ensureVisible(resultFinder);
    await tester.pumpAndSettle();
    expect(resultFinder, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark theme builds every integer screen without exceptions', (
    tester,
  ) async {
    _setViewport(tester, const Size(360, 690));
    await _pumpHome(tester, theme: AppTheme.dark());
    expect(tester.takeException(), isNull);

    final result = const BranchAndBoundSolver().solve(
      IntegerProgramExamples.knapsack,
    );
    await tester.pumpWidget(
      _app(
        BranchTreePage(
          result: result,
          program: IntegerProgramExamples.knapsack,
        ),
        theme: AppTheme.dark(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

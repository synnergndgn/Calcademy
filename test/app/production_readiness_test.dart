import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/calculator/presentation/calculator_page.dart';
import 'package:calcademy/features/calculus/presentation/calculus_page.dart';
import 'package:calcademy/features/equation_solver/presentation/equation_solver_page.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_calculator_page.dart';
import 'package:calcademy/features/formula_library/presentation/formula_library_page.dart';
import 'package:calcademy/features/graph/presentation/graph_page.dart';
import 'package:calcademy/features/history/presentation/history_page.dart';
import 'package:calcademy/features/home/presentation/home_page.dart';
import 'package:calcademy/features/integer_programming/presentation/integer_program_home_page.dart';
import 'package:calcademy/features/linear_programming/presentation/linear_program_page.dart';
import 'package:calcademy/features/matrix/presentation/matrix_home_page.dart';
import 'package:calcademy/features/operations_research/presentation/operations_research_page.dart';
import 'package:calcademy/features/quiz/presentation/quiz_home_page.dart';
import 'package:calcademy/features/quiz/presentation/quiz_mode_selection_page.dart';
import 'package:calcademy/features/quiz/presentation/quiz_topic_page.dart';
import 'package:calcademy/features/saved/presentation/saved_page.dart';
import 'package:calcademy/features/settings/presentation/about_page.dart';
import 'package:calcademy/features/settings/presentation/settings_page.dart';
import 'package:calcademy/features/statistics/presentation/statistics_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every major page, rendered in the shapes that actually break layouts.
///
/// The 1.9 polish sprint changed the body structure of eight pages to share one
/// width-constraining wrapper. A per-page smoke matrix is what catches a
/// mis-nested wrapper or a padding regression, since an overflow throws during
/// paint rather than failing a targeted assertion.
///
/// Deliberately no `ProviderScope` overrides beyond preferences: this is the
/// shipped offline, accountless, ad-supported configuration.
const _pages = <String, Widget>{
  'Home': HomePage(),
  'Calculator': CalculatorPage(),
  'Saved': SavedPage(),
  'History': HistoryPage(),
  'Formula Library': FormulaLibraryPage(),
  'Settings': SettingsPage(),
  'About': AboutPage(),
  'Graph': GraphPage(),
  'Matrix': MatrixHomePage(),
  'Equation Solver': EquationSolverPage(),
  'Calculus': CalculusPage(),
  'Statistics': StatisticsPage(),
  'Financial Calculator': FinancialCalculatorPage(),
  'Linear Programming': LinearProgramPage(),
  'Integer Programming': IntegerProgramHomePage(),
  'Operations Research': OperationsResearchPage(),
  'Quiz Home': QuizHomePage(),
  'Quiz Topics': QuizTopicPage(subjectId: 'calculus'),
  'Quiz Mode': QuizModeSelectionPage(
    subjectId: 'calculus',
    topicId: 'basic-derivatives',
  ),
};

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(390, 844),
  double textScale = 1,
  bool dark = false,
  String locale = 'en',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  SharedPreferences.setMockInitialValues({'settings.language': locale});
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('every page renders on a modern phone', () {
    _pages.forEach((name, page) {
      testWidgets(name, (tester) async {
        await _pump(tester, page);
        expect(tester.takeException(), isNull, reason: '$name threw on paint');
      });
    });
  });

  group('every page survives a small screen at 1.3 text scale', () {
    // 360x640 with enlarged text is where a fixed height or an unwrapped Row
    // overflows. Both themes share layout, so one pass covers the geometry.
    _pages.forEach((name, page) {
      testWidgets(name, (tester) async {
        await _pump(tester, page, size: const Size(360, 640), textScale: 1.3);
        expect(tester.takeException(), isNull, reason: '$name overflowed');
      });
    });
  });

  group('every page renders in Turkish', () {
    // Turkish strings run noticeably longer than their English counterparts,
    // which is what pushes labels past their buttons.
    _pages.forEach((name, page) {
      testWidgets(name, (tester) async {
        await _pump(tester, page, size: const Size(360, 640), locale: 'tr');
        expect(
          tester.takeException(),
          isNull,
          reason: '$name overflowed in TR',
        );
      });
    });
  });

  group('every page renders in dark mode', () {
    _pages.forEach((name, page) {
      testWidgets(name, (tester) async {
        await _pump(tester, page, dark: true);
        expect(tester.takeException(), isNull, reason: '$name threw in dark');
      });
    });
  });

  group('every page renders at tablet width', () {
    _pages.forEach((name, page) {
      testWidgets(name, (tester) async {
        await _pump(tester, page, size: const Size(1024, 1366));
        expect(tester.takeException(), isNull, reason: '$name threw on tablet');
      });
    });
  });

  group('the ad-supported build needs no account', () {
    // No account or backend exists. Every calculation tool must still render.
    const tools = <String, Widget>{
      'Home': HomePage(),
      'Calculator': CalculatorPage(),
      'Saved': SavedPage(),
      'Formula Library': FormulaLibraryPage(),
      'Graph': GraphPage(),
      'Matrix': MatrixHomePage(),
      'Equation Solver': EquationSolverPage(),
      'Calculus': CalculusPage(),
      'Statistics': StatisticsPage(),
      'Financial Calculator': FinancialCalculatorPage(),
      'Linear Programming': LinearProgramPage(),
      'Integer Programming': IntegerProgramHomePage(),
      'Operations Research': OperationsResearchPage(),
      'Quiz': QuizHomePage(),
      'Settings': SettingsPage(),
      'About': AboutPage(),
    };
    tools.forEach((name, page) {
      testWidgets('$name works without an account', (tester) async {
        await _pump(tester, page);
        expect(tester.takeException(), isNull, reason: '$name threw');
      });
    });
  });
}

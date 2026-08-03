import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/formula_library/application/formula_favorites_controller.dart';
import 'package:calcademy/features/formula_library/presentation/formula_detail_page.dart';
import 'package:calcademy/features/formula_library/presentation/formula_library_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('library renders and search and category filters work', (
    tester,
  ) async {
    await _pump(tester, const FormulaLibraryPage());
    expect(find.text('Formula Library'), findsWidgets);
    expect(find.byKey(const Key('formula-search-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('formula-search-field')),
      'Quadratic',
    );
    await tester.pump();
    expect(find.text('Quadratic Formula'), findsOneWidget);
    expect(find.text('Arithmetic Sequence'), findsNothing);

    await tester.enterText(find.byKey(const Key('formula-search-field')), '');
    await tester.tap(find.byKey(const Key('formula-category-calculus')));
    await tester.pump();
    expect(find.text('Power Rule Derivative'), findsOneWidget);
    expect(find.text('Quadratic Formula'), findsNothing);
  });

  testWidgets('favorite toggle persists its id', (tester) async {
    await _pump(
      tester,
      const FormulaDetailPage(formulaId: 'quadratic-formula'),
    );
    await tester.tap(find.byKey(const Key('formula-detail-favorite')));
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FormulaDetailPage)),
    );
    expect(
      container.read(formulaFavoritesProvider),
      contains('quadratic-formula'),
    );
    final prefs = container.read(sharedPreferencesProvider);
    expect(
      prefs.getStringList(FormulaFavoritesController.storageKey),
      contains('quadratic-formula'),
    );
  });

  testWidgets('detail renders formula, variables, examples, and tool action', (
    tester,
  ) async {
    await _pump(
      tester,
      const FormulaDetailPage(formulaId: 'net-present-value'),
    );
    expect(find.byKey(const Key('formula-detail-expression')), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.byKey(const Key('formula-examples')), findsOneWidget);
    expect(
      find.byKey(const Key('formula-tool-financial_calculator')),
      findsOneWidget,
    );
  });

  testWidgets('invalid id shows a graceful message', (tester) async {
    await _pump(tester, const FormulaDetailPage(formulaId: 'missing'));
    expect(find.byKey(const Key('formula-not-found')), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, Widget page) async {
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
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
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

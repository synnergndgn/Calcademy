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

    await tester.tap(find.byKey(const Key('formula-detail-favorite')));
    await tester.pump();
    expect(container.read(formulaFavoritesProvider), isEmpty);
    expect(prefs.getStringList(FormulaFavoritesController.storageKey), isEmpty);
  });

  testWidgets('favorites view shows its empty state', (tester) async {
    await _pump(tester, const FormulaLibraryPage());

    await tester.tap(find.byKey(const Key('formula-view-favorites')));
    await tester.pump();

    expect(find.byKey(const Key('formula-favorites-empty')), findsOneWidget);
    expect(find.text('No favorite formulas yet.'), findsOneWidget);
  });

  testWidgets('favorites filter shows only favorite formulas', (tester) async {
    SharedPreferences.setMockInitialValues({
      FormulaFavoritesController.storageKey: ['quadratic-formula'],
    });
    await _pump(tester, const FormulaLibraryPage());

    await tester.tap(find.byKey(const Key('formula-view-favorites')));
    await tester.pump();

    expect(
      find.byKey(const Key('formula-card-quadratic-formula')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('formula-card-distance-formula')),
      findsNothing,
    );
  });

  testWidgets('search and category filters work inside favorites', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      FormulaFavoritesController.storageKey: [
        'quadratic-formula',
        'net-present-value',
      ],
    });
    await _pump(tester, const FormulaLibraryPage());
    await tester.tap(find.byKey(const Key('formula-view-favorites')));
    await tester.enterText(
      find.byKey(const Key('formula-search-field')),
      'NPV',
    );
    await tester.pump();

    expect(
      find.byKey(const Key('formula-card-net-present-value')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('formula-card-quadratic-formula')),
      findsNothing,
    );
  });

  testWidgets('formula screens preserve bottom system-safe content', (
    tester,
  ) async {
    await _pump(tester, const FormulaLibraryPage());
    expect(find.byKey(const Key('formula-library-safe-area')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('formula-search-field')),
      'Quadratic',
    );
    await tester.pump();
    expect(
      find.byKey(const Key('formula-library-bottom-spacer')),
      findsOneWidget,
    );

    await _pump(
      tester,
      const FormulaDetailPage(formulaId: 'net-present-value'),
    );
    expect(find.byKey(const Key('formula-detail-safe-area')), findsOneWidget);
    expect(
      find.byKey(const Key('formula-detail-bottom-spacer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('formula-tool-financial_calculator')),
      findsOneWidget,
    );
  });

  testWidgets('formula library stays bounded at 320px and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 690);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pump(tester, const FormulaLibraryPage());
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('formula-library-safe-area')), findsOneWidget);
  });

  test('favorite state is restored by a new provider container', () async {
    final preferences = await SharedPreferences.getInstance();
    final first = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    await first
        .read(formulaFavoritesProvider.notifier)
        .toggle('quadratic-formula');
    first.dispose();

    final reopened = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(reopened.dispose);
    expect(
      reopened.read(formulaFavoritesProvider),
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

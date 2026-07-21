import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/features/saved_calculations/data/saved_calculations_repository.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/presentation/saved_calculations_controller.dart';
import 'package:calcademy/features/saved_calculations/presentation/saved_calculations_page.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  _MemoryRepository repository, {
  ThemeData? theme,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        savedCalculationsRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SavedCalculationsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void _setViewport(WidgetTester tester, Size size, {double scale = 1}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  testWidgets('shows the saved-calculations empty state', (tester) async {
    await _pump(tester, _MemoryRepository());

    expect(find.text('No saved calculations'), findsOneWidget);
    expect(find.byKey(const Key('saved-search')), findsOneWidget);
    expect(find.byKey(const Key('saved-clear-all')), findsOneWidget);
  });

  testWidgets('search, favorites, module filter, and sort update the list', (
    tester,
  ) async {
    final repository = _MemoryRepository(items: _items);
    await _pump(tester, repository);

    await tester.enterText(find.byKey(const Key('saved-search')), 'mean');
    await tester.pumpAndSettle();
    expect(find.text('Statistics item'), findsOneWidget);
    expect(find.text('Financial item'), findsNothing);

    await tester.enterText(find.byKey(const Key('saved-search')), '');
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Financial item'), findsOneWidget);
    expect(find.text('Statistics item'), findsNothing);

    await tester.tap(find.text('All'));
    await tester.tap(find.byKey(const Key('saved-module-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calculus').last);
    await tester.pumpAndSettle();
    expect(find.text('Calculus item'), findsOneWidget);
    expect(find.text('Financial item'), findsNothing);

    await tester.tap(find.byKey(const Key('saved-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oldest first').last);
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SavedCalculationsPage)),
    );
    expect(
      container.read(savedCalculationsProvider).sort,
      SavedCalculationsSort.oldestFirst,
    );
  });

  testWidgets('favorite and copy actions work on a saved card', (tester) async {
    final repository = _MemoryRepository(items: [_items.last]);
    await _pump(tester, repository);
    await _scrollTo(
      tester,
      find.byKey(const ValueKey('saved-favorite-calculus')),
    );

    expect(find.byKey(const ValueKey('saved-copy-calculus')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('saved-favorite-calculus')));
    await tester.pumpAndSettle();
    expect(repository.items.single.isFavorite, isTrue);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('lists and filters a Graph Plotter record', (tester) async {
    final graph = _item(
      'graph',
      'Parabola graph',
      SavedCalculationModule.graphPlotter,
      DateTime.utc(2026, 4, 1),
      result: 'x^2 · x:[-10, 10]',
    );
    await _pump(tester, _MemoryRepository(items: [graph]));

    expect(find.text('Parabola graph'), findsOneWidget);
    expect(find.text('Graphing'), findsWidgets);
    await tester.tap(find.byKey(const Key('saved-module-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Graphing').last);
    await tester.pumpAndSettle();
    expect(find.text('Parabola graph'), findsOneWidget);
  });

  testWidgets('lists and filters an Operations Research record', (
    tester,
  ) async {
    final transportation = _item(
      'or-transportation',
      'Transportation Solution',
      SavedCalculationModule.operationsResearch,
      DateTime.utc(2026, 4, 2),
      result: 'Total cost: 150',
    );
    await _pump(tester, _MemoryRepository(items: [transportation]));

    expect(find.text('Transportation Solution'), findsOneWidget);
    expect(find.text('Operations Research'), findsWidgets);
    await tester.tap(find.byKey(const Key('saved-module-filter')));
    await tester.pumpAndSettle();
    final option = find.text('Operations Research').last;
    await tester.ensureVisible(option);
    await tester.pumpAndSettle();
    await tester.tap(option.hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Transportation Solution'), findsOneWidget);
  });

  testWidgets('delete and clear-all require confirmation', (tester) async {
    final repository = _MemoryRepository(items: _items);
    await _pump(tester, repository);
    await _scrollTo(tester, find.byKey(const ValueKey('saved-delete-fin')));
    await tester.tap(find.byKey(const ValueKey('saved-delete-fin')));
    await tester.pumpAndSettle();
    expect(find.text('Delete saved calculation?'), findsOneWidget);
    expect(find.byKey(const Key('saved-confirm-delete')), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.items.length, 3);

    await tester.tap(find.byKey(const Key('saved-clear-all')));
    await tester.pumpAndSettle();
    expect(find.text('Clear all saved calculations?'), findsOneWidget);
    expect(find.byKey(const Key('saved-confirm-clear')), findsOneWidget);
  });

  testWidgets('is overflow-free at 320px and 200 percent text scale', (
    tester,
  ) async {
    _setViewport(tester, const Size(320, 690), scale: 2);
    await _pump(
      tester,
      _MemoryRepository(items: [_items.first]),
      locale: const Locale('tr'),
    );
    expect(tester.takeException(), isNull);
    final list = tester.widget<ListView>(
      find.byKey(const Key('saved-calculations-list')),
    );
    expect((list.padding! as EdgeInsets).bottom, greaterThan(16));
    await tester.fling(
      find.byKey(const Key('saved-calculations-list')),
      const Offset(0, -1400),
      1000,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('builds in dark mode', (tester) async {
    await _pump(
      tester,
      _MemoryRepository(items: [_items.first]),
      theme: AppTheme.dark(),
    );
    expect(tester.takeException(), isNull);
    expect(
      Theme.of(tester.element(find.byType(SavedCalculationsPage))).brightness,
      Brightness.dark,
    );
  });
}

final _items = [
  _item(
    'fin',
    'Financial item',
    SavedCalculationModule.financialCalculator,
    DateTime.utc(2026, 3, 1),
    favorite: true,
    result: 'NPV: 41.32',
  ),
  _item(
    'stats',
    'Statistics item',
    SavedCalculationModule.statistics,
    DateTime.utc(2026, 1, 1),
    result: 'Mean: 2',
  ),
  _item(
    'calculus',
    'Calculus item',
    SavedCalculationModule.calculus,
    DateTime.utc(2026, 2, 1),
    result: 'Derivative: 0.54',
  ),
];

SavedCalculation _item(
  String id,
  String title,
  SavedCalculationModule module,
  DateTime createdAt, {
  bool favorite = false,
  required String result,
}) => SavedCalculation(
  id: id,
  title: title,
  module: module,
  calculationType: id,
  createdAt: createdAt,
  updatedAt: createdAt,
  isFavorite: favorite,
  inputSummary: 'input for $title',
  resultSummary: result,
  fullInputJson: const {},
  resultJson: const {},
  tags: const [],
);

class _MemoryRepository implements SavedCalculationsRepository {
  _MemoryRepository({List<SavedCalculation>? items}) : items = [...?items];
  final List<SavedCalculation> items;

  @override
  SavedCalculationsLoadResult load() => SavedCalculationsLoadResult(
    items: List.unmodifiable(items),
    skippedItemCount: 0,
  );

  @override
  Future<void> add(SavedCalculation item) async => items.insert(0, item);

  @override
  Future<void> clear() async => items.clear();

  @override
  Future<void> delete(String id) async =>
      items.removeWhere((item) => item.id == id);

  @override
  Future<void> setFavorite(
    String id,
    bool isFavorite,
    DateTime updatedAt,
  ) async {
    final index = items.indexWhere((item) => item.id == id);
    items[index] = items[index].copyWith(
      isFavorite: isFavorite,
      updatedAt: updatedAt,
    );
  }
}

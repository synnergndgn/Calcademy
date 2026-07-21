import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/operations_research/presentation/operations_research_page.dart';
import 'package:calcademy/features/saved_calculations/data/saved_calculations_repository.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('switches modes and renders both responsive input grids', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byKey(const Key('or-transport-grid-scroll')), findsOneWidget);
    expect(find.byKey(const Key('or-transport-cost-0-0')), findsOneWidget);
    await _tapVisible(tester, find.byKey(const Key('or-mode-assignment')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('or-assignment-grid-scroll')), findsOneWidget);
    expect(find.byKey(const Key('or-assignment-value-0-0')), findsOneWidget);
  });

  testWidgets('solves transportation and saves a compact OR record', (
    tester,
  ) async {
    final repository = _RecordingRepository();
    await _pump(tester, repository: repository);
    await _enter(tester, 'or-transport-cost-0-0', '1');
    await _enter(tester, 'or-transport-cost-0-1', '4');
    await _enter(tester, 'or-transport-cost-1-0', '3');
    await _enter(tester, 'or-transport-cost-1-1', '1');
    final solve = find.byKey(const Key('or-transport-solve'));
    await _tapVisible(tester, solve);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('or-result-card')), findsOneWidget);
    expect(find.text('Optimal solution'), findsOneWidget);
    expect(find.text('Total cost: 2'), findsOneWidget);
    expect(find.byKey(const Key('or-allocation-scroll')), findsOneWidget);
    expect(find.byKey(const Key('or-copy-result')), findsOneWidget);
    expect(find.byKey(const Key('or-save-result')), findsOneWidget);

    await _tapVisible(tester, find.byKey(const Key('or-save-result')));
    await tester.pumpAndSettle();
    expect(repository.items, hasLength(1));
    expect(
      repository.items.single.module,
      SavedCalculationModule.operationsResearch,
    );
    expect(repository.items.single.calculationType, 'transportation');
    expect(find.text('Calculation saved on this device.'), findsOneWidget);
  });

  testWidgets('solves assignment and shows Hungarian assignments', (
    tester,
  ) async {
    await _pump(tester);
    await _tapVisible(tester, find.byKey(const Key('or-mode-assignment')));
    await tester.pumpAndSettle();
    await _enter(tester, 'or-assignment-value-0-0', '5');
    await _enter(tester, 'or-assignment-value-0-1', '1');
    await _enter(tester, 'or-assignment-value-1-0', '2');
    await _enter(tester, 'or-assignment-value-1-1', '4');
    final solve = find.byKey(const Key('or-assignment-solve'));
    await _tapVisible(tester, solve);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('or-result-card')), findsOneWidget);
    expect(find.text('Total cost: 3'), findsOneWidget);
    expect(find.text('W1 → J2'), findsOneWidget);
    expect(find.text('W2 → J1'), findsOneWidget);
    expect(find.textContaining('Hungarian algorithm'), findsOneWidget);
    expect(find.byKey(const Key('or-save-result')), findsOneWidget);
  });

  testWidgets('shows a friendly validation result for an empty cell', (
    tester,
  ) async {
    await _pump(tester);
    await _enter(tester, 'or-transport-cost-0-0', '');
    final solve = find.byKey(const Key('or-transport-solve'));
    await _tapVisible(tester, solve);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('or-result-error')), findsOneWidget);
    expect(
      find.text('Enter a valid finite number in every field.'),
      findsOneWidget,
    );
  });

  testWidgets('is usable at 320px and keeps wide tables scrollable', (
    tester,
  ) async {
    _setViewport(tester, const Size(320, 690));
    await _pump(tester, locale: const Locale('tr'));
    await _tapVisible(
      tester,
      find.byKey(const Key('or-transport-add-destination')),
    );
    await tester.pumpAndSettle();

    final grid = find.byKey(const Key('or-transport-grid-scroll'));
    expect(grid, findsOneWidget);
    expect(tester.getSize(grid).width, lessThanOrEqualTo(288));
    expect(find.byKey(const Key('or-transport-cost-0-2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('builds at 200 percent text scale and in dark mode', (
    tester,
  ) async {
    _setViewport(tester, const Size(360, 760), scale: 2);
    await _pump(tester, theme: AppTheme.dark());
    await _tapVisible(tester, find.byKey(const Key('or-mode-assignment')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('or-assignment-grid-scroll')), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(OperationsResearchPage))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ThemeData? theme,
  Locale locale = const Locale('en'),
  _RecordingRepository? repository,
}) async {
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        if (repository != null)
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
        home: const OperationsResearchPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String value) async {
  await tester.enterText(find.byKey(Key(key)), value);
  await tester.pump();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder.hitTestable());
  await tester.pump();
}

void _setViewport(WidgetTester tester, Size size, {double scale = 1}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

class _RecordingRepository implements SavedCalculationsRepository {
  final items = <SavedCalculation>[];

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
  ) async {}
}

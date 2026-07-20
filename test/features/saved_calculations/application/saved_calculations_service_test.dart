import 'package:calcademy/features/saved_calculations/application/saved_calculations_service.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = SavedCalculationsService();
  final old = _item(
    'old',
    'İstatistik Özeti',
    'Mean: 2',
    DateTime.utc(2026, 1, 1),
    SavedCalculationModule.statistics,
  );
  final favorite = _item(
    'favorite',
    'NPV Calculation',
    'NPV: 41.32',
    DateTime.utc(2026, 2, 1),
    SavedCalculationModule.financialCalculator,
    favorite: true,
  );
  final newest = _item(
    'newest',
    'Derivative',
    'Result: 0.54',
    DateTime.utc(2026, 3, 1),
    SavedCalculationModule.calculus,
  );
  late List<SavedCalculation> items;

  setUp(() => items = [old, favorite, newest]);

  test('searches title and result summary case-insensitively', () {
    expect(_apply(service, items, query: 'istatistik').single.id, 'old');
    expect(_apply(service, items, query: 'npv: 41').single.id, 'favorite');
    expect(
      _apply(service, items, query: 'finansal hesap makinesi').single.id,
      'favorite',
    );
  });

  test('filters favorites and module', () {
    expect(
      _apply(service, items, scope: SavedCalculationsScope.favorites).single.id,
      'favorite',
    );
    expect(
      _apply(service, items, module: SavedCalculationModule.calculus).single.id,
      'newest',
    );
  });

  test('sorts newest, oldest, and favorites first', () {
    expect(_apply(service, items).map((item) => item.id), [
      'newest',
      'favorite',
      'old',
    ]);
    expect(
      _apply(
        service,
        items,
        sort: SavedCalculationsSort.oldestFirst,
      ).map((item) => item.id),
      ['old', 'favorite', 'newest'],
    );
    expect(
      _apply(
        service,
        items,
        sort: SavedCalculationsSort.favoritesFirst,
      ).first.id,
      'favorite',
    );
  });
}

List<SavedCalculation> _apply(
  SavedCalculationsService service,
  List<SavedCalculation> items, {
  String query = '',
  SavedCalculationsScope scope = SavedCalculationsScope.all,
  SavedCalculationModule? module,
  SavedCalculationsSort sort = SavedCalculationsSort.newestFirst,
}) => service.apply(
  items: items,
  query: query,
  scope: scope,
  module: module,
  sort: sort,
);

SavedCalculation _item(
  String id,
  String title,
  String result,
  DateTime createdAt,
  SavedCalculationModule module, {
  bool favorite = false,
}) => SavedCalculation(
  id: id,
  title: title,
  module: module,
  calculationType: id,
  createdAt: createdAt,
  updatedAt: createdAt,
  isFavorite: favorite,
  inputSummary: 'input',
  resultSummary: result,
  fullInputJson: const {},
  resultJson: const {},
  tags: const [],
);

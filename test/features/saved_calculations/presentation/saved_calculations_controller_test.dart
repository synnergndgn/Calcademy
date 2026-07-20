import 'package:calcademy/features/saved_calculations/data/saved_calculations_repository.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_failure.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_limits.dart';
import 'package:calcademy/features/saved_calculations/presentation/saved_calculations_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('controller saves, toggles favorite, deletes, and clears', () async {
    final repository = MemorySavedCalculationsRepository();
    final container = ProviderContainer(
      overrides: [
        savedCalculationsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(savedCalculationsProvider.notifier);

    final saved = await controller.save(_draft);
    expect(container.read(savedCalculationsProvider).items.single.id, saved.id);
    expect(repository.items.single.id, saved.id);

    await controller.toggleFavorite(saved.id);
    expect(
      container.read(savedCalculationsProvider).items.single.isFavorite,
      isTrue,
    );
    await controller.delete(saved.id);
    expect(container.read(savedCalculationsProvider).items, isEmpty);

    await controller.save(_draft);
    await controller.clear();
    expect(repository.items, isEmpty);
  });

  test('controller rejects saves at the central item limit', () async {
    final repository = MemorySavedCalculationsRepository(
      items: List.generate(
        SavedCalculationsLimits.maxSavedItemCount,
        (index) => _item('$index'),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        savedCalculationsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(savedCalculationsProvider.notifier).save(_draft),
      throwsA(
        isA<SavedCalculationsException>().having(
          (error) => error.issue,
          'issue',
          SavedCalculationsIssue.itemLimit,
        ),
      ),
    );
  });
}

const _draft = SavedCalculationDraft(
  title: 'NPV Calculation',
  module: SavedCalculationModule.financialCalculator,
  calculationType: 'npv',
  inputSummary: 'rate=10',
  resultSummary: 'NPV: 41.32',
);

SavedCalculation _item(String id) => SavedCalculation(
  id: id,
  title: 'Item $id',
  module: SavedCalculationModule.statistics,
  calculationType: 'descriptive',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  isFavorite: false,
  inputSummary: 'input',
  resultSummary: 'result',
  fullInputJson: const {},
  resultJson: const {},
  tags: const [],
);

class MemorySavedCalculationsRepository implements SavedCalculationsRepository {
  MemorySavedCalculationsRepository({List<SavedCalculation>? items})
    : items = [...?items];

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

import 'dart:math';

import 'package:calcademy/features/saved_calculations/application/saved_calculations_service.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_limits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 7, 20, 12, 30);
  final item = SavedCalculation(
    id: 'saved-1',
    title: 'NPV Calculation',
    module: SavedCalculationModule.financialCalculator,
    calculationType: 'npv',
    createdAt: createdAt,
    updatedAt: createdAt,
    isFavorite: false,
    inputSummary: 'rate=10',
    resultSummary: 'NPV: 41.32',
    fullInputJson: const {'rate': 10},
    resultJson: const {'value': 41.32},
    tags: const ['finance'],
  );

  test('serializes and deserializes versioned ISO-8601 data', () {
    final json = item.toJson();
    final restored = SavedCalculation.fromJson(json);

    expect(json['schemaVersion'], SavedCalculationsLimits.schemaVersion);
    expect(json['createdAt'], createdAt.toIso8601String());
    expect(restored.id, item.id);
    expect(restored.module, SavedCalculationModule.financialCalculator);
    expect(restored.fullInputJson['rate'], 10);
    expect(restored.tags, ['finance']);
  });

  test('rejects an unsupported item schema without crashing', () {
    final json = item.toJson()..['schemaVersion'] = 99;
    expect(
      () => SavedCalculation.fromJson(json),
      throwsA(isA<FormatException>()),
    );
  });

  test('maps known and unknown module ids safely', () {
    expect(
      SavedCalculationModule.fromId('statistics'),
      SavedCalculationModule.statistics,
    );
    expect(
      SavedCalculationModule.fromId('future-module'),
      SavedCalculationModule.unknown,
    );
  });

  test('summary truncation is bounded and favorite copy is immutable', () {
    final service = SavedCalculationsService(random: Random(1));
    final long = 'x' * (SavedCalculationsLimits.maxSummaryLength + 20);
    final truncated = service.truncateSummary(long);
    final favorite = item.copyWith(isFavorite: true);

    expect(truncated.length, SavedCalculationsLimits.maxSummaryLength);
    expect(truncated, endsWith('…'));
    expect(favorite.isFavorite, isTrue);
    expect(item.isFavorite, isFalse);
  });
}

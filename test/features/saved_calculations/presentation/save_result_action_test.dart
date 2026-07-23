import 'package:calcademy/app/theme/app_theme.dart';
import 'package:calcademy/features/calculus/domain/calculus_result.dart';
import 'package:calcademy/features/calculus/presentation/calculus_result_card.dart';
import 'package:calcademy/features/financial_calculator/domain/financial_result.dart';
import 'package:calcademy/features/financial_calculator/presentation/financial_result_card.dart';
import 'package:calcademy/features/saved_calculations/data/saved_calculations_repository.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/statistics/domain/statistics_result.dart';
import 'package:calcademy/features/statistics/presentation/statistics_result_card.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'priority result cards expose save actions and persist a result',
    (tester) async {
      final repository = _RecordingRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedCalculationsRepositoryProvider.overrideWithValue(repository),
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
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    FinancialResultCard(result: _financialResult),
                    StatisticsResultCard(result: _statisticsResult),
                    CalculusResultCard(
                      result: _calculusResult,
                      functionExpression: 'sin(x)',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fin-save-result')), findsOneWidget);
      expect(find.byKey(const Key('stats-save-result')), findsOneWidget);
      expect(find.byKey(const Key('calc-save-result')), findsOneWidget);

      await tester.tap(find.byKey(const Key('fin-save-result')));
      await tester.pumpAndSettle();
      expect(repository.items, hasLength(1));
      expect(repository.items.single.calculationType, 'tvm');
      expect(find.text('Saved to Saved Calculations.'), findsOneWidget);

      final statisticsSave = find.byKey(const Key('stats-save-result'));
      await tester.ensureVisible(statisticsSave);
      await tester.pumpAndSettle();
      await tester.tap(statisticsSave);
      await tester.pumpAndSettle();
      expect(repository.items, hasLength(2));
      expect(repository.items.first.calculationType, 'descriptive');
      expect(repository.items.first.inputSummary, '1, 2, 3, 4, 5');
    },
  );
}

const _financialResult = TvmResult(
  operation: TvmOperation.presentValue,
  value: 620.92132306,
  ratePercent: 10,
  periods: 5,
  methodKey: 'finMethodPresentValue',
  inputs: {'futureValue': 1000, 'rate': 10},
);

const _statisticsResult = DescriptiveStatisticsResult(
  values: [1, 2, 3, 4, 5],
  count: 5,
  sum: 15,
  mean: 3,
  median: 3,
  modes: [],
  minimum: 1,
  maximum: 5,
  range: 4,
  populationVariance: 2,
  sampleVariance: 2.5,
  populationStandardDeviation: 1.41421356,
  sampleStandardDeviation: 1.58113883,
  q1: 1.5,
  q3: 4.5,
  iqr: 3,
  outliers: [],
  warnings: [],
);

final _calculusResult = DifferentiationSuccess(
  value: 0.540302,
  method: DifferentiationMethod.central,
  point: 1,
  stepSize: 0.001,
  errorEstimate: 1e-8,
);

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

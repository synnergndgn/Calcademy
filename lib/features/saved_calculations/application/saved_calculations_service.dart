import 'dart:convert';
import 'dart:math';

import 'package:calcademy/features/saved_calculations/domain/saved_calculation.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculation_module.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_failure.dart';
import 'package:calcademy/features/saved_calculations/domain/saved_calculations_limits.dart';

class SavedCalculationsService {
  SavedCalculationsService({Random? random})
    : _random = random ?? Random.secure();

  final Random _random;

  SavedCalculation create(
    SavedCalculationDraft draft, {
    DateTime? now,
    String? id,
  }) {
    if (draft.module == SavedCalculationModule.unknown) {
      throw const SavedCalculationsException(
        SavedCalculationsIssue.unknownModule,
      );
    }
    if (draft.calculationType.trim().isEmpty ||
        draft.inputSummary.trim().isEmpty ||
        draft.resultSummary.trim().isEmpty) {
      throw const SavedCalculationsException(
        SavedCalculationsIssue.invalidPayload,
      );
    }
    final timestamp = (now ?? DateTime.now()).toUtc();
    final title = draft.title.trim().isEmpty
        ? _fallbackTitle(draft)
        : draft.title.trim();
    _validateLength(
      title,
      SavedCalculationsLimits.maxTitleLength,
      SavedCalculationsIssue.titleTooLong,
    );
    final inputSummary = truncateSummary(draft.inputSummary);
    final resultSummary = truncateSummary(draft.resultSummary);
    final int payloadBytes;
    try {
      payloadBytes = utf8
          .encode(
            jsonEncode({
              'input': draft.fullInputJson,
              'result': draft.resultJson,
            }),
          )
          .length;
    } on Object catch (error) {
      throw SavedCalculationsException(
        SavedCalculationsIssue.invalidPayload,
        error,
      );
    }
    if (payloadBytes > SavedCalculationsLimits.maxStoredPayloadBytes) {
      throw const SavedCalculationsException(
        SavedCalculationsIssue.payloadTooLarge,
      );
    }
    return SavedCalculation(
      id: id ?? _newId(timestamp),
      title: title,
      module: draft.module,
      calculationType: draft.calculationType,
      createdAt: timestamp,
      updatedAt: timestamp,
      isFavorite: false,
      inputSummary: inputSummary,
      resultSummary: resultSummary,
      fullInputJson: draft.fullInputJson,
      resultJson: draft.resultJson,
      tags: List.unmodifiable(draft.tags),
    );
  }

  List<SavedCalculation> apply({
    required List<SavedCalculation> items,
    required String query,
    required SavedCalculationsScope scope,
    required SavedCalculationModule? module,
    required SavedCalculationsSort sort,
  }) {
    if (query.length > SavedCalculationsLimits.maxSearchQueryLength) {
      throw const SavedCalculationsException(
        SavedCalculationsIssue.searchQueryTooLong,
      );
    }
    final needle = _normalize(query.trim());
    final filtered = items.where((item) {
      if (scope == SavedCalculationsScope.favorites && !item.isFavorite) {
        return false;
      }
      if (module != null && item.module != module) return false;
      if (needle.isEmpty) return true;
      return [
        item.title,
        item.module.id,
        item.moduleName,
        _moduleSearchTerms(item.module),
        item.calculationType,
        item.inputSummary,
        item.resultSummary,
      ].any((value) => _normalize(value).contains(needle));
    }).toList();
    filtered.sort(
      (a, b) => switch (sort) {
        SavedCalculationsSort.newestFirst => b.createdAt.compareTo(a.createdAt),
        SavedCalculationsSort.oldestFirst => a.createdAt.compareTo(b.createdAt),
        SavedCalculationsSort.favoritesFirst => _favoriteOrder(a, b),
      },
    );
    return filtered;
  }

  String truncateSummary(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= SavedCalculationsLimits.maxSummaryLength) {
      return trimmed;
    }
    return '${trimmed.substring(0, SavedCalculationsLimits.maxSummaryLength - 1)}…';
  }

  String _newId(DateTime now) {
    final randomPart = List.generate(
      12,
      (_) => _random.nextInt(16).toRadixString(16),
    ).join();
    return 'saved-${now.microsecondsSinceEpoch}-$randomPart';
  }

  static String _fallbackTitle(SavedCalculationDraft draft) =>
      '${draft.calculationType} Calculation';

  static void _validateLength(
    String value,
    int max,
    SavedCalculationsIssue issue,
  ) {
    if (value.trim().length > max) {
      throw SavedCalculationsException(issue);
    }
  }

  static String _normalize(String value) => value
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .toLowerCase()
      .replaceAll('\u0307', '');

  static String _moduleSearchTerms(SavedCalculationModule module) =>
      switch (module) {
        SavedCalculationModule.scientificCalculator =>
          'Scientific Calculator Bilimsel Hesap Makinesi',
        SavedCalculationModule.graphPlotter =>
          'Graph Plotter Graphing Grafik Cizici Grafik Çizici',
        SavedCalculationModule.financialCalculator =>
          'Financial Calculator Finansal Hesap Makinesi',
        SavedCalculationModule.statistics => 'Statistics İstatistik',
        SavedCalculationModule.calculus => 'Calculus Kalkülüs',
        SavedCalculationModule.equationSolver =>
          'Equation Solver Denklem Çözücü',
        SavedCalculationModule.matrix =>
          'Matrices Linear Algebra Matrisler Lineer Cebir',
        SavedCalculationModule.linearProgramming =>
          'Linear Programming Lineer Programlama',
        SavedCalculationModule.integerProgramming =>
          'Integer Programming Tam Sayılı Programlama',
        SavedCalculationModule.unknown => 'Unknown Bilinmeyen',
      };

  static int _favoriteOrder(SavedCalculation a, SavedCalculation b) {
    final favorite = (b.isFavorite ? 1 : 0).compareTo(a.isFavorite ? 1 : 0);
    return favorite != 0 ? favorite : b.createdAt.compareTo(a.createdAt);
  }
}

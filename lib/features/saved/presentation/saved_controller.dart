import 'package:calcademy/features/history/data/local_calculation_repository.dart';
import 'package:calcademy/features/history/domain/calculation_record.dart';
import 'package:calcademy/features/history/domain/saved_calculation.dart';
import 'package:calcademy/features/history/presentation/history_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final savedProvider = NotifierProvider<SavedController, List<SavedCalculation>>(
  SavedController.new,
);

class SavedController extends Notifier<List<SavedCalculation>> {
  @override
  List<SavedCalculation> build() =>
      ref.watch(calculationRepositoryProvider).loadSaved();

  Future<void> addFromRecord(
    CalculationRecord record, {
    String? title,
    String? note,
  }) async {
    if (state.any((item) => item.id == record.id)) return;
    final fallback = record.expression.length > 28
        ? '${record.expression.substring(0, 28)}…'
        : record.expression;
    state = [
      SavedCalculation(
        id: record.id,
        title: title?.trim().isNotEmpty == true ? title!.trim() : fallback,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        expression: record.expression,
        result: record.result,
        createdAt: record.createdAt,
      ),
      ...state,
    ];
    await ref.read(historyProvider.notifier).setSaved(record.id, true);
    await _persist();
  }

  Future<void> update(String id, String title, String note) async {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(title: title.trim(), note: note.trim())
        else
          item,
    ];
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((item) => item.id != id).toList();
    await ref.read(historyProvider.notifier).setSaved(id, false);
    await _persist();
  }

  Future<void> clear() async {
    final ids = state.map((item) => item.id).toSet();
    state = [];
    for (final id in ids) {
      await ref.read(historyProvider.notifier).setSaved(id, false);
    }
    await _persist();
  }

  Future<void> _persist() =>
      ref.read(calculationRepositoryProvider).saveSaved(state);
}

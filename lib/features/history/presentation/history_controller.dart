import 'package:calcademy/features/history/data/local_calculation_repository.dart';
import 'package:calcademy/features/history/domain/calculation_record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final historyProvider =
    NotifierProvider<HistoryController, List<CalculationRecord>>(
      HistoryController.new,
    );

class HistoryController extends Notifier<List<CalculationRecord>> {
  @override
  List<CalculationRecord> build() =>
      ref.watch(calculationRepositoryProvider).loadHistory();

  Future<void> add(CalculationRecord record) async {
    state = [record, ...state].take(200).toList();
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _persist();
  }

  Future<void> setSaved(String id, bool saved) async {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isSaved: saved) else item,
    ];
    await _persist();
  }

  Future<void> clear() async {
    state = [];
    await _persist();
  }

  Future<void> _persist() =>
      ref.read(calculationRepositoryProvider).saveHistory(state);
}

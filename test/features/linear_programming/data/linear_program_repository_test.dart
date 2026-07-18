import 'package:calcademy/features/linear_programming/data/linear_program_repository.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program_result.dart';
import 'package:calcademy/features/linear_programming/domain/lp_examples.dart';
import 'package:calcademy/features/linear_programming/domain/saved_linear_program.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'repository persists and restores model separately from summary',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = LinearProgramRepository(preferences);
      final date = DateTime(2026, 7, 17);
      final saved = SavedLinearProgram(
        id: 'lp-1',
        title: 'Product mix',
        program: LpExamples.productMix,
        status: LinearProgramStatus.optimal,
        objectiveValue: 10,
        createdAt: date,
        updatedAt: date,
      );

      await repository.save([saved]);
      final restored = repository.load().single;
      expect(preferences.containsKey(LinearProgramRepository.savedKey), isTrue);
      expect(restored.program.objective, [3, 2]);
      expect(restored.status, LinearProgramStatus.optimal);
      expect(restored.objectiveValue, 10);
    },
  );

  test('repository returns empty list for corrupt JSON', () async {
    SharedPreferences.setMockInitialValues({
      LinearProgramRepository.savedKey: '{bad',
    });
    final repository = LinearProgramRepository(
      await SharedPreferences.getInstance(),
    );
    expect(repository.load(), isEmpty);
  });
}

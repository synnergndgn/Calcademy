import 'package:calcademy/features/integer_programming/data/integer_program_repository.dart';
import 'package:calcademy/features/integer_programming/domain/branch_and_bound_solver.dart';
import 'package:calcademy/features/integer_programming/domain/integer_program_examples.dart';
import 'package:calcademy/features/integer_programming/domain/saved_integer_program.dart';
import 'package:calcademy/features/linear_programming/data/linear_program_repository.dart';
import 'package:calcademy/features/linear_programming/domain/linear_program_result.dart';
import 'package:calcademy/features/linear_programming/domain/lp_examples.dart';
import 'package:calcademy/features/linear_programming/domain/saved_linear_program.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('repository persists and restores model and result summary', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = IntegerProgramRepository(preferences);
    final date = DateTime(2026, 7, 17);
    final result = const BranchAndBoundSolver().solve(
      IntegerProgramExamples.knapsack,
    );
    final saved = SavedIntegerProgram(
      id: 'ip-1',
      title: 'Knapsack',
      program: IntegerProgramExamples.knapsack,
      result: MipResultSummary.fromResult(result),
      createdAt: date,
      updatedAt: date,
    );

    await repository.save([saved]);
    expect(preferences.containsKey(IntegerProgramRepository.savedKey), isTrue);
    final restored = repository.load().single;
    expect(restored.program.linearModel.objective, [10, 7, 12, 8]);
    expect(restored.result!.statusKey, 'mipStatusOptimal');
    expect(restored.result!.objectiveValue, closeTo(22, 1e-9));
    expect(restored.result!.variableValues['x1'], closeTo(1, 1e-9));
  });

  test(
    'a saved program without a result round-trips with a null summary',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = IntegerProgramRepository(
        await SharedPreferences.getInstance(),
      );
      final date = DateTime(2026, 7, 17);
      await repository.save([
        SavedIntegerProgram(
          id: 'ip-2',
          title: 'Unsolved',
          program: IntegerProgramExamples.fractionalRelaxation,
          result: null,
          createdAt: date,
          updatedAt: date,
        ),
      ]);
      expect(repository.load().single.result, isNull);
    },
  );

  test('repository returns empty list for corrupt JSON', () async {
    SharedPreferences.setMockInitialValues({
      IntegerProgramRepository.savedKey: '{bad',
    });
    final repository = IntegerProgramRepository(
      await SharedPreferences.getInstance(),
    );
    expect(repository.load(), isEmpty);
  });

  group('repository upsert behaviour', () {
    test(
      'saving a renamed copy with the same id replaces it on reload',
      () async {
        SharedPreferences.setMockInitialValues({});
        final repository = IntegerProgramRepository(
          await SharedPreferences.getInstance(),
        );
        final date = DateTime(2026, 7, 17);
        final first = SavedIntegerProgram(
          id: 'ip-1',
          title: 'First',
          program: IntegerProgramExamples.fractionalRelaxation,
          result: null,
          createdAt: date,
          updatedAt: date,
        );
        await repository.save([first]);
        var loaded = repository.load();
        expect(loaded, hasLength(1));
        expect(loaded.single.title, 'First');

        final updated = first.copyWith(title: 'Renamed');
        await repository.save([updated]);
        loaded = repository.load();
        expect(loaded, hasLength(1));
        expect(loaded.single.title, 'Renamed');
        expect(loaded.single.id, first.id);
      },
    );

    test(
      'save-as-copy produces a distinct id while keeping the same model',
      () {
        final date = DateTime(2026, 7, 17);
        final original = SavedIntegerProgram(
          id: 'ip-1',
          title: 'Original',
          program: IntegerProgramExamples.knapsack,
          result: null,
          createdAt: date,
          updatedAt: date,
        );
        final copy = original.copyWith(id: 'ip-2', title: 'Original (copy)');
        expect(copy.id, isNot(original.id));
        expect(
          copy.program.linearModel.objective,
          original.program.linearModel.objective,
        );
      },
    );
  });

  test(
    'saving integer programs does not disturb existing linear program saves',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final lpRepository = LinearProgramRepository(preferences);
      final ipRepository = IntegerProgramRepository(preferences);
      final date = DateTime(2026, 7, 17);

      await lpRepository.save([
        SavedLinearProgram(
          id: 'lp-1',
          title: 'Product mix',
          program: LpExamples.productMix,
          status: LinearProgramStatus.optimal,
          objectiveValue: 10,
          createdAt: date,
          updatedAt: date,
        ),
      ]);
      await ipRepository.save([
        SavedIntegerProgram(
          id: 'ip-1',
          title: 'Knapsack',
          program: IntegerProgramExamples.knapsack,
          result: null,
          createdAt: date,
          updatedAt: date,
        ),
      ]);

      expect(lpRepository.load(), hasLength(1));
      expect(ipRepository.load(), hasLength(1));
      expect(lpRepository.load().single.program.title, 'Product mix');
      expect(ipRepository.load().single.program.title, '0-1 Knapsack');
    },
  );
}

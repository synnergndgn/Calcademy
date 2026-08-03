import 'package:calcademy/features/ai_assistant/application/ai_problem_classifier.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_problem_intent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const classifier = AiProblemClassifier();

  const cases = {
    'matris determinant': AiProblemIntent.matrix,
    'npv hesapla': AiProblemIntent.finance,
    'türev al': AiProblemIntent.calculus,
    'standart sapma': AiProblemIntent.statistics,
    'linear programming': AiProblemIntent.linearProgramming,
    'transportation problem': AiProblemIntent.operationsResearch,
    'hava durumu': AiProblemIntent.outOfScope,
    'yatırım öner': AiProblemIntent.outOfScope,
  };

  for (final entry in cases.entries) {
    test('classifies "${entry.key}"', () {
      expect(classifier.classify(entry.key), entry.value);
    });
  }

  test('unknown chat is unsupported rather than general chat', () {
    expect(
      classifier.classify('selam, nasılsın?'),
      AiProblemIntent.unsupported,
    );
  });
}

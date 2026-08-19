import 'package:calcademy/features/quiz/data/quiz_question_repository.dart';
import 'package:calcademy/features/quiz/domain/quiz_answer_validator.dart';
import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/domain/quiz_subject.dart';
import 'package:calcademy/features/quiz/domain/quiz_topic.dart';
import 'package:flutter_test/flutter_test.dart';

QuizQuestion _question(String id) =>
    QuizQuestionBank.all.firstWhere((question) => question.id == id);

void main() {
  group('the constant of integration', () {
    test('a complete answer passes without a note', () {
      final question = _question('bi-wr-01');
      final check = QuizAnswerValidator.check(question, 'x^(n+1)/(n+1) + C');
      expect(check.outcome, QuizAnswerOutcome.correct);
      expect(check.noteKey, isNull);
    });

    test('dropping + C still scores, but earns a note', () {
      final question = _question('bi-wr-01');
      final check = QuizAnswerValidator.check(question, 'x^(n+1)/(n+1)');
      expect(check.outcome, QuizAnswerOutcome.correctWithNote);
      expect(check.noteKey, QuizAnswerValidator.missingConstantNoteKey);
      expect(check.isCorrect, isTrue);
    });

    test(
      'the note reaches every accepted spelling, not just the canonical',
      () {
        final question = _question('bi-wr-01');
        final check = QuizAnswerValidator.check(question, '(1/(n+1))x^(n+1)');
        expect(check.outcome, QuizAnswerOutcome.correctWithNote);
      },
    );

    test('a wrong antiderivative is still wrong, with or without + C', () {
      final question = _question('bi-wr-01');
      for (final wrong in ['x^n', 'x^n + C', 'n x^(n-1)', 'n x^(n-1) + C']) {
        expect(
          QuizAnswerValidator.check(question, wrong).outcome,
          QuizAnswerOutcome.incorrect,
          reason: wrong,
        );
      }
    });

    test('blank input never reaches the note path', () {
      final question = _question('bi-wr-01');
      for (final blank in ['', '   ']) {
        expect(
          QuizAnswerValidator.check(question, blank).outcome,
          QuizAnswerOutcome.incorrect,
        );
      }
    });

    test('derivative questions never earn the note', () {
      for (final question in QuizQuestionBank.all.where(
        (question) => question.prompt == QuizPrompt.derivative,
      )) {
        expect(
          QuizAnswerValidator.expectsConstantOfIntegration(question),
          isFalse,
          reason: question.id,
        );
      }
    });

    test('every written indefinite integral expects the constant', () {
      final integrals = QuizQuestionBank.all.where(
        (question) =>
            question.type == QuestionType.written &&
            question.prompt == QuizPrompt.integral,
      );
      expect(integrals, isNotEmpty);
      for (final question in integrals) {
        expect(
          QuizAnswerValidator.expectsConstantOfIntegration(question),
          isTrue,
          reason: question.id,
        );
        // Every accepted spelling has a constant-less twin that notes rather
        // than fails, so the learner-friendly grading stays intact.
        for (final form in QuizAnswerValidator.acceptedForms(question)) {
          final stripped = form.replaceAll(RegExp(r'\s*\+\s*C$'), '');
          expect(
            QuizAnswerValidator.check(question, stripped).outcome,
            QuizAnswerOutcome.correctWithNote,
            reason: '${question.id} / "$stripped"',
          );
        }
      }
    });
  });

  group('the integral of 1/x', () {
    final question = _question('bi-wr-02');

    test('the canonical answer keeps the absolute value', () {
      expect(question.correctAnswer, 'ln|x| + C');
    });

    test('absolute-value spellings are accepted', () {
      for (final accepted in ['ln|x| + C', 'ln(|x|) + C', 'LN|X| + C']) {
        expect(
          QuizAnswerValidator.check(question, accepted).outcome,
          QuizAnswerOutcome.correct,
          reason: accepted,
        );
      }
    });

    test('dropping only the constant still notes rather than fails', () {
      for (final accepted in ['ln|x|', 'ln(|x|)']) {
        expect(
          QuizAnswerValidator.check(question, accepted).outcome,
          QuizAnswerOutcome.correctWithNote,
          reason: accepted,
        );
      }
    });

    test('bare "ln x" is not silently accepted', () {
      for (final bare in ['ln x', 'ln x + C', 'ln(x)', 'ln(x) + C']) {
        expect(
          QuizAnswerValidator.check(question, bare).outcome,
          QuizAnswerOutcome.incorrect,
          reason: '$bare must not pass as ln|x| + C',
        );
      }
      expect(
        question.acceptedAnswers.any((form) => !form.contains('|')),
        isFalse,
        reason: 'accepted answers should focus on absolute value variants',
      );
    });
  });

  group('multiple choice', () {
    test('grades to a plain verdict, never to a note', () {
      for (final question in QuizQuestionBank.all.where(
        (question) => question.type == QuestionType.multipleChoice,
      )) {
        final correct = QuizAnswerValidator.correctOption(question)!;
        expect(
          QuizAnswerValidator.check(question, correct.id).outcome,
          QuizAnswerOutcome.correct,
          reason: question.id,
        );
        for (final option in question.options.where(
          (option) => option.id != correct.id,
        )) {
          expect(
            QuizAnswerValidator.check(question, option.id).outcome,
            QuizAnswerOutcome.incorrect,
            reason: '${question.id}/${option.id}',
          );
        }
      }
    });

    test('an unknown option id is incorrect, not a crash', () {
      final question = QuizQuestionBank.all.firstWhere(
        (question) => question.type == QuestionType.multipleChoice,
      );
      expect(
        QuizAnswerValidator.check(question, 'z').outcome,
        QuizAnswerOutcome.incorrect,
      );
    });
  });

  test('both passing outcomes count toward the score', () {
    expect(QuizAnswerOutcome.correct.isCorrect, isTrue);
    expect(QuizAnswerOutcome.correctWithNote.isCorrect, isTrue);
    expect(QuizAnswerOutcome.incorrect.isCorrect, isFalse);
  });

  test('a definite-looking integral without a constant expects none', () {
    const definite = QuizQuestion(
      id: 'definite',
      subject: QuizSubject.calculus,
      topicId: 'test-topic',
      subtopic: QuizSubtopic.powerRuleIntegral,
      difficulty: QuizDifficulty.easy,
      type: QuestionType.written,
      prompt: QuizPrompt.integral,
      expression: '∫ from 0 to 1 of x dx',
      correctAnswer: '1/2',
      explanationEn: 'Evaluate x^2/2 between 0 and 1.',
      explanationTr: '0 ile 1 arasında x^2/2 hesaplanır.',
    );
    expect(QuizAnswerValidator.expectsConstantOfIntegration(definite), isFalse);
    expect(
      QuizAnswerValidator.check(definite, '1/2').outcome,
      QuizAnswerOutcome.correct,
    );
  });
}

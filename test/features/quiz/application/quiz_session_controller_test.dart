import 'dart:math';

import 'package:calcademy/features/quiz/application/quiz_session_controller.dart';
import 'package:calcademy/features/quiz/data/quiz_question_repository.dart';
import 'package:calcademy/features/quiz/domain/quiz_answer_validator.dart';
import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/domain/quiz_session.dart';
import 'package:calcademy/features/quiz/domain/quiz_subject.dart';
import 'package:calcademy/features/quiz/domain/quiz_topic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tiny fixed bank keeps these assertions about session mechanics readable,
/// independent of whatever the shipped calculus bank happens to contain.
const _written = QuizQuestion(
  id: 'w1',
  subject: QuizSubject.calculus,
  topicId: 'test-topic',
  subtopic: QuizSubtopic.powerRule,
  difficulty: QuizDifficulty.easy,
  type: QuestionType.written,
  prompt: QuizPrompt.derivative,
  expression: 'd/dx (x^2)',
  correctAnswer: '2x',
  explanationEn: 'Power rule.',
  explanationTr: 'Kuvvet kuralı.',
);

const _writtenTwo = QuizQuestion(
  id: 'w2',
  subject: QuizSubject.calculus,
  topicId: 'test-topic',
  subtopic: QuizSubtopic.primaryTrig,
  difficulty: QuizDifficulty.medium,
  type: QuestionType.written,
  prompt: QuizPrompt.derivative,
  expression: 'd/dx (sin x)',
  correctAnswer: 'cos x',
  explanationEn: 'Trig derivative.',
  explanationTr: 'Trigonometrik türev.',
);

const _multipleChoice = QuizQuestion(
  id: 'm1',
  subject: QuizSubject.calculus,
  topicId: 'test-topic',
  subtopic: QuizSubtopic.powerRule,
  difficulty: QuizDifficulty.easy,
  type: QuestionType.multipleChoice,
  prompt: QuizPrompt.derivative,
  expression: 'd/dx (x^3)',
  correctAnswer: '3x^2',
  explanationEn: 'Power rule.',
  explanationTr: 'Kuvvet kuralı.',
  options: [
    QuizOption(id: 'a', text: '3x^2'),
    QuizOption(id: 'b', text: 'x^2'),
    QuizOption(id: 'c', text: '3x^3'),
    QuizOption(id: 'd', text: 'x^4/4'),
  ],
);

ProviderContainer _container(List<QuizQuestion> questions) {
  final container = ProviderContainer(
    overrides: [
      quizRepositoryProvider.overrideWithValue(
        QuizQuestionRepository(questions: questions),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

const _writtenConfig = QuizSessionConfig(
  subject: QuizSubject.calculus,
  questionType: QuestionType.written,
  questionCount: 2,
);

void main() {
  test('starts empty', () {
    final container = _container([_written]);
    expect(container.read(quizSessionProvider), isNull);
    expect(container.read(quizResultProvider), isNull);
  });

  test('start draws a session for the configuration', () {
    final container = _container([_written, _writtenTwo, _multipleChoice]);
    container.read(quizSessionProvider.notifier).start(_writtenConfig);

    final session = container.read(quizSessionProvider)!;
    expect(session.questions.length, 2);
    expect(
      session.questions.every(
        (question) => question.type == QuestionType.written,
      ),
      isTrue,
    );
    expect(session.currentIndex, 0);
    expect(session.isComplete, isFalse);
  });

  test('grades a written answer through normalization', () {
    final container = _container([_written]);
    container
        .read(quizSessionProvider.notifier)
        .start(
          const QuizSessionConfig(
            subject: QuizSubject.calculus,
            questionType: QuestionType.written,
            questionCount: 1,
          ),
        );

    expect(
      container.read(quizSessionProvider.notifier).submit('  2 * X '),
      QuizAnswerOutcome.correct,
    );
    final session = container.read(quizSessionProvider)!;
    expect(session.correctCount, 1);
    expect(session.isComplete, isTrue);
    expect(session.answers['w1']!.submitted, '  2 * X ');
  });

  test('grades a multiple-choice answer by option id', () {
    final container = _container([_multipleChoice]);
    container
        .read(quizSessionProvider.notifier)
        .start(
          const QuizSessionConfig(
            subject: QuizSubject.calculus,
            questionType: QuestionType.multipleChoice,
            questionCount: 1,
          ),
        );
    final controller = container.read(quizSessionProvider.notifier);
    final question = container.read(quizSessionProvider)!.currentQuestion;
    final correct = QuizAnswerValidator.correctOption(question)!;

    expect(controller.submit(correct.id), QuizAnswerOutcome.correct);
  });

  test('an already answered question keeps its first verdict', () {
    final container = _container([_written]);
    final controller = container.read(quizSessionProvider.notifier);
    controller.start(
      const QuizSessionConfig(
        subject: QuizSubject.calculus,
        questionType: QuestionType.written,
        questionCount: 1,
      ),
    );

    expect(controller.submit('wrong'), QuizAnswerOutcome.incorrect);
    // The second call reports the stored verdict rather than grading again.
    expect(controller.submit('2x'), QuizAnswerOutcome.incorrect);
    expect(
      container.read(quizSessionProvider)!.answers['w1']!.submitted,
      'wrong',
    );
  });

  test('next advances and stops on the last question', () {
    final container = _container([_written, _writtenTwo]);
    final controller = container.read(quizSessionProvider.notifier);
    controller.start(_writtenConfig);

    expect(container.read(quizSessionProvider)!.currentIndex, 0);
    controller.next();
    expect(container.read(quizSessionProvider)!.currentIndex, 1);
    expect(container.read(quizSessionProvider)!.isLastQuestion, isTrue);
    controller.next();
    expect(container.read(quizSessionProvider)!.currentIndex, 1);
  });

  test('the result reflects answered and unanswered questions', () {
    final container = _container([_written, _writtenTwo]);
    final controller = container.read(quizSessionProvider.notifier)
      ..start(_writtenConfig);
    final first = container.read(quizSessionProvider)!.currentQuestion;
    controller.submit(first.correctAnswer);

    final result = container.read(quizResultProvider)!;
    expect(result.totalQuestions, 2);
    expect(result.correctCount, 1);
    expect(result.incorrectCount, 1);
    expect(result.scorePercent, 50);
    expect(result.incorrectEntries.single.answer, isNull);
    expect(result.incorrectEntries.single.submittedText, '');
  });

  test('restart keeps the configuration and drops the answers', () {
    final container = _container([_written, _writtenTwo]);
    container.read(quizSessionProvider.notifier)
      ..start(_writtenConfig)
      ..submit('2x')
      ..restart(random: Random(3));

    final session = container.read(quizSessionProvider)!;
    expect(session.answers, isEmpty);
    expect(session.currentIndex, 0);
    expect(session.config.questionType, QuestionType.written);
  });

  test('clear removes the session and its result', () {
    final container = _container([_written]);
    container.read(quizSessionProvider.notifier)
      ..start(_writtenConfig)
      ..clear();

    expect(container.read(quizSessionProvider), isNull);
    expect(container.read(quizResultProvider), isNull);
  });

  test('submitting with no session is a no-op', () {
    final container = _container([_written]);
    expect(
      container.read(quizSessionProvider.notifier).submit('2x'),
      QuizAnswerOutcome.incorrect,
    );
    expect(container.read(quizSessionProvider), isNull);
  });
}

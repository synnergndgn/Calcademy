import 'dart:math';

import 'package:calcademy/features/quiz/data/quiz_question_repository.dart';
import 'package:calcademy/features/quiz/domain/quiz_answer_validator.dart';
import 'package:calcademy/features/quiz/domain/quiz_result.dart';
import 'package:calcademy/features/quiz/domain/quiz_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final quizRepositoryProvider = Provider<QuizQuestionRepository>(
  (ref) => const QuizQuestionRepository(),
);

/// The one session in flight, or null when the learner is still choosing.
final quizSessionProvider =
    NotifierProvider<QuizSessionController, QuizSession?>(
      QuizSessionController.new,
    );

/// The score for the current session. Available mid-session too, which is what
/// lets the result screen render straight off the same state.
final quizResultProvider = Provider<QuizResult?>((ref) {
  final session = ref.watch(quizSessionProvider);
  return session == null ? null : QuizResult.fromSession(session);
});

class QuizSessionController extends Notifier<QuizSession?> {
  @override
  QuizSession? build() => null;

  void start(QuizSessionConfig config, {Random? random}) {
    state = ref
        .read(quizRepositoryProvider)
        .buildSession(config, random: random);
  }

  /// Records an answer for the current question and returns how it graded.
  /// Re-submitting an already answered question is ignored, so a double tap
  /// cannot overwrite a verdict.
  QuizAnswerOutcome submit(String submitted) {
    final session = state;
    if (session == null || session.questions.isEmpty) {
      return QuizAnswerOutcome.incorrect;
    }
    final question = session.currentQuestion;
    if (session.answers.containsKey(question.id)) {
      return session.answers[question.id]!.outcome;
    }
    final check = QuizAnswerValidator.check(question, submitted);
    state = session.copyWith(
      answers: {
        ...session.answers,
        question.id: QuizAnswer(
          questionId: question.id,
          submitted: submitted,
          outcome: check.outcome,
          noteKey: check.noteKey,
        ),
      },
    );
    return check.outcome;
  }

  /// Advances to the next question. No-op on the last one; the session is
  /// finished at that point and the caller navigates to the result.
  void next() {
    final session = state;
    if (session == null || session.isLastQuestion) return;
    state = session.copyWith(currentIndex: session.currentIndex + 1);
  }

  /// Draws a fresh set of questions for the same configuration.
  void restart({Random? random}) {
    final session = state;
    if (session == null) return;
    start(session.config, random: random);
  }

  void clear() => state = null;
}

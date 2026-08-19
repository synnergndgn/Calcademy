import 'package:calcademy/features/quiz/domain/quiz_answer_validator.dart';
import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/domain/quiz_subject.dart';

/// Whether the session grades each question as it is answered or holds every
/// verdict back until the result screen.
enum QuizFeedbackMode { immediate, endOfSession }

/// What the learner asked for before the session was built.
class QuizSessionConfig {
  const QuizSessionConfig({
    required this.subject,
    required this.questionType,
    this.topicIds = const {},
    this.feedbackMode = QuizFeedbackMode.immediate,
    this.questionCount = defaultQuestionCount,
  });

  static const defaultQuestionCount = 10;

  final QuizSubject subject;

  /// Empty means every topic in [subject], which is how a mixed session is
  /// requested.
  final Set<String> topicIds;
  final QuestionType questionType;
  final QuizFeedbackMode feedbackMode;
  final int questionCount;
}

/// One submitted answer. [submitted] is an option id for multiple choice and
/// the raw typed text for written questions.
class QuizAnswer {
  const QuizAnswer({
    required this.questionId,
    required this.submitted,
    required this.outcome,
    this.noteKey,
  });

  final String questionId;
  final String submitted;

  /// The graded verdict. Kept whole rather than reduced to a bool so the
  /// screens can tell a clean pass from one that earned a reminder.
  final QuizAnswerOutcome outcome;

  /// Localization key for that reminder, when there is one.
  final String? noteKey;

  bool get isCorrect => outcome.isCorrect;

  bool get hasNote => outcome == QuizAnswerOutcome.correctWithNote;
}

/// An in-progress or finished run through a fixed list of questions.
class QuizSession {
  const QuizSession({
    required this.config,
    required this.questions,
    this.answers = const {},
    this.currentIndex = 0,
  });

  final QuizSessionConfig config;
  final List<QuizQuestion> questions;
  final Map<String, QuizAnswer> answers;
  final int currentIndex;

  QuizQuestion get currentQuestion => questions[currentIndex];

  QuizAnswer? get currentAnswer => answers[currentQuestion.id];

  int get answeredCount => answers.length;

  int get correctCount =>
      answers.values.where((answer) => answer.isCorrect).length;

  bool get isLastQuestion => currentIndex == questions.length - 1;

  bool get isComplete =>
      questions.isNotEmpty && answeredCount == questions.length;

  QuizSession copyWith({Map<String, QuizAnswer>? answers, int? currentIndex}) =>
      QuizSession(
        config: config,
        questions: questions,
        answers: answers ?? this.answers,
        currentIndex: currentIndex ?? this.currentIndex,
      );
}

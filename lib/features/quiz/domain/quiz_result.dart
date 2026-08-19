import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/domain/quiz_session.dart';

/// One question paired with what the learner actually submitted.
class QuizReviewEntry {
  const QuizReviewEntry({required this.question, required this.answer});

  final QuizQuestion question;

  /// Null when the session ended before this question was reached.
  final QuizAnswer? answer;

  bool get isCorrect => answer?.isCorrect ?? false;

  /// True when the answer passed but earned a reminder, e.g. an indefinite
  /// integral written without its constant of integration.
  bool get hasNote => answer?.hasNote ?? false;

  /// Localization key for that reminder, or null when there is none.
  String? get noteKey => answer?.noteKey;

  /// The submission as the learner would recognize it: the chosen option's
  /// text for multiple choice, the typed string for written answers.
  String get submittedText {
    final submitted = answer?.submitted;
    if (submitted == null || submitted.isEmpty) return '';
    if (question.type == QuestionType.written) return submitted;
    return question.optionById(submitted)?.text ?? '';
  }
}

/// The scored outcome of a session.
class QuizResult {
  const QuizResult({required this.entries, required this.feedbackMode});

  factory QuizResult.fromSession(QuizSession session) => QuizResult(
    entries: [
      for (final question in session.questions)
        QuizReviewEntry(
          question: question,
          answer: session.answers[question.id],
        ),
    ],
    feedbackMode: session.config.feedbackMode,
  );

  final List<QuizReviewEntry> entries;
  final QuizFeedbackMode feedbackMode;

  int get totalQuestions => entries.length;

  int get correctCount => entries.where((entry) => entry.isCorrect).length;

  int get incorrectCount => totalQuestions - correctCount;

  /// Answers that scored but carried a reminder. The result screen surfaces
  /// these, because a noted answer is never wrong enough to reach review.
  List<QuizReviewEntry> get notedEntries =>
      entries.where((entry) => entry.hasNote).toList(growable: false);

  /// Every distinct reminder the session earned, in the order first seen, so
  /// ten missing constants read as one line rather than ten.
  List<String> get noteKeys {
    final keys = <String>[];
    for (final entry in notedEntries) {
      final key = entry.noteKey;
      if (key != null && !keys.contains(key)) keys.add(key);
    }
    return keys;
  }

  List<QuizReviewEntry> get incorrectEntries =>
      entries.where((entry) => !entry.isCorrect).toList(growable: false);

  /// Score as a fraction in `0..1`; zero for an empty session.
  double get score => totalQuestions == 0 ? 0 : correctCount / totalQuestions;

  int get scorePercent => (score * 100).round();
}

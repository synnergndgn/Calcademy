import 'package:calcademy/features/quiz/domain/math_answer_normalizer.dart';
import 'package:calcademy/features/quiz/domain/quiz_question.dart';

/// How a submitted answer scored.
///
/// [correctWithNote] exists so a learner-friendly pass does not have to be a
/// silent one: it counts toward the score exactly like [correct], but carries
/// a key the UI turns into a reminder.
enum QuizAnswerOutcome {
  correct,
  correctWithNote,
  incorrect;

  /// Both passing outcomes score. The distinction is what the learner is
  /// told, not what the result adds up to.
  bool get isCorrect => this != QuizAnswerOutcome.incorrect;
}

/// The verdict on one submission, plus the note that goes with it.
class QuizAnswerCheck {
  const QuizAnswerCheck(this.outcome, {this.noteKey});

  static const correct = QuizAnswerCheck(QuizAnswerOutcome.correct);
  static const incorrect = QuizAnswerCheck(QuizAnswerOutcome.incorrect);

  final QuizAnswerOutcome outcome;

  /// Localization key for the reminder, non-null exactly when the outcome is
  /// [QuizAnswerOutcome.correctWithNote].
  final String? noteKey;

  bool get isCorrect => outcome.isCorrect;
}

/// Decides whether a submitted answer counts as correct.
///
/// Multiple choice compares the chosen option against the question's canonical
/// answer rather than trusting a flag on the option, so a bank row cannot mark
/// two options correct. Written answers compare normalized text against the
/// canonical answer plus any spellings the bank explicitly accepts.
abstract final class QuizAnswerValidator {
  /// Reminder shown when an indefinite integral is right except for the
  /// constant of integration.
  static const missingConstantNoteKey = 'quizNoteMissingConstant';

  /// The constant of integration as the bank spells it, and as it reads once
  /// normalized. Only these two forms need handling: normalization already
  /// folds case, spacing, and dash variants.
  static const _constantSuffix = ' + C';
  static const _normalizedConstantSuffix = '+c';

  static QuizAnswerCheck check(QuizQuestion question, String submitted) =>
      switch (question.type) {
        QuestionType.multipleChoice =>
          _isCorrectOption(question, submitted)
              ? QuizAnswerCheck.correct
              : QuizAnswerCheck.incorrect,
        QuestionType.written => _checkWritten(question, submitted),
      };

  static bool isCorrect(QuizQuestion question, String submitted) =>
      check(question, submitted).isCorrect;

  static bool matchesWrittenAnswer(QuizQuestion question, String submitted) {
    final normalized = MathAnswerNormalizer.normalize(submitted);
    if (normalized.isEmpty) return false;
    return acceptedForms(
      question,
    ).map(MathAnswerNormalizer.normalize).contains(normalized);
  }

  /// Every spelling a written answer may take, canonical form first.
  static List<String> acceptedForms(QuizQuestion question) => [
    question.correctAnswer,
    ...question.acceptedAnswers,
  ];

  /// True when the question asks for an indefinite integral, i.e. one whose
  /// canonical answer carries a constant of integration.
  ///
  /// The canonical answer is the test rather than the prompt alone, so a
  /// definite integral filed under the same prompt would not pick up the
  /// reminder.
  static bool expectsConstantOfIntegration(QuizQuestion question) =>
      question.prompt == QuizPrompt.integral &&
      MathAnswerNormalizer.normalize(
        question.correctAnswer,
      ).endsWith(_normalizedConstantSuffix);

  static QuizOption? correctOption(QuizQuestion question) {
    final target = MathAnswerNormalizer.normalize(question.correctAnswer);
    for (final option in question.options) {
      if (MathAnswerNormalizer.normalize(option.text) == target) return option;
    }
    return null;
  }

  static QuizAnswerCheck _checkWritten(
    QuizQuestion question,
    String submitted,
  ) {
    if (matchesWrittenAnswer(question, submitted)) {
      return QuizAnswerCheck.correct;
    }
    // An otherwise right antiderivative missing its `+ C`. Re-checking the
    // submission with the constant appended keeps the rule in one place
    // instead of asking every integral row to list a second spelling.
    if (expectsConstantOfIntegration(question) &&
        submitted.trim().isNotEmpty &&
        matchesWrittenAnswer(question, '$submitted$_constantSuffix')) {
      return const QuizAnswerCheck(
        QuizAnswerOutcome.correctWithNote,
        noteKey: missingConstantNoteKey,
      );
    }
    return QuizAnswerCheck.incorrect;
  }

  static bool _isCorrectOption(QuizQuestion question, String optionId) {
    final option = question.optionById(optionId);
    if (option == null) return false;
    return MathAnswerNormalizer.normalize(option.text) ==
        MathAnswerNormalizer.normalize(question.correctAnswer);
  }
}

import 'package:calcademy/features/quiz/domain/quiz_subject.dart';
import 'package:calcademy/features/quiz/domain/quiz_topic.dart';

enum QuestionType { multipleChoice, written }

enum QuizDifficulty { easy, medium, hard }

/// The localized instruction that precedes a question's expression.
///
/// The bank stores a key rather than prose so a question row carries no
/// language, and so a new locale needs no change to the data source.
enum QuizPrompt {
  derivative('quizPromptDerivative'),
  integral('quizPromptIntegral');

  const QuizPrompt(this.localizationKey);

  final String localizationKey;
}

/// One selectable answer on a multiple-choice question.
///
/// Correctness deliberately does not live here: [QuizQuestion.correctAnswer]
/// is the single source of truth, so an option cannot disagree with it.
class QuizOption {
  const QuizOption({required this.id, required this.text});

  final String id;
  final String text;
}

/// A single quiz item.
///
/// Presentation-neutral by design: it carries a [prompt] key and a
/// language-neutral [expression] instead of a rendered question string, so the
/// same row serves every locale and every screen that shows it.
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.subject,
    required this.topicId,
    required this.subtopic,
    required this.difficulty,
    required this.type,
    required this.prompt,
    required this.expression,
    required this.correctAnswer,
    required this.explanationEn,
    required this.explanationTr,
    this.options = const [],
    this.acceptedAnswers = const [],
  });

  final String id;
  final QuizSubject subject;
  final String topicId;
  final QuizSubtopic subtopic;
  final QuizDifficulty difficulty;
  final QuestionType type;

  /// Localization key for the instruction, e.g. "Find the derivative".
  final QuizPrompt prompt;

  /// The mathematics being asked about, e.g. `d/dx (x^3)`.
  final String expression;

  /// Canonical answer text. For [QuestionType.multipleChoice] exactly one
  /// entry of [options] matches it once both sides are normalized.
  final String correctAnswer;

  /// Extra spellings accepted in [QuestionType.written] mode, on top of
  /// [correctAnswer] and everything normalization already folds together.
  final List<String> acceptedAnswers;

  /// The derivation shown after answering and in review, in English.
  ///
  /// Explanations are teaching prose, so unlike [prompt] they cannot be a
  /// localization key without moving eighty paragraphs into the string table.
  /// They ride on the row in both languages instead, the same shape
  /// [QuizSubject] and [QuizTopic] already use for their titles.
  final String explanationEn;

  /// The same derivation in Turkish.
  final String explanationTr;

  final List<QuizOption> options;

  /// The derivation in the active locale, falling back to English for a
  /// language the bank has not been translated into.
  String explanation(String languageCode) =>
      languageCode == 'tr' ? explanationTr : explanationEn;

  QuizOption? optionById(String optionId) {
    for (final option in options) {
      if (option.id == optionId) return option;
    }
    return null;
  }

  /// Same question with its options in a different order.
  ///
  /// Sessions shuffle options so the correct answer is not always in the same
  /// slot; ids travel with their text, so a recorded answer stays valid.
  QuizQuestion withOptions(List<QuizOption> options) => QuizQuestion(
    id: id,
    subject: subject,
    topicId: topicId,
    subtopic: subtopic,
    difficulty: difficulty,
    type: type,
    prompt: prompt,
    expression: expression,
    correctAnswer: correctAnswer,
    explanationEn: explanationEn,
    explanationTr: explanationTr,
    options: options,
    acceptedAnswers: acceptedAnswers,
  );
}

import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/domain/quiz_session.dart';
import 'package:calcademy/features/quiz/presentation/math_display.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Where the quiz domain meets the string table.
///
/// The bank stores keys and enums, never prose, so every rendered label is
/// resolved here rather than inside a model.
String quizPromptLabel(BuildContext context, QuizPrompt prompt) =>
    context.l10n.t(prompt.localizationKey);

String quizDifficultyLabel(BuildContext context, QuizDifficulty difficulty) =>
    context.l10n.t(switch (difficulty) {
      QuizDifficulty.easy => 'quizDifficultyEasy',
      QuizDifficulty.medium => 'quizDifficultyMedium',
      QuizDifficulty.hard => 'quizDifficultyHard',
    });

String quizQuestionTypeLabel(BuildContext context, QuestionType type) =>
    context.l10n.t(switch (type) {
      QuestionType.multipleChoice => 'quizModeMultipleChoice',
      QuestionType.written => 'quizModeWritten',
    });

String quizQuestionTypeDescription(BuildContext context, QuestionType type) =>
    context.l10n.t(switch (type) {
      QuestionType.multipleChoice => 'quizModeMultipleChoiceDescription',
      QuestionType.written => 'quizModeWrittenDescription',
    });

String quizFeedbackModeLabel(BuildContext context, QuizFeedbackMode mode) =>
    context.l10n.t(switch (mode) {
      QuizFeedbackMode.immediate => 'quizFeedbackImmediate',
      QuizFeedbackMode.endOfSession => 'quizFeedbackEndOfSession',
    });

/// The question's derivation in the locale the app is running in.
///
/// Explanations live on the row in both languages rather than in the string
/// table, so this is the one place that picks between them; no screen reads
/// [QuizQuestion.explanationEn] or [QuizQuestion.explanationTr] directly.
String quizExplanationText(BuildContext context, QuizQuestion question) =>
    MathDisplay.format(
      question.explanation(Localizations.localeOf(context).languageCode),
    );

/// The mathematics being asked about, set the way it is written on paper.
///
/// The bank stores caret notation because that is what grading and a phone
/// keyboard agree on; every screen renders it through here instead, so `x^2`
/// reaches the learner as `x²` without either side of the comparison moving.
String quizExpressionText(QuizQuestion question) =>
    MathDisplay.format(question.expression);

/// The canonical answer, in the same polished notation.
String quizAnswerText(String answer) => MathDisplay.format(answer);

/// What the learner submitted, as they would recognize it.
///
/// A chosen option is bank text and is polished like the rest of it; a typed
/// answer is echoed exactly as typed, because that is the thing being
/// discussed.
String quizSubmittedText(QuizQuestion question, String submitted) =>
    question.type == QuestionType.written
    ? submitted
    : MathDisplay.format(submitted);

/// "Question 3 / 10". The string table has no placeholder support, so the
/// counter is composed rather than interpolated into a translated sentence.
String quizProgressLabel(BuildContext context, int index, int total) =>
    '${context.l10n.t('quizQuestionLabel')} ${index + 1} / $total';

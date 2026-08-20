import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/domain/quiz_session.dart';
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
///
/// The result is still the bank's own notation. Screens hand it to
/// `MathFormula`, which is what turns it into typeset mathematics; nothing
/// here formats, so a screen cannot accidentally show a half-polished string.
String quizExplanationSource(BuildContext context, QuizQuestion question) =>
    question.explanation(Localizations.localeOf(context).languageCode);

/// What the learner submitted, in the notation it should be shown in.
///
/// A chosen option resolves to that option's own text; a written answer is the
/// string as typed. Both are rendered by `MathFormula` afterwards, so a typed
/// `x^2` is shown back as x² -- the same spelling as the correct answer it
/// sits next to, which is the comparison the panel exists to make.
String quizSubmittedSource(QuizQuestion question, String submitted) =>
    question.type == QuestionType.written
    ? submitted
    : question.optionById(submitted)?.text ?? submitted;

/// "Question 3 / 10". The string table has no placeholder support, so the
/// counter is composed rather than interpolated into a translated sentence.
String quizProgressLabel(BuildContext context, int index, int total) =>
    '${context.l10n.t('quizQuestionLabel')} ${index + 1} / $total';

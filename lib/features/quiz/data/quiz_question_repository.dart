import 'dart:math';

import 'package:calcademy/features/quiz/data/calculus/basic_derivative_questions.dart';
import 'package:calcademy/features/quiz/data/calculus/basic_integral_questions.dart';
import 'package:calcademy/features/quiz/data/calculus/exponential_logarithmic_derivative_questions.dart';
import 'package:calcademy/features/quiz/data/calculus/trigonometric_derivative_questions.dart';
import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/domain/quiz_session.dart';

/// Every question that ships with the app.
///
/// One flat list per subject file keeps the bank a data source: nothing here
/// knows about widgets, locales, or navigation.
abstract final class QuizQuestionBank {
  static const all = <QuizQuestion>[
    ...basicDerivativeQuestions,
    ...trigonometricDerivativeQuestions,
    ...exponentialLogarithmicDerivativeQuestions,
    ...basicIntegralQuestions,
  ];
}

/// Turns a [QuizSessionConfig] into the concrete list of questions to ask.
class QuizQuestionRepository {
  const QuizQuestionRepository({this.questions = QuizQuestionBank.all});

  final List<QuizQuestion> questions;

  /// Everything matching the configuration's subject, topics, and type.
  List<QuizQuestion> pool(QuizSessionConfig config) => questions
      .where(
        (question) =>
            question.subject == config.subject &&
            question.type == config.questionType &&
            (config.topicIds.isEmpty ||
                config.topicIds.contains(question.topicId)),
      )
      .toList(growable: false);

  int availableCount(QuizSessionConfig config) => pool(config).length;

  /// Draws a session, shuffling both the question order and each question's
  /// options so the answer never sits in a predictable slot.
  ///
  /// A short pool yields a short session rather than an error, which is what
  /// keeps a half-populated future subject usable.
  QuizSession buildSession(QuizSessionConfig config, {Random? random}) {
    final generator = random ?? Random();
    final candidates = pool(config).toList()..shuffle(generator);
    final selected = candidates.take(config.questionCount).toList()
      ..sort((a, b) => a.difficulty.index.compareTo(b.difficulty.index));
    return QuizSession(
      config: config,
      questions: [
        for (final question in selected) _shuffleOptions(question, generator),
      ],
    );
  }

  static QuizQuestion _shuffleOptions(QuizQuestion question, Random generator) {
    if (question.options.length < 2) return question;
    return question.withOptions(question.options.toList()..shuffle(generator));
  }
}

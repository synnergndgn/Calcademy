import 'dart:math';

import 'package:calcademy/features/quiz/data/quiz_question_repository.dart';
import 'package:calcademy/features/quiz/data/quiz_topic_registry.dart';
import 'package:calcademy/features/quiz/domain/math_answer_normalizer.dart';
import 'package:calcademy/features/quiz/domain/quiz_answer_validator.dart';
import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/domain/quiz_session.dart';
import 'package:calcademy/features/quiz/domain/quiz_subject.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bank is hand-authored data, so its invariants are worth asserting: a
/// duplicated id or an option that quietly normalizes onto the right answer
/// would mis-grade a learner and never throw.
void main() {
  const questions = QuizQuestionBank.all;
  const repository = QuizQuestionRepository();

  test('question ids are unique', () {
    final ids = questions.map((question) => question.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every question belongs to a registered topic', () {
    for (final question in questions) {
      final topic = QuizTopicRegistry.byId(question.topicId);
      expect(topic, isNotNull, reason: '${question.id} has no topic');
      expect(topic!.subject, question.subject, reason: question.id);
    }
  });

  test('every question carries a prompt, expression, and explanation', () {
    for (final question in questions) {
      expect(question.expression.trim(), isNotEmpty, reason: question.id);
      expect(question.correctAnswer.trim(), isNotEmpty, reason: question.id);
      expect(question.explanationEn.trim(), isNotEmpty, reason: question.id);
      expect(question.explanationTr.trim(), isNotEmpty, reason: question.id);
    }
  });

  group('the questions are rule recall, not arithmetic', () {
    // The module exists to drill formulas a learner has to produce on sight.
    // A prompt like `d/dx (x^3 - 2)` asks them to compute instead, which is
    // what the calculator is for, so the shape of the prompt is asserted
    // rather than left to review.

    /// A number multiplying a variable, e.g. the `3x` in `3x^4 - 2x`. The
    /// lookbehind lets `sec^2 x` through: there the digit is an exponent on a
    /// function name, not a coefficient. The lookahead lets `∫ 1 dx` through,
    /// where the letter after the number is the differential.
    final coefficient = RegExp(r'(?<!\^)[0-9]\s*(?!d[a-z]\b)[a-z]');

    /// A variable raised to a specific number, e.g. `x^3`, as opposed to the
    /// general `x^n` the power rule is stated with. The lookbehind keeps a
    /// function power such as `sec^2 x` out of it: there the base is a name,
    /// not a variable, and the 2 is part of the formula being recalled.
    final numericPower = RegExp(r'(?<![a-z])[a-z]\^\(?-?[0-9]');

    /// A derivative of a specific constant, e.g. `d/dx (7)`. The closing
    /// bracket is part of the pattern so `d/dx (1/x)` -- a formula, not a
    /// calculation -- is not caught with it.
    final numericConstant = RegExp(r'd/dx\s*\(-?[0-9]+\)');

    /// A specific constant under an integral sign, e.g. `∫ 5 dx`. The unit
    /// case is the table entry, so the number itself is checked rather than
    /// its presence.
    final numericIntegrand = RegExp(r'∫\s*(-?[0-9]+)\s*d[a-z]');

    /// A function raised to a power inside a derivative, e.g.
    /// `d/dx (sin^2 x)`, which is the chain rule on one composition. The same
    /// shape under an integral sign -- `∫ sec^2 x dx` -- is a table entry.
    final composedPower = RegExp(r'(sin|cos|tan|cot|sec|csc|ln)\^[0-9]');

    test('no prompt carries a numeric coefficient or power', () {
      for (final question in questions) {
        final expression = question.expression;
        expect(
          coefficient.hasMatch(expression),
          isFalse,
          reason: '${question.id} asks for a calculation: "$expression"',
        );
        expect(
          numericPower.hasMatch(expression),
          isFalse,
          reason:
              '${question.id} pins the power rule to a number: '
              '"$expression"',
        );
        expect(
          numericConstant.hasMatch(expression),
          isFalse,
          reason:
              '${question.id} differentiates a specific constant: '
              '"$expression"',
        );
        final integrand = numericIntegrand.firstMatch(expression)?[1];
        expect(
          integrand ?? '1',
          '1',
          reason:
              '${question.id} integrates a specific constant: "$expression"',
        );
        if (question.prompt == QuizPrompt.derivative) {
          expect(
            composedPower.hasMatch(expression),
            isFalse,
            reason:
                '${question.id} asks for the chain rule on a composition: '
                '"$expression"',
          );
        }
      }
    });

    test('the MVP rule set is covered', () {
      final expressions = questions
          .map((question) => question.expression)
          .toList();
      for (final rule in _mvpRules) {
        expect(
          expressions.any((expression) => expression.contains(rule)),
          isTrue,
          reason: 'no question asks about "$rule"',
        );
      }
    });

    test("every question is filed under one of its topic's subtopics", () {
      for (final question in questions) {
        final topic = QuizTopicRegistry.byId(question.topicId)!;
        expect(
          topic.subtopics,
          contains(question.subtopic),
          reason:
              '${question.id} is filed under ${question.subtopic.id}, '
              'which ${topic.id} does not list',
        );
      }
    });
  });

  group('multiple choice', () {
    final multipleChoice = questions
        .where((question) => question.type == QuestionType.multipleChoice)
        .toList();

    test('offers exactly four options with unique ids', () {
      for (final question in multipleChoice) {
        expect(question.options.length, 4, reason: question.id);
        expect(
          question.options.map((option) => option.id).toSet().length,
          4,
          reason: question.id,
        );
      }
    });

    test('exactly one option matches the correct answer', () {
      for (final question in multipleChoice) {
        final target = MathAnswerNormalizer.normalize(question.correctAnswer);
        final matches = question.options
            .where(
              (option) => MathAnswerNormalizer.normalize(option.text) == target,
            )
            .length;
        expect(matches, 1, reason: '${question.id} has $matches matches');
      }
    });

    test('distractors stay distinct once normalized', () {
      for (final question in multipleChoice) {
        final normalized = question.options
            .map((option) => MathAnswerNormalizer.normalize(option.text))
            .toSet();
        expect(normalized.length, 4, reason: question.id);
      }
    });

    test('grading accepts the right option and rejects the others', () {
      for (final question in multipleChoice) {
        final correct = QuizAnswerValidator.correctOption(question)!;
        expect(
          QuizAnswerValidator.isCorrect(question, correct.id),
          isTrue,
          reason: question.id,
        );
        for (final option in question.options.where(
          (option) => option.id != correct.id,
        )) {
          expect(
            QuizAnswerValidator.isCorrect(question, option.id),
            isFalse,
            reason: '${question.id}/${option.id}',
          );
        }
      }
    });

    test('carries no written-only accepted answers', () {
      for (final question in multipleChoice) {
        expect(question.acceptedAnswers, isEmpty, reason: question.id);
      }
    });
  });

  group('written', () {
    final written = questions
        .where((question) => question.type == QuestionType.written)
        .toList();

    test('has no options', () {
      for (final question in written) {
        expect(question.options, isEmpty, reason: question.id);
      }
    });

    test('accepts each of its own accepted spellings', () {
      for (final question in written) {
        for (final form in QuizAnswerValidator.acceptedForms(question)) {
          expect(
            QuizAnswerValidator.matchesWrittenAnswer(question, form),
            isTrue,
            reason: '${question.id} rejects its own "$form"',
          );
        }
      }
    });

    test('accepted spellings are not redundant', () {
      for (final question in written) {
        final normalized = QuizAnswerValidator.acceptedForms(
          question,
        ).map(MathAnswerNormalizer.normalize).toList();
        expect(
          normalized.toSet().length,
          normalized.length,
          reason: '${question.id} lists a spelling that already normalizes',
        );
      }
    });

    test('rejects empty and wrong input', () {
      for (final question in written) {
        expect(QuizAnswerValidator.isCorrect(question, ''), isFalse);
        expect(QuizAnswerValidator.isCorrect(question, '   '), isFalse);
        expect(
          QuizAnswerValidator.isCorrect(question, 'definitely not the answer'),
          isFalse,
          reason: question.id,
        );
      }
    });
  });

  group('session pools', () {
    test('every calculus topic can fill a session in both modes', () {
      for (final topic in QuizTopicRegistry.forSubject(QuizSubject.calculus)) {
        for (final type in QuestionType.values) {
          final config = QuizSessionConfig(
            subject: QuizSubject.calculus,
            topicIds: {topic.id},
            questionType: type,
          );
          expect(
            repository.availableCount(config),
            greaterThanOrEqualTo(QuizSessionConfig.defaultQuestionCount),
            reason: '${topic.id}/${type.name}',
          );
        }
      }
    });

    test('a mixed session draws from every topic in the subject', () {
      const config = QuizSessionConfig(
        subject: QuizSubject.calculus,
        questionType: QuestionType.written,
      );
      final topicIds = repository
          .pool(config)
          .map((question) => question.topicId)
          .toSet();
      expect(
        topicIds.length,
        QuizTopicRegistry.forSubject(QuizSubject.calculus).length,
      );
    });

    test('a built session is the requested length and free of repeats', () {
      const config = QuizSessionConfig(
        subject: QuizSubject.calculus,
        questionType: QuestionType.multipleChoice,
      );
      final session = repository.buildSession(config, random: Random(7));
      expect(session.questions.length, 10);
      expect(
        session.questions.map((question) => question.id).toSet().length,
        10,
      );
    });

    test('shuffling options preserves the correct answer', () {
      const config = QuizSessionConfig(
        subject: QuizSubject.calculus,
        questionType: QuestionType.multipleChoice,
      );
      for (var seed = 0; seed < 20; seed++) {
        final session = repository.buildSession(config, random: Random(seed));
        for (final question in session.questions) {
          expect(question.options.length, 4);
          expect(
            QuizAnswerValidator.correctOption(question),
            isNotNull,
            reason: '${question.id} lost its correct option on seed $seed',
          );
        }
      }
    });

    test('does not put the answer in the same slot every time', () {
      const config = QuizSessionConfig(
        subject: QuizSubject.calculus,
        questionType: QuestionType.multipleChoice,
      );
      final slots = <int>{};
      for (var seed = 0; seed < 20; seed++) {
        final session = repository.buildSession(config, random: Random(seed));
        for (final question in session.questions) {
          final correct = QuizAnswerValidator.correctOption(question)!;
          slots.add(question.options.indexOf(correct));
        }
      }
      expect(slots.length, greaterThan(1));
    });

    test('a short pool yields a short session instead of failing', () {
      const config = QuizSessionConfig(
        subject: QuizSubject.calculus,
        questionType: QuestionType.written,
        topicIds: {CalculusTopicIds.basicIntegrals},
        questionCount: 40,
      );
      final session = repository.buildSession(config, random: Random(1));
      expect(session.questions.length, 10);
    });

    test('an unpopulated subject yields an empty session', () {
      const config = QuizSessionConfig(
        subject: QuizSubject.financeMath,
        questionType: QuestionType.written,
      );
      expect(repository.availableCount(config), 0);
      expect(repository.buildSession(config).questions, isEmpty);
    });
  });
}

/// The rules the MVP promises to drill, written as they appear in a prompt.
///
/// Listed here rather than counted, so dropping one while rewriting the bank
/// is a failing test instead of a gap a learner finds during revision.
const _mvpRules = [
  'd/dx (c)',
  'd/dx (x)',
  'd/dx (x^n)',
  'd/dx (c f(x))',
  'd/dx (k x)',
  'd/dx (f(x) + g(x))',
  'd/dx (f(x) - g(x))',
  'd/dx (sin x)',
  'd/dx (cos x)',
  'd/dx (tan x)',
  'd/dx (cot x)',
  'd/dx (sec x)',
  'd/dx (csc x)',
  'd/dx (e^x)',
  'd/dx (a^x)',
  'd/dx (ln x)',
  'd/dx (log_a x)',
  '∫ e^x dx',
  '∫ a^x dx',
  '∫ x^n dx',
  '∫ (1/x) dx',
  '∫ sin x dx',
  '∫ cos x dx',
  '∫ sec^2 x dx',
  '∫ csc^2 x dx',
  '∫ sec x tan x dx',
  '∫ csc x cot x dx',
  '∫ k dx',
];

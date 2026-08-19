import 'package:calcademy/features/quiz/domain/quiz_subject.dart';
import 'package:calcademy/features/quiz/domain/quiz_topic.dart';

/// Stable topic ids. Referenced by the question bank and by routing, so they
/// are declared once here rather than repeated as literals.
abstract final class CalculusTopicIds {
  static const basicDerivatives = 'basic-derivatives';
  static const trigDerivatives = 'trigonometric-derivatives';
  static const expLogDerivatives = 'exponential-logarithmic-derivatives';
  static const basicIntegrals = 'basic-integrals';
}

/// The catalogue of quiz topics, grouped by subject.
///
/// A subject with no topics is a subject that has not shipped yet; the home
/// screen reads exactly that to decide what is selectable.
///
/// The descriptions name rules rather than worked examples, because that is
/// what the bank asks about: the module is a formula drill, not a problem set.
abstract final class QuizTopicRegistry {
  static const topics = <QuizTopic>[
    QuizTopic(
      id: CalculusTopicIds.basicDerivatives,
      subject: QuizSubject.calculus,
      titleEn: 'Basic derivative rules',
      titleTr: 'Temel türev kuralları',
      descriptionEn:
          'Constant, power, constant multiple, sum, and difference rules.',
      descriptionTr: 'Sabit, kuvvet, sabitle çarpım, toplam ve fark kuralları.',
      subtopics: [
        QuizSubtopic.constantRule,
        QuizSubtopic.powerRule,
        QuizSubtopic.constantMultiple,
        QuizSubtopic.sumRule,
        QuizSubtopic.productRule,
      ],
    ),
    QuizTopic(
      id: CalculusTopicIds.trigDerivatives,
      subject: QuizSubject.calculus,
      titleEn: 'Trigonometric derivatives',
      titleTr: 'Trigonometrik türevler',
      descriptionEn: 'The six formulas: sin, cos, tan, cot, sec, and csc.',
      descriptionTr: 'Altı formül: sin, cos, tan, cot, sec ve csc.',
      subtopics: [
        QuizSubtopic.primaryTrig,
        QuizSubtopic.reciprocalTrig,
        QuizSubtopic.constantMultiple,
        QuizSubtopic.chainRule,
      ],
    ),
    QuizTopic(
      id: CalculusTopicIds.expLogDerivatives,
      subject: QuizSubject.calculus,
      titleEn: 'Exponential and logarithmic rules',
      titleTr: 'Üstel ve logaritmik kurallar',
      descriptionEn: 'Derivatives and integrals of eˣ, aˣ, ln x, and logₐx.',
      descriptionTr: 'eˣ, aˣ, ln x ve logₐx türev ve integralleri.',
      subtopics: [
        QuizSubtopic.exponential,
        QuizSubtopic.logarithmic,
        QuizSubtopic.chainRule,
      ],
    ),
    QuizTopic(
      id: CalculusTopicIds.basicIntegrals,
      subject: QuizSubject.calculus,
      titleEn: 'Basic integral rules',
      titleTr: 'Temel integral kuralları',
      descriptionEn: 'Antiderivatives of xⁿ, 1/x, and the trig functions.',
      descriptionTr: 'xⁿ, 1/x ve trigonometrik fonksiyonların ters türevleri.',
      subtopics: [
        QuizSubtopic.powerRuleIntegral,
        QuizSubtopic.basicAntiderivative,
        QuizSubtopic.constantMultiple,
        QuizSubtopic.trigIntegral,
      ],
    ),
  ];

  static List<QuizTopic> forSubject(QuizSubject subject) =>
      topics.where((topic) => topic.subject == subject).toList(growable: false);

  static QuizTopic? byId(String id) {
    for (final topic in topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }

  static bool hasContent(QuizSubject subject) =>
      topics.any((topic) => topic.subject == subject);
}

import 'package:calcademy/features/quiz/domain/quiz_subject.dart';

/// The rule a question drills, one level below [QuizTopic].
///
/// Kept as an enum rather than a free string so the bank cannot drift into
/// near-duplicate labels and so the review screen can translate the tag.
enum QuizSubtopic {
  constantRule('constant-rule', 'Constant Rule', 'Sabit Kuralı'),
  powerRule('power-rule', 'Power Rule', 'Kuvvet Kuralı'),
  constantMultiple(
    'constant-multiple',
    'Constant Multiple Rule',
    'Sabitle Çarpım Kuralı',
  ),
  sumRule('sum-rule', 'Sum & Difference Rule', 'Toplam ve Fark Kuralı'),
  productRule('product-rule', 'Product Rule', 'Çarpım Kuralı'),
  chainRule('chain-rule', 'Chain Rule', 'Zincir Kuralı'),
  primaryTrig(
    'primary-trig',
    'Sine, Cosine & Tangent',
    'Sinüs, Kosinüs ve Tanjant',
  ),
  reciprocalTrig(
    'reciprocal-trig',
    'Secant, Cosecant & Cotangent',
    'Sekant, Kosekant ve Kotanjant',
  ),
  exponential('exponential', 'Exponential Functions', 'Üstel Fonksiyonlar'),
  logarithmic(
    'logarithmic',
    'Logarithmic Functions',
    'Logaritmik Fonksiyonlar',
  ),
  powerRuleIntegral(
    'power-rule-integral',
    'Power Rule for Integrals',
    'İntegralde Kuvvet Kuralı',
  ),
  basicAntiderivative(
    'basic-antiderivative',
    'Basic Antiderivatives',
    'Temel Ters Türevler',
  ),
  trigIntegral(
    'trig-integral',
    'Trigonometric Integrals',
    'Trigonometrik İntegraller',
  );

  const QuizSubtopic(this.id, this.titleEn, this.titleTr);

  final String id;
  final String titleEn;
  final String titleTr;

  String title(String languageCode) => languageCode == 'tr' ? titleTr : titleEn;
}

/// One studiable unit inside a subject, e.g. "Trigonometric derivatives".
class QuizTopic {
  const QuizTopic({
    required this.id,
    required this.subject,
    required this.titleEn,
    required this.titleTr,
    required this.descriptionEn,
    required this.descriptionTr,
    required this.subtopics,
  });

  final String id;
  final QuizSubject subject;
  final String titleEn;
  final String titleTr;
  final String descriptionEn;
  final String descriptionTr;
  final List<QuizSubtopic> subtopics;

  String title(String languageCode) => languageCode == 'tr' ? titleTr : titleEn;

  String description(String languageCode) =>
      languageCode == 'tr' ? descriptionTr : descriptionEn;
}

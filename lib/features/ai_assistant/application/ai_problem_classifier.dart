import 'package:calcademy/features/ai_assistant/domain/ai_problem_intent.dart';

class AiProblemClassifier {
  const AiProblemClassifier();

  AiProblemIntent classify(String input) {
    final text = _normalize(input);
    if (_containsAny(text, const [
      'hava durumu',
      'weather',
      'yemek',
      'recipe',
      'haber',
      'news',
      'kisisel tavsiye',
      'personal advice',
      'yatirim tavsiyesi',
      'yatirim oner',
      'investment advice',
      'stock pick',
      'saglik teshisi',
      'medical diagnosis',
      'hukuk',
      'legal advice',
      'sinavda kopya',
      'cheat on exam',
    ])) {
      return AiProblemIntent.outOfScope;
    }
    if (_containsAny(text, const [
      'integer programming',
      'tamsayili programlama',
      'tam sayili programlama',
      'mip',
    ])) {
      return AiProblemIntent.integerProgramming;
    }
    if (_containsAny(text, const [
      'linear programming',
      'dogrusal programlama',
      'constraint',
      'objective',
      'amac fonksiyonu',
    ])) {
      return AiProblemIntent.linearProgramming;
    }
    if (_containsAny(text, const [
      'transportation',
      'assignment',
      'cpm',
      'pert',
      'goal programming',
      'yoneylem',
    ])) {
      return AiProblemIntent.operationsResearch;
    }
    if (_containsAny(text, const [
      'matrix',
      'matris',
      'determinant',
      'inverse',
      'ters matris',
      'rref',
    ])) {
      return AiProblemIntent.matrix;
    }
    if (_containsAny(text, const [
      'derivative',
      'turev',
      'integral',
      'limit',
      'tangent',
      'teget',
    ])) {
      return AiProblemIntent.calculus;
    }
    if (_containsAny(text, const [
      'npv',
      'net present value',
      'irr',
      'faiz',
      'compound',
      'future value',
      'present value',
      'loan',
      'annuity',
      'finans',
      'finance',
    ])) {
      return AiProblemIntent.finance;
    }
    if (_containsAny(text, const [
      'standard deviation',
      'standart sapma',
      'mean',
      'average',
      'ortalama',
      'variance',
      'varyans',
      'z-score',
      'normal',
      'binomial',
      'poisson',
    ])) {
      return AiProblemIntent.statistics;
    }
    if (_containsAny(text, const [
      'graph',
      'grafik',
      'plot',
      'fonksiyon ciz',
      'ciz',
    ])) {
      return AiProblemIntent.graphing;
    }
    if (_containsAny(text, const [
      'equation',
      'denklem',
      'solve',
      'kok',
      'root',
    ])) {
      return AiProblemIntent.equationSolving;
    }
    if (_containsAny(text, const [
      'formula',
      'formul',
      'kutuphane',
      'nasil hesaplanir',
    ])) {
      return AiProblemIntent.formulaLookup;
    }
    if (_containsAny(text, const [
      'calculate',
      'hesapla',
      'sin(',
      'cos(',
      'log(',
      'sqrt',
    ])) {
      return AiProblemIntent.scientificCalculation;
    }
    return AiProblemIntent.unsupported;
  }

  static String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  static bool _containsAny(String value, List<String> terms) =>
      terms.any(value.contains);
}

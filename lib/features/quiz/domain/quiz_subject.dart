/// Subjects the quiz module can cover.
///
/// Only [calculus] ships with a question bank today. The remaining values are
/// declared up front so the subject picker, routing, and persistence keys stay
/// stable as later banks land.
/// The Turkish titles name the scope rather than transliterating the English
/// one: a Turkish learner looks for "Türev & İntegral", not "Kalkülüs".
enum QuizSubject {
  calculus(
    'calculus',
    'Calculus',
    'Türev & İntegral',
    'Limits, derivatives, integrals, and the standard formulas.',
    'Limitler, türevler, integraller ve temel formüller',
  ),
  linearAlgebra(
    'linear-algebra',
    'Linear Algebra',
    'Lineer Cebir',
    'Matrices, determinants, and systems of equations.',
    'Matrisler, determinantlar ve denklem sistemleri',
  ),
  statistics(
    'statistics',
    'Statistics',
    'İstatistik',
    'Descriptive measures, distributions, and confidence intervals.',
    'Betimsel ölçüler, dağılımlar ve güven aralıkları',
  ),
  differentialEquations(
    'differential-equations',
    'Differential Equations',
    'Diferansiyel Denklemler',
    'First- and second-order equations and their standard solutions.',
    'Birinci ve ikinci mertebeden denklemler ve temel çözümleri',
  ),
  financeMath(
    'finance-math',
    'Finance Math',
    'Finans Matematiği',
    'Interest, annuities, and present value.',
    'Faiz, anuiteler ve bugünkü değer',
  );

  const QuizSubject(
    this.id,
    this.titleEn,
    this.titleTr,
    this.subtitleEn,
    this.subtitleTr,
  );

  final String id;
  final String titleEn;
  final String titleTr;

  /// One line describing what the subject covers, shown under its title on
  /// the subject picker.
  final String subtitleEn;
  final String subtitleTr;

  String title(String languageCode) => languageCode == 'tr' ? titleTr : titleEn;

  String subtitle(String languageCode) =>
      languageCode == 'tr' ? subtitleTr : subtitleEn;

  static QuizSubject? byId(String id) {
    for (final subject in values) {
      if (subject.id == id) return subject;
    }
    return null;
  }
}

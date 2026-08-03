enum FormulaCategory {
  mathematics('Mathematics', 'Matematik'),
  algebra('Algebra', 'Cebir'),
  calculus('Calculus', 'Kalkülüs'),
  linearAlgebra('Linear Algebra', 'Lineer Cebir'),
  statisticsProbability('Statistics & Probability', 'İstatistik ve Olasılık'),
  finance('Finance', 'Finans'),
  engineeringEconomy('Engineering Economy', 'Mühendislik Ekonomisi'),
  optimization('Optimization', 'Optimizasyon'),
  operationsResearch('Operations Research', 'Yöneylem Araştırması');

  const FormulaCategory(this.titleEn, this.titleTr);

  final String titleEn;
  final String titleTr;

  String localized(String languageCode) =>
      languageCode == 'tr' ? titleTr : titleEn;
}

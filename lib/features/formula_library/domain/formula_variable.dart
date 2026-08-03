class FormulaVariable {
  const FormulaVariable({
    required this.symbol,
    required this.nameEn,
    required this.nameTr,
    required this.descriptionEn,
    required this.descriptionTr,
    this.unit,
  });

  final String symbol;
  final String nameEn;
  final String nameTr;
  final String descriptionEn;
  final String descriptionTr;
  final String? unit;
}

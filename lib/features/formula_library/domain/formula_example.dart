class FormulaExample {
  const FormulaExample({
    required this.titleEn,
    required this.titleTr,
    required this.givenValues,
    required this.stepsEn,
    required this.stepsTr,
    required this.result,
    this.relatedToolInput,
  });

  final String titleEn;
  final String titleTr;
  final Map<String, String> givenValues;
  final List<String> stepsEn;
  final List<String> stepsTr;
  final String result;
  final Map<String, Object?>? relatedToolInput;
}

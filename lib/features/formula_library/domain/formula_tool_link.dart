class FormulaToolLink {
  const FormulaToolLink({
    required this.toolId,
    required this.route,
    required this.labelEn,
    required this.labelTr,
    this.supportedPrefill = false,
    this.prefillSchema,
  });

  final String toolId;
  final String route;
  final String labelEn;
  final String labelTr;
  final bool supportedPrefill;
  final Map<String, String>? prefillSchema;
}

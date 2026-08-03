class AiToolCallPlan {
  const AiToolCallPlan({
    required this.toolId,
    required this.route,
    required this.displayName,
    required this.reasonEn,
    required this.reasonTr,
    this.prefillPayload,
    this.prefillSupported = false,
  });

  final String toolId;
  final String route;
  final String displayName;
  final String reasonEn;
  final String reasonTr;
  final Map<String, Object?>? prefillPayload;
  final bool prefillSupported;

  String reason(String languageCode) =>
      languageCode == 'tr' ? reasonTr : reasonEn;
}

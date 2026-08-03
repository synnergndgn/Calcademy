class BillingException implements Exception {
  const BillingException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'BillingException($code)';
}

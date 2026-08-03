enum BillingProductType { subscription }

class BillingProduct {
  const BillingProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.currencyCode,
    this.rawPrice,
    this.type = BillingProductType.subscription,
  });

  final String id;
  final String title;
  final String description;
  final String price;
  final String? currencyCode;
  final double? rawPrice;
  final BillingProductType type;
}

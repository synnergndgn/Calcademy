import 'package:calcademy/app/premium/premium_entitlement.dart';

abstract interface class EntitlementRepository {
  PremiumEntitlement get current;

  Future<PremiumEntitlement> refresh();

  void setEntitlement(PremiumEntitlement entitlement);
}

import 'package:calcademy/app/premium/premium_entitlement.dart';

abstract interface class EntitlementRepository {
  PremiumEntitlement get current;

  void setEntitlement(PremiumEntitlement entitlement);
}

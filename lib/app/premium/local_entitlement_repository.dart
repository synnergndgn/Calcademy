import 'package:calcademy/app/premium/entitlement_repository.dart';
import 'package:calcademy/app/premium/premium_entitlement.dart';

class LocalEntitlementRepository implements EntitlementRepository {
  LocalEntitlementRepository({
    PremiumEntitlement initialEntitlement = const PremiumEntitlement.free(),
  }) : _current = initialEntitlement;

  PremiumEntitlement _current;

  @override
  PremiumEntitlement get current => _current;

  @override
  void setEntitlement(PremiumEntitlement entitlement) {
    _current = entitlement;
  }
}

import 'package:calcademy/app/premium/purchase_validation_request.dart';
import 'package:calcademy/app/premium/purchase_validation_result.dart';

abstract interface class EntitlementSyncService {
  Future<PurchaseValidationResult> validateAndSync(
    PurchaseValidationRequest request,
  );
}

class PendingEntitlementSyncService implements EntitlementSyncService {
  const PendingEntitlementSyncService();

  @override
  Future<PurchaseValidationResult> validateAndSync(
    PurchaseValidationRequest request,
  ) async => const PurchaseValidationResult.unsupported();
}

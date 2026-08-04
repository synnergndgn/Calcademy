import 'package:calcademy/app/premium/purchase_validation_request.dart';
import 'package:calcademy/app/premium/purchase_validation_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class SupabaseEntitlementSyncService implements EntitlementSyncService {
  const SupabaseEntitlementSyncService(this._client);

  final SupabaseClient _client;

  @override
  Future<PurchaseValidationResult> validateAndSync(
    PurchaseValidationRequest request,
  ) async {
    if (_client.auth.currentUser == null) {
      return const PurchaseValidationResult.rejected();
    }
    try {
      final response = await _client.functions.invoke(
        'validate-play-purchase',
        method: HttpMethod.post,
        body: {
          'productId': request.productId,
          'purchaseToken': request.purchaseToken,
          'platform': 'google_play',
        },
      );
      if (response.status < 200 || response.status >= 300) {
        return const PurchaseValidationResult.error();
      }
      final data = response.data;
      if (data is! Map) return const PurchaseValidationResult.error();
      return switch (data['status']) {
        'active' => const PurchaseValidationResult.active(),
        'pending' => const PurchaseValidationResult.pending(),
        'rejected' => const PurchaseValidationResult.rejected(),
        'unsupported' => const PurchaseValidationResult.unsupported(),
        _ => const PurchaseValidationResult.error(),
      };
    } on FunctionException {
      return const PurchaseValidationResult.error();
    } catch (_) {
      return const PurchaseValidationResult.error();
    }
  }
}

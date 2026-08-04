import 'package:calcademy/app/premium/entitlement_repository.dart';
import 'package:calcademy/app/premium/entitlement_status_dto.dart';
import 'package:calcademy/app/premium/premium_entitlement.dart';
import 'package:calcademy/app/premium/premium_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef EntitlementStatusFetcher = Future<Object?> Function();
typedef SignedInUserCheck = bool Function();

class BackendEntitlementRepository implements EntitlementRepository {
  BackendEntitlementRepository(
    this._client, {
    this.fetchStatus,
    this.hasSignedInUser,
  });

  final SupabaseClient _client;
  final EntitlementStatusFetcher? fetchStatus;
  final SignedInUserCheck? hasSignedInUser;
  PremiumEntitlement _current = const PremiumEntitlement.free();

  @override
  PremiumEntitlement get current => _current;

  @override
  Future<PremiumEntitlement> refresh() async {
    final signedIn =
        hasSignedInUser?.call() ?? _client.auth.currentUser != null;
    if (!signedIn) {
      _current = const PremiumEntitlement.free();
      return _current;
    }
    try {
      final statusFetcher = fetchStatus;
      final response = statusFetcher != null
          ? await statusFetcher()
          : await _client.rpc<Object?>('get_my_premium_status');
      _current = EntitlementStatusDto.fromResponse(response).toEntitlement();
    } catch (_) {
      _current = const PremiumEntitlement.free(
        status: PremiumStatus.unknown,
        source: EntitlementSource.backend,
      );
    }
    return _current;
  }

  @override
  void setEntitlement(PremiumEntitlement entitlement) {
    _current = entitlement;
  }
}

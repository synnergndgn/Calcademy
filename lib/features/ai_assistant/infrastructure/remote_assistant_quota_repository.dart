import 'package:calcademy/app/premium/usage_limit.dart';
import 'package:calcademy/app/premium/usage_quota.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads the caller's remaining remote-assistant allowance.
///
/// This is display only. The allowance that actually governs a request is
/// reserved server-side by `consume_ai_usage_quota`, so a stale or missing
/// value here can never grant an extra request.
abstract interface class RemoteAssistantQuotaRepository {
  Future<UsageQuota?> fetch();
}

class SupabaseRemoteAssistantQuotaRepository
    implements RemoteAssistantQuotaRepository {
  const SupabaseRemoteAssistantQuotaRepository(this._client);

  static const featureName = 'gemini_assistant';

  final SupabaseClient _client;

  @override
  Future<UsageQuota?> fetch() async {
    if (_client.auth.currentUser == null) return null;
    try {
      final response = await _client.rpc<Object?>(
        'get_my_usage_quota',
        params: {'p_feature': featureName},
      );
      return parseRpcResponse(response);
    } catch (_) {
      return null;
    }
  }

  /// `get_my_usage_quota` returns a zero limit when today's window has no row
  /// yet, which would otherwise read as "no requests left" to a user who has
  /// not made one. Treat that shape as "unknown" and let the caller supply the
  /// plan default instead.
  static UsageQuota? parseRpcResponse(Object? response) {
    final row = response is List
        ? (response.isEmpty ? null : response.first)
        : response;
    if (row is! Map) return null;
    final used = row['used_count'];
    final limit = row['limit_count'];
    if (used is! int || limit is! int) return null;
    if (limit <= 0) return null;
    return UsageQuota(
      feature: UsageFeature.geminiAssistant,
      dailyLimit: limit,
      usedToday: used,
      resetsAt: _parseResetsAt(row['period_end']),
    );
  }

  static DateTime _parseResetsAt(Object? value) {
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed != null) return parsed;
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day + 1);
  }
}

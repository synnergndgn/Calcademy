/// Why a remote assistant call did not produce an answer.
///
/// Every value falls back to the local rule-based pipeline; the distinction
/// only controls which notice the user sees alongside that local answer.
enum AiRemoteFailure {
  /// Supabase is not configured, the user is signed out, or remote assistance
  /// has not been consented to. No request was attempted.
  notAttempted,

  /// The account has no active Premium entitlement.
  premiumRequired,

  /// The account's daily remote allowance is spent.
  quotaExceeded,

  /// Transport error, provider outage, or an unusable provider response.
  unavailable;

  String? get messageKey => switch (this) {
    AiRemoteFailure.notAttempted => null,
    AiRemoteFailure.premiumRequired => 'aiAssistantRemotePremiumRequired',
    AiRemoteFailure.quotaExceeded => 'aiAssistantRemoteQuotaExceeded',
    AiRemoteFailure.unavailable => 'aiAssistantRemoteUnavailable',
  };
}

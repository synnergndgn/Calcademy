# Play Billing backend validation

## Trust boundary

A Flutter purchase update is evidence to validate, not an entitlement. The app
must never durably enable Premium from `PurchaseDetails` alone.

The target flow is:

1. The signed-in app receives a purchase token from Google Play.
2. It sends the token, product ID, platform, and authenticated user context to a
   Supabase Edge Function over TLS.
3. The Edge Function verifies the Supabase JWT and uses a server-held Google
   service account to call the Google Play Developer API.
4. The function verifies package name, product ID, purchase state, expiry,
   acknowledgement state, and account association.
5. A server transaction upserts the subscription and derived entitlement.
6. The app refreshes entitlement state from the backend. Only an active backend
   entitlement unlocks durable Premium features.

## 1.6 implementation boundary

`EntitlementSyncService` and its request/result models establish the client
interface. The default implementation returns `unsupported`, leaving the UI in
**purchase received / validation required** state. It does not activate Premium.
The token exists in memory only while handling the purchase: it is not logged,
written to preferences, or stored in plaintext on the device.

No Google service-account material, Play Developer API credential, or Supabase
service-role credential belongs in the app bundle or repository. Secrets must
be stored only in the Edge Function's managed server environment.

## Server design

- Require a valid Supabase access token and derive the user ID server-side.
- Accept only allow-listed product IDs and the expected Android package name.
- Make validation idempotent using the purchase token's server-side digest or a
  provider transaction identifier; encrypt sensitive values when retention is
  necessary.
- Restrict table writes to the service function. Clients receive read-only
  entitlement access through row-level security scoped to their user ID.
- Record validation outcome and expiry without returning or logging the token.
- Re-check subscriptions on app refresh and on lifecycle events.
- Revoke access for expiry, cancellation, refund, chargeback, account hold, or
  revoked purchases.

## Acknowledgement and completion

The client calls the plugin's `completePurchase` after handing the token to the
validation interface, even when the 1.6 stub cannot grant an entitlement. This
prevents test transactions from remaining unfinished and being automatically
refunded. The production Edge Function should validate first and coordinate
acknowledgement idempotently. A failed completion remains an error and must be
retried; Google Play can refund unacknowledged purchases after its deadline.

Before production subscription sales are enabled, replace the stub, test
validation and acknowledgement together, and define recovery for a successful
charge whose validation request was interrupted.

## Refunds, cancellations, and RTDN

The durable entitlement source is backend state, never a cached client flag.
The next backend sprint should add Real-time Developer Notifications (RTDN) via
Google Cloud Pub/Sub, verify every notification again through the Developer
API, update subscription/entitlement rows, and periodically reconcile active
subscriptions. Cancellation normally retains access until expiry; refunds,
revocations, and expired subscriptions must remove access according to the
verified server state.

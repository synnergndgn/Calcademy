# Play Billing backend validation

## 1.7 trust boundary

A Flutter purchase update is evidence to validate, not an entitlement. A local
`purchased` or `restored` state never durably enables Premium. Remove Ads is
enabled only by an explicit active/grace-period backend entitlement or an
injected test/mock entitlement.

The current flow is:

1. A signed-in Android client receives a Google Play purchase token in memory.
2. With Supabase configured, it invokes the authenticated
   `validate-play-purchase` Edge Function with the product ID, token, and
   `google_play` platform value.
3. The function derives the user from the bearer JWT, hashes the token with
   SHA-256, and writes safe validation audit events through its server-only
   environment.
4. The 1.7 stub returns `unsupported` and does not call Google or write an
   active entitlement.
5. The app shows Purchase received / Backend validation pending and remains
   Free. A future `active` response triggers a new account entitlement read;
   the response itself still does not unlock Premium.

Signed-out purchases are not sent for validation. Missing Supabase config,
function errors, rejected requests, and unknown backend states all fail closed.

## Token and credential handling

- The full purchase token is neither logged nor echoed.
- The database has no plaintext `purchase_token` column.
- Audit/purchase correlation uses a SHA-256 token hash.
- The full token exists only in request/client memory while the call is active.
- The Supabase privileged key is read only from the Edge Function environment.
- No Google service-account JSON, private key, Developer API key, or external
  payment URL is present in the repository or client.

## Function contract

- `OPTIONS` returns 204 with CORS headers.
- Non-POST methods return 405.
- Missing/invalid bearer authentication returns 401.
- Invalid JSON, product ID, token, or platform returns 400.
- A valid authenticated request records safe audit metadata and returns:

```json
{
  "success": false,
  "status": "unsupported",
  "message": "Backend validation is not enabled yet."
}
```

The function keeps the platform JWT gate enabled and also verifies/derives the
caller explicitly with `auth.getUser` inside the handler.

## Next validation sprint

The production implementation must use a server-held Google service account
and the Google Play Developer API to verify package name, product/base-plan,
purchase state, account association, expiry, acknowledgement, cancellation,
refund, and revocation. It must update `subscription_purchases` and
`premium_entitlements` transactionally and idempotently before returning an
active result.

Real-time Developer Notifications (RTDN) should terminate at an authenticated
Google Cloud Pub/Sub push endpoint. Every notification must be treated as a
signal to re-query Google, never as trusted entitlement data. Add idempotency,
replay protection, dead-letter handling, periodic reconciliation, and tests for
grace period, cancellation-at-period-end, expiry, refund, revoke, and account
hold. Do not log the notification's purchase token.

## Deployment

```powershell
npx supabase@2.111.0 db push
npx supabase@2.111.0 functions deploy validate-play-purchase
```

Staging deployment was completed on 2026-08-05; the migration is applied and the
function is `ACTIVE` with `verify_jwt: true`. See the deployment record in
`docs/supabase_entitlement_schema.md`.

Merchant profile verification, Play subscription product creation, and real
sandbox purchase testing remain pending, so the end-to-end purchase path has
still never been exercised.

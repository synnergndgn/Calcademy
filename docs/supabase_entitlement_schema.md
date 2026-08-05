# Supabase entitlement schema

Calcademy 1.7 adds the database foundation for account-scoped Premium access.
The schema is defined in
`supabase/migrations/20260804111930_entitlement_backend_foundation.sql`.
It does not enable Google Play Developer API validation by itself.

## Tables

### `profiles`

One row per `auth.users` record. The Auth trigger copies only the user ID and
email. Deleting the Auth user cascades to the profile. Authenticated users can
select and update only their own row; inserts are owned by the Auth trigger.

### `premium_entitlements`

One current row per user. Supported states are `inactive`, `active`,
`grace_period`, `expired`, `canceled`, `revoked`, and `pending_validation`.
Supported sources are `google_play`, `manual`, `test`, and `unknown`.
Authenticated clients have owner-scoped `SELECT` only. Only trusted backend
code can insert, update, or delete entitlement rows.

### `subscription_purchases`

Stores the backend view of a Google Play subscription. It stores a SHA-256
`purchase_token_hash` and optional non-secret last four characters, never a
plaintext purchase-token column. Authenticated clients have owner-scoped
`SELECT` only; writes are backend-only.

### `purchase_validation_events`

Backend-only audit trail for receipt, validation, entitlement update,
acknowledgement, and rejection events. Authenticated and anonymous clients have
no table privileges and no read policy. Messages must remain allow-listed and
must never contain a purchase token, access token, private key, or credential.

### `usage_quotas`

Future account-scoped quota windows for Gemini/camera features. Users may read
their own quota state but cannot change counters or limits. No Gemini API,
camera permission, OCR, or remote inference is enabled by this migration.

## RLS and privileges

RLS is enabled on every table in the exposed `public` schema. Policies use
`TO authenticated` plus `(select auth.uid())` ownership checks. Profile update
uses both `USING` and `WITH CHECK`. The audit table deliberately has no client
policy. Data API privileges are explicitly revoked before the minimum required
`SELECT` or profile `UPDATE` grants are added.

Backend writes use the Supabase server environment only. The service-role key
must never be added to Flutter code, build arguments, repository files, logs,
or client responses.

## Helper functions

- `set_updated_at()` maintains mutable row timestamps.
- `handle_new_user()` is a narrowly scoped `SECURITY DEFINER` Auth trigger with
  an empty `search_path`; direct execution is revoked from client roles.
- `get_my_premium_status()` is `SECURITY INVOKER`, observes RLS, and returns only
  `is_premium_active`, `status`, `source`, `product_id`,
  `current_period_end`, and `cancel_at_period_end`.

An `active` or `grace_period` row whose period end is already past does not
produce `is_premium_active = true`.

## Apply to staging

After reviewing the linked project and taking a database backup when required:

```powershell
npx supabase@2.111.0 db push
npx supabase@2.111.0 functions deploy validate-play-purchase
```

## Staging deployment record — 2026-08-05

Applied to the linked `Calcademy Staging` project.

| Check | Result |
| --- | --- |
| Migration `20260804111930` | Applied; `migration list` shows matching local and remote entries |
| `validate-play-purchase` | Deployed, `ACTIVE`, `verify_jwt: true` |
| `delete-account` | Still `ACTIVE`, unchanged |
| Function `OPTIONS` | 204 |
| Function `GET` / `POST` unauthenticated | 401 at the platform JWT gate, before the handler |
| Anonymous `SELECT` on `profiles`, `premium_entitlements`, `subscription_purchases`, `purchase_validation_events`, `usage_quotas` | All denied with `42501 permission denied` — the Data API grants are revoked for `anon` |
| Anonymous `get_my_premium_status()` | `42501 permission denied for function` |
| `handle_new_user()` | Not exposed through the Data API |

**Still pending, and not verifiable from the repository:** the two-account
authenticated RLS check (each account reads only its own rows, cannot write any
backend-owned table, and cannot read `purchase_validation_events`) and the
Supabase database advisors run. Both need operator-created staging test accounts
and dashboard access.

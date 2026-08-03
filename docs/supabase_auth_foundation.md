# Supabase Auth and Staging Foundation — 1.5.0+14

Calcademy supports optional Supabase email/password Auth while remaining usable
without an account. Runtime configuration comes only from `SUPABASE_URL` and
`SUPABASE_ANON_KEY` dart defines. Missing or invalid configuration skips
initialization, leaves auth actions disabled, and does not crash the app.

## Implemented flows

- sign-up with loading, validation, safe errors, and email-confirmation notice;
- sign-in with invalid-credential and unconfirmed-email feedback;
- password-reset email request with safe success/error feedback;
- sign-out and persisted-session restoration through `supabase_flutter`;
- signed-in email on Account and Premium;
- authenticated account deletion through the `delete-account` Edge Function.

Email confirmation is handled correctly: a successful sign-up response without
a Session remains signed out until confirmation and a later sign-in.

## Security model

- The mobile app receives only a publishable/legacy anon public key.
- The service-role credential exists only in the hosted function environment.
- Account deletion accepts no client-provided user ID; Auth resolves it from the
  Bearer token.
- User-editable metadata is not used for authorization.
- No `.env`, real URL/key, project ref, signing key, or local configuration is
  committed.
- `supabase_flutter` and the Edge Function SDK are pinned; lock/config files are
  committed where the installed runtimes permit them.

No exposed data tables are added in this sprint. Future public-schema tables
must have explicit grants, RLS, owner-scoped policies, and deletion coverage.

## Operations

- Setup: [supabase_staging_setup.md](supabase_staging_setup.md)
- Manual validation: [auth_manual_test_runbook.md](auth_manual_test_runbook.md)
- Deletion design: [account_deletion.md](account_deletion.md)
- Public deletion page: [account_deletion_request.md](account_deletion_request.md)

Play Billing, real premium entitlement, Gemini, camera/OCR, cloud Saved sync,
and global login gating remain intentionally absent.

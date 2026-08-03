# Calcademy Account Deletion Foundation

## Current 1.4.0+13 behavior

The in-app route `/account/delete` exists and explains that deletion is
irreversible. A signed-in user can review the scope and confirm intent. The
request button remains disabled because the secure backend function is not yet
deployed. Production account creation must remain disabled until both the
backend deletion flow and the public web request page are operational.

Local calculations and local Saved data are not uploaded by this foundation.
Users can delete those records in the app, clear app storage, or uninstall the
app independently of account deletion.

## Required production deletion transaction

The future authenticated Edge Function must:

1. verify a fresh authenticated session and protect the endpoint with rate
   limits and abuse controls;
2. resolve the user ID only from the verified session, never from a caller
   supplied ID;
3. delete or anonymize all user-owned profile, entitlement, quota, and sync
   records covered by the request;
4. remove user-owned Storage objects before deleting the Auth user;
5. delete the Supabase Auth user with server-only privileges;
6. prevent new sessions and account for the remaining lifetime of already
   issued access tokens;
7. return a generic success response and avoid exposing internal identifiers.

The privileged server credential must be stored only as a backend secret. It
must not be shipped in the Flutter application.

## Data expected to be deleted

When those data types exist, deletion must cover:

- Auth identity, email address, sessions, and refresh tokens;
- profile/display-name records;
- server-side premium entitlement and usage-quota records;
- synced Saved/calculation data and user-owned uploads;
- other records whose purpose depends on the deleted account.

Limited security, fraud-prevention, transaction, tax, or legal records may be
retained only where necessary, for a documented period, with access controls
and data minimization. Retention must not be used as a substitute for deleting
the account.

## Release prerequisites

- Deploy and test the deletion Edge Function against a non-production project.
- Test partial-failure recovery and idempotent retries.
- Publish and verify the public account-deletion URL.
- Link the exact URL in Play Console and the privacy policy.
- Update Data Safety for email, user ID, and any synced data.
- Verify deletion removes associated user data, not merely account access.
- Recheck current Google Play User Data and account-deletion requirements.

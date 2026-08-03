# Account Deletion — 1.5.0+14

## Behavior

- With no Supabase runtime config, account controls remain disabled and the app
  continues to open normally.
- A signed-out user is directed to sign in.
- A signed-in user must explicitly select the confirmation checkbox.
- The Flutter client invokes `delete-account` with `POST`; Supabase attaches the
  current session token.
- On `{ "success": true }`, the client clears its local session, returns to the
  Account page, and shows a completion message.
- Safe, localized errors are shown without server or credential details.

## Security boundary

`supabase/functions/delete-account/index.ts` rejects non-POST calls and missing
Bearer credentials. It validates the token through Supabase Auth, derives the
caller ID from the verified user, and passes only that ID to the Auth Admin
delete API. No user ID supplied by the client is accepted.

The privileged `SUPABASE_SERVICE_ROLE_KEY` is read only from the hosted function
environment. It is never compiled into Flutter. Supabase documents this legacy
variable as automatically provided to hosted functions; custom secret names
cannot use the reserved `SUPABASE_` prefix.

Auth user deletion does not retroactively invalidate a previously issued JWT.
The client removes its session after success, and staging should use an
appropriately short JWT expiry. Any future security-sensitive cloud API should
also validate the JWT `session_id` against active Auth sessions.

## Related data

No Calcademy cloud data tables exist in 1.5. Before cloud sync or remote premium
services launch, deletion must cover `profiles`, `subscriptions`,
`usage_limits`, `ai_requests`, and `saved_cloud_items` using owner-scoped
deletes or tested `ON DELETE CASCADE` relationships. The function contains a
guard comment at the exact insertion point; shipping any of these tables without
implementing cleanup is blocked.

Local Saved content remains on the device and can be removed by clearing app
data or uninstalling Calcademy.

## Play web link

Publish and verify:

`https://synnergndgn.github.io/Calcademy/account_deletion_request`

Source: [account_deletion_request.md](account_deletion_request.md).

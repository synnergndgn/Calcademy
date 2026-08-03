# Supabase Staging Setup — Calcademy 1.5

This runbook intentionally contains placeholders only. Never commit a real
project URL, public key, project ref, access token, `.env`, or privileged key.

## 1. Create and configure staging

1. Create a dedicated staging project in the Supabase Dashboard.
2. From **Connect** or **Settings → API Keys**, copy the Project URL and a
   publishable key. A legacy anon key remains supported by the current app input
   name.
3. In **Authentication → Providers**, enable Email.
4. In **Authentication → URL Configuration**, set Site URL to the public
   Calcademy site or privacy page. Add only verified redirect URLs. A future app
   deep link for password recovery must be allow-listed before use.
5. Choose the email-confirmation mode:
   - enabled (hosted-project default): sign-up succeeds without a session and
     the user must confirm email before sign-in;
   - disabled for controlled staging only: sign-up returns a session directly.
6. Keep the Auth JWT expiry short enough for the project's risk profile because
   already-issued access tokens remain valid until expiry after sign-out or user
   deletion.

## 2. Run the app

No-config mode:

```powershell
flutter run
```

Staging mode:

```powershell
flutter run --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<publishable-or-anon-key>
```

Release example:

```powershell
flutter build appbundle --release --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<publishable-or-anon-key>
```

The command line and resulting artifact can expose a public key, so handle build
logs and artifacts as release material. Public/anon keys are not privileged,
but database access must still be protected by grants and RLS.

## 3. Link and deploy the Edge Function

Install the current Supabase CLI using the official instructions, then discover
the installed command shape rather than relying on memory:

```powershell
supabase --version
supabase --help
supabase functions --help
supabase functions deploy --help
supabase link --project-ref <project-ref>
supabase functions deploy delete-account
```

Hosted Edge Functions automatically receive `SUPABASE_URL` and the legacy
`SUPABASE_SERVICE_ROLE_KEY`, along with the newer publishable/secret-key maps.
Do **not** run `supabase secrets set SUPABASE_SERVICE_ROLE_KEY=...`: Supabase
reserves the `SUPABASE_` prefix and provides that variable itself. Confirm its
presence by name in **Edge Functions → Secrets** without copying or logging its
value. For local serving, use an ignored local env file and never commit it.

The function dependency is exactly pinned in
`supabase/functions/delete-account/deno.json`.

## 4. Verify staging

Follow [auth_manual_test_runbook.md](auth_manual_test_runbook.md). Confirm that:

- sign-up, email confirmation, sign-in, restart persistence, sign-out, and reset
  email delivery match the selected staging settings;
- an unauthenticated or non-POST function call fails;
- a signed-in user can delete only their own account;
- sign-in fails after deletion;
- local tools still work before and after auth tests.

No staging project values are stored in this repository. Live verification
therefore requires an operator-supplied staging project at run time.

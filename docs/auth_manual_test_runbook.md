# Auth Manual Test Runbook — 1.5.0+14

Record the device, OS, commit, staging project, email-confirmation setting, and
result for every run. Use disposable staging accounts and never paste secrets
into the report.

## A. No Supabase config

1. Run `flutter run` without Supabase dart defines.
2. Confirm the app opens and Home renders.
3. Open Settings → Account, Sign in, Create account, and Delete account.
4. Confirm the config-missing notice is visible and network actions are disabled.
5. Use Calculator, Saved, Formula Library, and the local AI Assistant.
6. Confirm none requires login and Camera Solver requests no camera permission.

## B. Staging config

```powershell
flutter run --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<publishable-or-anon-key>
```

1. Create an account with email/password and observe the loading state.
2. If confirmation is enabled, confirm the app stays signed out, shows the
   check-email notice, and allows sign-in only after the email link is used.
3. Sign in. Verify the Account and Premium pages show the account email.
4. Fully stop and restart the app. Verify the persisted session is restored.
5. Sign out and verify Account returns to signed-out state.
6. Enter the account email on Sign in and request password reset. Verify a
   generic success message and receipt of the staging email. Verify the link
   target matches the Dashboard URL configuration; an in-app change-password
   deep link is not part of 1.5.
7. Sign in again, open Delete account, and verify the button is disabled until
   confirmation is selected.
8. Delete the account. Verify the success message, local sign-out, and return to
   Account.
9. Try to sign in again. It must fail because the Auth user no longer exists.
10. Verify local Saved data remains until app data is cleared or the app is
    uninstalled.
11. Repeat a core-tool smoke test while signed out.

## Negative function checks

Use the deployed staging endpoint without recording tokens:

- `GET` returns 405 JSON;
- `POST` without Authorization returns 401 JSON;
- authenticated `POST` returns 200 `{ "success": true }` for the caller only;
- errors contain short codes and no stack trace, key, token, email, or user ID.

Review Edge Function logs for status and request correlation only. Never log
Authorization headers or environment values.

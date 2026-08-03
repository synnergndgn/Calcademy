# Supabase Auth Foundation — 1.4.0+13

## Scope

Calcademy 1.4 adds an optional Supabase Flutter Auth client boundary. Core
calculators, Formula Library, the local Assistant, and local Saved data remain
available without an account. The app has no global authentication redirect.

This release does not add Play Billing, Gemini, camera/OCR, cloud saved-data
sync, or a production account-deletion backend.

## Runtime configuration

The client reads only these compile-time values:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
```

Example development launch:

```sh
flutter run --dart-define=SUPABASE_URL=https://project-ref.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-publishable-client-key
```

No `.env` file is required or committed. If either value is absent, the URL is
not public HTTPS, or initialization fails, Calcademy starts normally with the
local signed-out repository. Auth screens then show **Auth is not configured
yet** and disable network auth actions.

Only a public anon/publishable client key belongs in a mobile build. A Supabase
service role key is a privileged server credential and must never be embedded
in Calcademy.

## Architecture

- `AppConfig` validates the two `--dart-define` values.
- `main.dart` initializes Supabase only when the configuration is valid.
- `AuthRepository` defines session, email/password, reset, sign-out, and
  deletion boundaries.
- `SupabaseAuthRepository` maps Supabase users and auth-state events to app
  domain types.
- `LocalAuthRepository` is the config-missing and test fallback.
- `AuthController` exposes immutable Riverpod state to account and premium UI.
- `/account`, `/sign-in`, `/create-account`, and `/account/delete` are optional
  routes and do not gate core routes.

Email/password is the only remote auth method in this foundation. OAuth, magic
links, profile sync, and deep-link recovery handling are future work.

## Account deletion boundary

Supabase Auth user deletion is an administrative operation. The mobile client
does not call it. Both repositories report deletion as unsupported until an
authenticated, rate-limited Edge Function can delete related user data, remove
the Auth user, record only legally required audit evidence, and return a safe
result. See [account_deletion.md](account_deletion.md).

## Premium connection

Signed-out and newly signed-in users receive the free runtime entitlement.
There is no backend entitlement sync yet. The existing injected mock premium
entitlement remains available to automated tests, while production defaults to
free. Premium and AI gate sign-in actions now open the auth routes.

## Security checklist

- No privileged Supabase credential in client code or documentation examples.
- No real endpoint or client key committed.
- No direct administrative user-deletion call from Flutter.
- No Play purchase token storage.
- No Gemini or other AI provider key.
- Dependency version is pinned and `pubspec.lock` is committed.

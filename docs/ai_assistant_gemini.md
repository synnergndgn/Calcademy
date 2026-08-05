# Gemini-backed assistant

Calcademy 1.8 adds an optional remote assistant. It is the first feature that
sends user-typed text off the device, so it is opt-in, account-scoped,
Premium-gated, quota-limited, and always falls back to the existing local
rule-based pipeline.

## Four gates, all required

A question can leave the device only when **all** of the following hold. Any one
of them failing keeps the assistant entirely local:

1. the build was compiled with Supabase runtime config;
2. the user is signed in;
3. the account's backend entitlement grants `PremiumFeature.geminiAssistant`;
4. the user has explicitly turned on **Advanced assistant (Gemini)**.

`canUseRemoteAssistantProvider` is the single place this is decided, and it is
re-evaluated per request. A sign-out, a lapsed subscription, or a withdrawn
consent takes effect on the next message with no restart.

Consent defaults to off on every install and is stored in
`settings.remoteAssistant`. It is offered in the assistant page only to accounts
that could actually use the feature, and can be withdrawn at any time from
Settings.

## Request path

```
Flutter → ai-assist Edge Function → Gemini API
```

The client never holds the Gemini key and never contacts Google directly. The
key exists only in the function's environment, set with
`supabase secrets set GEMINI_API_KEY=...`.

The function, in order:

1. rejects non-POST and unauthenticated calls;
2. validates the body — non-empty prompt, at most 1000 characters, language code
   in `en`/`tr`;
3. derives the caller from the bearer JWT with `auth.getUser`;
4. reads `premium_entitlements` and refuses without an active or grace-period
   entitlement inside its period;
5. reserves one quota unit **before** calling Gemini;
6. calls Gemini with a 20-second timeout;
7. sanitizes the response;
8. returns the plan plus the caller's remaining quota.

## Quota

`consume_ai_usage_quota(user, feature, limit)` performs the reservation as a
single `insert … on conflict do update … where used_count < limit_count`. The
guard lives in the statement, so concurrent requests cannot both pass a check
and then both spend a unit — the counter can never exceed the limit. The window
is the UTC day, derived in SQL so client and backend cannot disagree about the
boundary.

`release_ai_usage_quota` returns the unit when Gemini never produced a usable
answer, so an upstream outage does not cost the user part of their allowance.

The Premium allowance is 20 requests per UTC day. Free accounts get zero, which
is enforced by the entitlement check before quota is even consulted.

## Prompt-injection and output handling

The user's text is sent as its own `user` turn and is never concatenated into
the system instruction. The system instruction states that the user turn is
untrusted problem data and that attempts inside it to change the assistant's
role, extract the instructions, or leave Calcademy's scope must be ignored.

Model output is treated as untrusted too, and is filtered twice:

| Field | Server rule | Client rule |
| --- | --- | --- |
| `intent` | must be one of the 13 known intents, otherwise `unsupported` | re-mapped, unknown → `unsupported` |
| `toolIds` | must be in the 11-ID allow-list | must resolve through `CalcademyToolRegistry` |
| `formulaIds` | must match the slug shape, max 3 | must resolve through `FormulaRegistry` |
| `summary` | capped at 1200 characters | — |
| `steps` | max 8, each capped at 400 characters | — |

Routes are never taken from the response. The client maps an allow-listed ID to
a route it already knows, so a model that emits a URL or a path cannot make the
app navigate anywhere. `unsupported` and `outOfScope` answers are stripped of
every tool and formula suggestion on both sides.

## Failure behavior

Every failure degrades to the local pipeline and shows why:

| Condition | Result |
| --- | --- |
| Gate closed | Local answer, no notice, no request sent |
| 403 no Premium | Local answer + "requires Premium" notice |
| 429 quota spent | Local answer + "allowance used up" notice |
| Timeout, 5xx, transport error, unusable response | Local answer + "unreachable" notice |

The user always receives an answer. Nothing about the failure path can leave the
assistant unusable.

## What is stored

`ai_assistant_events` is backend-only — no client role holds any privilege on
it and it has no RLS policy. It records the user ID, event type, model name,
resolved intent, character counts, latency, and an allow-listed reason string.

It must never contain prompt text, model output, an API key, or a token. An
audit write failure is swallowed and never fails the user's request. A test
asserts that no recorded event carries the prompt or the answer.

Calcademy stores no conversation. Assistant messages remain in in-memory
Riverpod state and are lost when the page is disposed.

## Deployment

```powershell
npx supabase@2.111.0 db push
npx supabase@2.111.0 secrets set GEMINI_API_KEY=<key>
npx supabase@2.111.0 functions deploy ai-assist
```

### Staging status — 2026-08-05

| Step | State |
| --- | --- |
| Migration `20260805094500_ai_assistant_quota_and_audit` | Applied to `Calcademy Staging` |
| Anonymous `SELECT` on `ai_assistant_events` | Denied, `42501` |
| Anonymous `consume_ai_usage_quota` / `release_ai_usage_quota` / `current_usage_period_start` | Denied, `42501` |
| Anonymous `get_my_usage_quota` | Denied, `42501` — granted to `authenticated` only |
| `GEMINI_API_KEY` secret | **Not set** — operator step |
| `ai-assist` function deploy | **Not deployed** — pointless until the key exists |

Until the secret is set and the function is deployed, every client falls back to
local mode, which is the intended safe default. Nothing in the app is broken by
this state.

**Not yet verified:** `consume_ai_usage_quota` has never been *executed*. The
migration applies cleanly and the privilege model is confirmed, but PL/pgSQL
compiles a function body on first call, so runtime errors would not have
surfaced yet. Executing it needs a real `auth.users` row because `usage_quotas`
carries a foreign key to it. First check after creating a staging test account:

- call it 21 times for that user and confirm the 21st returns
  `allowed = false` with `used_count` stuck at 20;
- call `release_ai_usage_quota` and confirm the counter drops by exactly one and
  never goes below zero;
- confirm a second account's counter is unaffected throughout.

`GEMINI_MODEL` optionally overrides the default `gemini-2.5-flash`. Verify the
model ID against current Google documentation before deploying; the function
treats an unknown model as a provider failure and falls back, so a wrong value
degrades quietly rather than erroring loudly.

Without `GEMINI_API_KEY` the function returns 502 and every client falls back to
local mode, which is the correct fail-closed posture but means a missing secret
looks exactly like an outage. Check the secret first when the advanced
assistant never seems to engage.

## Privacy and Data Safety consequence

This feature changes Calcademy's Data Safety answers. Once a user opts in, text
they type is transmitted to Google as a service provider. `privacy_policy.md`
and `data_safety_draft.md` are updated accordingly and must be re-reviewed
before the first release that ships this enabled.

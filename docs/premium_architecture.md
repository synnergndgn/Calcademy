# Premium Architecture Foundation — 1.3.0+12

> **1.4.0+13 Auth connection:** Supabase email auth is now available only when
> valid runtime configuration is supplied. Account, sign-in, create-account,
> and deletion routes exist. Core tools remain no-login. Signed-in users remain
> free until a future backend provides a verified premium entitlement. The
> injected mock premium path is retained for tests. Play Billing, Gemini, and
> camera/OCR are still absent.

## Product model

Calcademy remains usable without login. Core calculators, Formula Library,
local Saved data, and the local rule-based Assistant remain available on the
free plan. The 1.3 foundation only models future premium access; it does not
sell a product or create an account.

Planned premium benefits are:

- Gemini-powered Assistant requests;
- Camera Solver and OCR processing;
- removal of Home and Saved banner ads;
- higher daily Gemini and camera quotas.

## Entitlements

`PremiumEntitlement` contains a status, active feature set, optional expiry, and
source. Sources are modeled as local mock, Play Billing, or backend, but only the
local mock repository exists in this build. The safe default is free, with no
premium feature active. Tests can inject a mock premium entitlement.

`PremiumFeatureGate` is the shared authorization decision. UI code must not
infer premium access from a button, account state, or cached plan name.

## Accounts and authentication

`AuthRepository` now has local and Supabase implementations. Supabase is
initialized only with valid runtime URL and anon/publishable configuration;
otherwise the app safely uses the local signed-out implementation. Basic use
never requires an account.

Account, sign-in, create-account, and deletion routes now exist. Real account
deletion remains blocked until a secure Edge Function can delete associated
server data and the Auth user. The public deletion URL must be published before
production account creation is enabled.

## Billing

Google Play Billing is not included. Subscribe and manage-subscription controls
remain disabled placeholders; sign-in and account actions now open the Auth
routes. There are no billing
product IDs, purchase tokens, external checkout links, purchase restoration,
or server-side purchase validation in this build.

A production implementation must use Google Play Billing for Play-distributed
digital subscriptions, validate purchases on a trusted backend, reconcile
renewals/cancellations/refunds, and map verified purchases to entitlements.

## Usage limits

The local usage model is UI/architecture scaffolding, not a security boundary:

| Feature | Free placeholder | Premium placeholder |
| --- | ---: | ---: |
| Local Assistant | Unlimited | Unlimited |
| Gemini Assistant | 0/day | 20/day |
| Camera Solver | 0/day | 10/day |

`LocalUsageLimitService` keeps counters only in memory. Production AI/camera
limits must be enforced atomically by the backend and must not trust device
counters.

## Ads removal

Free and signed-out users keep the existing Home and Saved banner behavior.
When a verified entitlement includes `removeAds`, the shared `AdBanner` returns
zero layout space and does not request an ad. Calculator, Formula Library, AI
Assistant, solver, graph, and other workspaces remain banner-free regardless of
plan.

## Gemini and Camera Solver

The local Assistant remains free and operational. Gemini is represented only by
a locked/coming-soon premium card. Camera Solver is a route and explanatory
placeholder only. This release adds no AI provider call, API key, camera
permission, image picker, OCR/ML Kit dependency, or upload path.

## Privacy and Data Safety

The architecture foundation starts no new collection or sharing. There is no
account data, purchase data, prompt transmission, image capture, OCR input,
backend log, or cloud entitlement record. Existing AdMob disclosures remain in
effect for free Home/Saved banners.

Before enabling any future premium capability, re-evaluate:

- account/profile and account-deletion data flows;
- billing purchase history, identifiers, and backend validation;
- Gemini prompt/response retention and safety controls;
- camera/photo permissions, image processing location, retention, and upload;
- privacy policy, Play Data Safety, consent, and store disclosures.

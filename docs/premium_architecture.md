# Premium architecture — 1.6.0+16

Calcademy remains usable without login. Core calculators, Formula Library,
local Saved data, and the local rule-based Assistant stay on the free plan.
Accounts are required only for subscription actions and future durable Premium
entitlements.

## Product and feature model

The active product model contains the Google Play subscription
`calcademy_premium_monthly`; `calcademy_premium_yearly` is reserved for a later
release and is not queried. Planned benefits are:

- removal of Home and Saved banner ads;
- Gemini-powered Assistant;
- Camera Solver and OCR;
- higher daily Gemini and camera quotas.

Gemini, camera access, OCR, external AI requests, and image upload remain
inactive in 1.6.

## Billing boundary

`BillingRepository` isolates product discovery, purchase launch, purchase
updates, restoration, and completion. `PlayBillingRepository` wraps the
official Flutter `in_app_purchase` plugin and is active only on Android. It
returns a safe unavailable state on iOS, web, desktop, tests without an injected
repository, and devices/builds where the store is unavailable.

`LocalBillingRepository` is an injectable, in-memory test double. It can model
unavailable, pending, successful, canceled, error, and restored flows without a
real transaction.

`BillingController` owns transient UI state. Signed-out users cannot subscribe.
Signed-in users can see a Play product and localized store price when available,
launch Subscribe, restore purchases, and open Google Play subscription
management. No external payment link exists.

## Entitlement trust boundary

A purchase update never grants durable Premium by itself. For a purchased or
restored transaction, the controller:

1. displays purchase received / validating entitlement;
2. passes the in-memory token to `EntitlementSyncService`;
3. completes the plugin transaction when required;
4. waits for a backend entitlement before enabling Premium.

The 1.6 default sync service deliberately returns unsupported. The token is not
logged, persisted to preferences, or treated as proof of access. The next
backend implementation must validate with the Google Play Developer API from a
Supabase Edge Function, update server-side subscription/entitlement tables, and
let the client read that verified state.

`PremiumFeatureGate` remains the only feature authorization decision. Its safe
default is free. The explicit local mock seam remains for automated tests; it
can hide ads and unlock modeled features without becoming a production purchase
path.

## Ads and limits

Free and signed-out users keep the existing banner behavior on Home and Saved.
When a verified backend entitlement—or the explicit test mock—contains
`removeAds`, the shared banner returns zero layout space and does not request an
ad. Calculator, Formula Library, Assistant, Account, and other workspaces remain
banner-free regardless of plan.

Local usage counters are UI scaffolding, not a security boundary. Production
Gemini/camera quotas must be enforced atomically by the backend.

## Privacy and secrets

Google Play processes subscription purchases. A future validation backend will
associate an authenticated account with verified purchase/subscription state.
Service-account material, Supabase service-role credentials, and Play Developer
API credentials must remain server-side. Existing AdMob and optional Supabase
Auth disclosures continue to apply.

See [Play Billing setup](play_billing_setup.md), [backend validation](play_billing_backend_validation.md),
and the [manual test runbook](play_billing_manual_test_runbook.md).

# Premium architecture — 1.7.0+18

Calcademy remains usable without login. Calculator, Formula Library, local
Saved data, and the local rule-based Assistant remain available on the Free
plan. An account is required only for subscription actions and durable Premium
entitlements.

## Sources of truth

Production Premium state comes from the signed-in account's Supabase
entitlement. `BackendEntitlementRepository` calls
`get_my_premium_status()` and maps only `active` and `grace_period` with a valid
period to active Premium. Pending, inactive, expired, canceled, revoked,
signed-out, missing-config, and error states remain Free.

The `LocalEntitlementRepository` is an explicit test seam. Its mock Premium
state may unlock features in automated UI/ad tests, but a normal production
build does not derive entitlement from local purchase state or preferences.

## Billing and validation

`PlayBillingRepository` owns product discovery, purchase launch, restore, and
Play completion. `BillingController` forwards a purchase receipt only when a
user is signed in. `SupabaseEntitlementSyncService` calls the
`validate-play-purchase` function when a configured client exists.

The 1.7 function is a secure unsupported stub: it authenticates, hashes the
token, records audit events, and reports that Google validation is not enabled.
Unsupported/pending/error/rejected responses never unlock Premium. Even a
future active validation response only requests a fresh backend entitlement;
explicit backend state is still required.

## Feature and ad gates

`PremiumGateController` is the shared authority used by feature gates and
`AdBanner`. Home and Saved banners are hidden only when the entitlement grants
`PremiumFeature.removeAds`. These states do not hide ads:

- local Play `purchased` or `restored`;
- pending/unsupported validation;
- signed out or missing Supabase config;
- backend/network errors;
- inactive, expired, canceled, or revoked entitlement.

An active/grace backend entitlement or explicit test mock can hide the Home and
Saved banners. Ad placement remains unchanged elsewhere.

## Deferred features

The schema reserves quota state for later work, but Gemini calls, camera
permission, OCR, image upload, and external payment links remain absent.

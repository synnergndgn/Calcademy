# Monetization Strategy — 1.7.0+18

> **Decided model: freemium.** Core tools stay free and usable without an
> account; ads are shown on Home and Saved only; a Google Play subscription
> removes those ads and is intended to gate future Gemini/camera work. The
> AdMob sections below are retained as the crash post-mortem and the still-open
> ad-release checklist.

## Status

| | `main` today (1.7.0+18) |
|---|---|
| Ads SDK | `google_mobile_ads` 9.0.0 |
| Banner | Home + Saved only |
| Consent (UMP) | **not implemented** — blocks EEA/UK ad delivery |
| Play "Contains ads" | Yes (draft only) |
| Billing | `in_app_purchase` 3.3.0; `calcademy_premium_monthly` planned |
| Merchant account | **not created** — blocks product creation and sandbox purchase |
| Entitlement source | Supabase `get_my_premium_status()`; client purchase state never grants Premium |
| Backend validation | authenticated stub returning `unsupported`; real Play Developer API validation not implemented |

## AdMob crash post-mortem (1.0.0+6)

The history below is kept because the dependency-forcing and R8 keep rules it
describes are still load-bearing in the current build.

## Why 1.0.0+6 crashed

The 1.0.0+5/+6 AdMob integration caused a **native startup crash on real
devices**, before Flutter/Dart ran, so runtime try/catch, feature flags, and a
runApp-first ordering could not prevent it:

```
FATAL EXCEPTION: main
Unable to get provider androidx.startup.InitializationProvider
Caused by: com.google.android.gms.internal.ads...
Caused by: Failed to create an instance of androidx.work.impl.WorkDatabase
```

Root cause, established in the retry sprint by resolving the native dependency
graph:

- `google_mobile_ads` → `com.google.android.gms:play-services-ads:25.3.0`
- → `play-services-ads-api:25.3.0` → **`androidx.work:work-runtime:2.7.0`** (2021)
- → **`androidx.room:room-runtime:2.2.5`** (2020)

`androidx.work` registers `WorkManagerInitializer` with AndroidX Startup, so
WorkManager builds a Room database inside `InitializationProvider.onCreate()` —
during process start, before `main()`. Room resolves the generated
`WorkDatabase_Impl` **and its no-arg constructor** reflectively. The message
`Failed to create an instance of` (as opposed to `cannot find implementation
for`) means the class survived R8 but the constructor did not: Room 2.2.5
predates R8 full mode, which has been mandatory since AGP 8, and its consumer
keep rules do not preserve the constructor under it. This project builds with
AGP 9.0.1 / Gradle 9.1.0 and ships release artifacts with `isMinifyEnabled`.

The 1.0.0+6 ProGuard rules kept `com.google.android.gms.ads.**` and
`com.google.android.ump.**` — the ads SDK — but nothing for the
`androidx.work`/Room classes that actually failed.

## The fix

1. **Force current WorkManager** in `android/app/build.gradle.kts`:
   `androidx.work:work-runtime:2.11.2`, which resolves Room `2.2.5 → 2.7.0`
   and `androidx.sqlite → 2.5.0`.
2. **Explicit R8 keep rules** for Room database constructors and AndroidX
   Startup initializers, alongside the existing ads/UMP keeps.
3. **No ads call before `runApp`.** `lib/main.dart` has no ads import at all;
   `AdBanner` drives `AdService.ensureInitialized()` lazily after first frame,
   so an SDK failure degrades to "no banner", never "no app".

Rejected alternative: removing `androidx.work.WorkManagerInitializer` from the
merged manifest with `tools:node="remove"`. The app itself does not use
WorkManager, but **the ads SDK does**, so suppressing auto-initialization would
leave `WorkManager.getInstance()` throwing `IllegalStateException` later — it
relocates the crash from startup to ad-load rather than removing it. Kept as a
documented fallback only if the dependency fix proves insufficient.

## Consent (UMP) — deliberately deferred

`user-messaging-platform:4.0.0` ships as a native transitive dependency
regardless, but **no Dart-side UMP call is made this sprint**. The goal is to
isolate one variable: AdMob SDK startup stability. Consent must be implemented
before any EEA/UK release, and before the Play data declarations below go live.

## Placement guardrails

- Banner on **Home** and **Saved** only.
- **No** ads on Calculator, Graph, Matrix, Equation Solver, Calculus,
  Statistics, Financial Calculator, or LP/IP/OR input screens.
- No interstitials during expression entry, solving, result reading,
  copy/save, or navigation back from a result.
- Rewarded ads are not a natural fit and must never gate correctness,
  accessibility, or saved data.
- The banner reserves zero height until an ad loads, so it cannot push or clip
  content offline, on small screens, or at 200% text scale.

## Merge gate (historical — branch merged in PR #2)

The gate below was the merge condition for `feature/admob-retry`
(status as of 2026-07-25, Xiaomi 23021RAAEG — see
`docs/admob_retry_device_test.md`). Unchecked lines are still open release
work and are repeated in the checklist that follows.

- [x] Release APK (minify off) opens on a real device.
- [x] Release APK (minify **on**) opens on a real device — the configuration
      that crashed in 1.0.0+6.
- [ ] Release AAB opens from a Play internal test track (split-APK delivery
      path; not yet exercised) — see `docs/play_internal_test_runbook.md`.
      The signed 62.2 MB `app-release.aab` (versionCode 8) is built and
      verified: `WorkDatabase_Impl` is kept unrenamed with its no-arg
      constructor intact in this build's own R8 mapping.
- [x] No `FATAL EXCEPTION`, no `WorkDatabase` failure, no
      `InitializationProvider` failure in logcat.
- [x] App reaches the Home screen; banner serves on Home and Saved; Scientific
      Calculator stays ad-free.
- [x] `flutter analyze` clean and `flutter test` 517/517 green.
- [ ] Play Console declarations and policy docs updated together with the merge.
- [ ] UMP consent implemented (required before any EEA/UK release).

The startup crash is **fixed and verified on device**. The remaining gates are
release-process items, not stability items.

## Remaining release work before an ad-supported launch

- [ ] Implement UMP consent and a privacy-options entry point.
- [ ] Publish and validate `app-ads.txt` on the verified developer domain
      (`docs/app_ads_txt_setup.md`); the publisher id is still `null` in code.
- [ ] Redo the Data Safety form against the exact SDK/version and mediation
      configuration (`docs/data_safety_draft.md`).
- [ ] Flip the Play Ads declaration to **Yes**
      (`docs/play_console_app_content_checklist.md`).
- [ ] Revisit target audience, child-directed treatment, Families eligibility,
      and maximum ad content rating.
- [ ] Review the auto-merged ad permissions: `AD_ID`,
      `ACCESS_ADSERVICES_AD_ID`, `ACCESS_ADSERVICES_ATTRIBUTION`,
      `ACCESS_ADSERVICES_TOPICS`, `WAKE_LOCK`, `FOREGROUND_SERVICE`.
- [ ] Test offline/failure behavior, initialization latency, memory, battery,
      binary size, and accessibility.

## Risks

- Ads can reduce trust and retention in a focused academic workflow.
- Poor placement can cause accidental clicks or obscure critical inputs.
- Advertising SDKs increase binary size, network surface, review complexity,
  and Data Safety obligations.
- Consent state, regional rules, mediation partners, and SDK behavior change
  over time and require ongoing maintenance.
- Monetization must never imply that a numerical result becomes more accurate
  after payment.

## Model decision

**Freemium was chosen.** Every calculation module, the Formula Library, local
Saved data, and the local rule-based Assistant remain free and account-free.
The subscription removes the Home/Saved banners and is the intended gate for
Gemini-backed assistance, camera solving, and higher daily limits once those
exist. Correctness, accessibility, and access to already-saved data are never
gated.

Rejected for now: free-and-ad-free (needs another funding source), one-time
paid (reduces discovery and does not fund recurring inference cost), and
donation-only (uncertain revenue).

## Subscription blockers

1. **Google Payments merchant account is not created.** Without it
   `calcademy_premium_monthly` and its `monthly` base plan cannot exist, so no
   license-tester sandbox purchase can be run. This is an external, account-level
   step and blocks the entire end-to-end billing verification.
2. **Backend validation is a stub.** Real entitlement requires a server-held
   Google service account, `purchases.subscriptionsv2.get`, transactional and
   idempotent writes to `subscription_purchases` and `premium_entitlements`, and
   an authenticated RTDN Pub/Sub endpoint. See
   `docs/play_billing_backend_validation.md`.
3. **Staging deployment is pending** for the entitlement migration and the
   validation function.

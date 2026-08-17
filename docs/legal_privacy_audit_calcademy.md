# Calcademy Legal / Privacy Compliance Audit

> **Post-remediation status — 2026-08-12:** The release application was reduced to offline, accountless + AdMob; Supabase and Play Billing were removed from the dependency graph and release artifact. Android backup and device-transfer extraction are disabled/excluded in verified AAB `1.9.4+28`. The owner reports that Play Console Data Safety has been corrected. The current decision is therefore **PASS WITH FIXES**, pending publication of the corrected Turkish and English live privacy policy. See `docs/release_privacy_remediation_1.9.4_28.md` for the current artifact hash and exact wording. The original findings below are retained as the audit trail for the pre-remediation state.

**Audit date:** 2026-08-11 (Europe/Istanbul)  
**Audited source state:** current working tree, including pre-existing uncommitted changes  
**Current app metadata:** Calcademy `1.9.3+26`, package `com.aligundogan.calcademy`  
**Live privacy policy:** [https://gundev.dev/gizlilik/calcademy](https://gundev.dev/gizlilik/calcademy)  
**Owner-confirmed release profile:** offline, account-free and AdMob-supported; Supabase, account creation/sign-in, subscriptions/Premium, AI Assistant and Camera Solver are not active  
**Assessment type:** static source/configuration review plus inspection of the existing release merged manifest and release artifact records. This is not legal advice and does not verify the current Play Console answers or the artifact actually uploaded to Google Play.

## Executive Summary

Calcademy's calculation and saved-work features are predominantly local-first. Expressions, results, history, saved calculations, graph/matrix/LP/IP workspaces, favorites, notes, timestamps, language, theme, angle mode and other preferences are serialized into `SharedPreferences`. No analytics, Firebase, crash-reporting, remote-config, location, contacts, camera, microphone or OCR implementation was found. The AI Assistant currently uses a local mock service. User-initiated copy/share and external-link actions are present and mostly described accurately.

The current default release plan is an ad-supported build compiled **without** `SUPABASE_URL` and `SUPABASE_ANON_KEY`. In that profile, Supabase is not initialized and account/Premium UI entry points are hidden. AdMob remains active on Home and Saved after the UMP flow. This distinction is important: the source tree also contains functional, configuration-gated Supabase email authentication, account deletion, entitlement RPC calls, Google Play Billing and purchase-token submission to a Supabase Edge Function. Any release built with Supabase defines is a materially different privacy profile and must not ship under the current live policy or current free-build store declarations.

Two release-blocking/high-risk issues were found:

1. Android Auto Backup is left at its default-enabled state. Android's official documentation states that shared-preference files are included by default and may be uploaded to the user's Google Drive. This contradicts the live and repository policies' unqualified claims that stored work remains only on the device, has no cloud copy, and is removed by uninstalling/clearing local storage.
2. The Google Play Data Safety draft incorrectly says **App activity = No** and **App info/performance = No**, while Google's current Mobile Ads SDK disclosure says the SDK automatically collects and shares user-product interactions and diagnostic information, in addition to IP address and device/account identifiers.
The owner confirmed that Supabase, account creation/sign-in, subscriptions/Premium, AI Assistant and Camera Solver are inactive in the release under review. Their source code is therefore treated as dormant/future code, not as current data collection. A build accidentally supplied with Supabase `--dart-define` values would create a different privacy profile, so this remains a release-control finding rather than an active privacy contradiction.

The live policy is also stale: it declares itself current for `1.8.0 (build 20)` while the audited app is `1.9.3+26`. The “Clear saved” action clears only the legacy calculator-saved collection, not all saved-calculation/workspace repositories.

## Final Decision: FAIL

The failure decision follows the requested decision rule: the app's default Android backup configuration can transmit policy-described “device-only” data to system cloud backup without that behavior being disclosed, and the current Data Safety draft omits data types automatically collected/shared by AdMob. Wider release should be blocked until the backup posture, live policy and Play Console Data Safety answers are reconciled against the exact AAB.

This is **not** a finding that Calcademy uploads calculations to its own server, uses accounts, sells subscriptions, calls a remote AI service or accesses the camera in the confirmed release profile. No such active path was found. The failure is caused by Android system backup and incomplete third-party AdMob disclosures.

**Finding count:** Critical `0`, High `2`, Medium `6`, Low `2`, Info `7`.

## App Data Flow Summary

| Data / event | Source | Processing and storage | Leaves device? | Deletion/control | Evidence |
|---|---|---|---|---|---|
| Calculation expressions and results | User input | Calculated locally; history JSON in `SharedPreferences`, capped at 200 records | Not sent by Calcademy feature code; may be included in Android Auto Backup | Individual delete, clear history, clear app storage/uninstall; backup caveat applies | `lib/features/history/data/local_calculation_repository.dart:13-36`; `lib/features/history/presentation/history_controller.dart:15-39` |
| Legacy saved calculations, titles and notes | User | JSON in `calculator.saved` | Same backup caveat | Individual delete and legacy clear | `lib/features/saved/presentation/saved_controller.dart:16-67`; `lib/features/history/data/local_calculation_repository.dart:17-35` |
| Cross-module saved calculations, favorites, payload summaries and timestamps | User/app results | Versioned JSON in `saved_calculations.repository.v1` | Same backup caveat | Individual delete; controller has clear, but Settings does not call this controller | `lib/features/saved_calculations/data/saved_calculations_repository.dart:59-65,125-190`; `lib/features/saved_calculations/presentation/saved_calculations_controller.dart:127-137` |
| Saved graphs | User | Functions, ranges and titles in `graph.saved` | Same backup caveat | Individual delete | `lib/features/graph/data/graph_repository.dart:47-79`; `lib/features/graph/domain/saved_graph.dart:28-36` |
| Saved matrices | User | Inputs, results, parameters and timestamps in `matrix.saved` | Same backup caveat | Individual delete | `lib/features/matrix/data/matrix_repository.dart:48-81`; `lib/features/matrix/domain/saved_matrix_operation.dart:40-48` |
| Saved linear/integer programs | User | Model, result/status, title and timestamps in `SharedPreferences` JSON | Same backup caveat | Individual delete | `lib/features/linear_programming/data/linear_program_repository.dart:50-80`; `lib/features/integer_programming/data/integer_program_repository.dart:51-81` |
| Formula favorites | User | Formula IDs in `SharedPreferences` | Same backup caveat | Toggle individually; no global clear in Settings | `lib/features/formula_library/application/formula_favorites_controller.dart:10-22` |
| Theme, language, angle, precision, haptics, sound, scientific notation | User/device locale | `SharedPreferences` | Same backup caveat | No in-app reset-all; clear app storage/uninstall | `lib/features/settings/presentation/settings_controller.dart:13-45,57-92` |
| Clipboard copy | Explicit user action | Writes selected result/formula text to system clipboard | Available to the OS and clipboard consumers under platform rules | User/OS controlled | `lib/core/widgets/result_action_bar.dart:18-24`; `lib/features/calculator/presentation/calculator_page.dart:228-236` |
| Graph image share | Explicit user action | In-memory PNG passed to Android share chooser | Sent only to the app selected by the user | Receiving app controls its copy | `lib/features/graph/data/graph_export_service.dart:42-51` |
| Privacy and subscription URLs | Explicit user action | Opens external browser/Google Play | URL and ordinary network metadata reach the selected service | User/browser controlled | `lib/features/settings/presentation/about_page.dart:240-258`; `lib/features/premium/presentation/premium_page.dart:133-145` |
| Advertising | App on Home/Saved | UMP consent/status, then Google Mobile Ads banner request | Yes. Google says its SDK automatically collects/shares IP address, user-product interactions, diagnostics and device/account identifiers | UMP privacy options where required; advertising ID in Android settings | `lib/app/ads/ad_banner.dart:43-94,102-130`; `lib/features/home/presentation/home_page.dart:70-73`; `lib/features/saved/presentation/saved_page.dart:65-68` |
| Supabase email authentication (dormant/future) | No current release input | Source supports Supabase Auth, but owner-confirmed release has no Supabase configuration and does not activate the account surface | No in the confirmed release profile | Not applicable to current users | `lib/main.dart:13-29`; `lib/app/premium/premium_surface.dart:4-19`; `docs/play_store_release_notes.md:43-52` |
| Entitlement and purchase validation (dormant/future) | No current release purchase flow | Billing/token-validation source exists but is not reachable/active in the confirmed release profile | No in the confirmed release profile | Not applicable to current users | `lib/app/billing/play_billing_repository.dart:171-179`; `lib/app/premium/entitlement_sync_service.dart:25-52`; owner confirmation |
| AI Assistant | User prompt | Local mock classifier/planner/composer; no remote provider | No | In-memory session only | `lib/features/ai_assistant/application/ai_assistant_controller.dart:10-11`; `lib/features/ai_assistant/infrastructure/mock_ai_assistant_service.dart:7-10` |
| Camera Solver | None yet | Placeholder only | No | Not applicable | `lib/features/camera_solver/presentation/camera_solver_page.dart:31-44`; no camera permission in source/merged manifest |

### Network destinations identifiable from source

- Google AdMob/UMP through `google_mobile_ads`.
- No Supabase Auth, RPC or Edge Function traffic in the owner-confirmed release profile. Source would enable it only if valid HTTPS Supabase build-time configuration were supplied.
- No Google Play Billing transaction flow in the owner-confirmed release profile. Billing code/dependency remains present in the artifact but the Premium surface is inactive.
- External browser targets selected by user: the privacy-policy URL and Google Play subscription-management URL.
- No direct `http` package/API client, Firebase, analytics, crash reporting, remote config, push notification, custom WebView content or developer telemetry endpoint was found.

## Privacy Policy Summary

### Live policy

The live page was accessible on 2026-08-11 without authentication. It identifies Calcademy, Ali Gündoğan, Nilüfer/Bursa, Türkiye, the effective date `2026-08-06`, and `calcademyapp@gmail.com`. It states that it covers `1.8.0 (build 20)` and discloses:

- local calculations and `SharedPreferences` storage;
- history, saved calculations, graphs, matrices, optimization workspaces, titles, notes, favorites, summaries and timestamps;
- Google AdMob banners on Home and Saved;
- UMP consent/privacy options;
- AdMob processing of advertising/device identifiers, IP address, coarse/derived location and general device information;
- `INTERNET` and `ACCESS_NETWORK_STATE`;
- user-initiated system sharing;
- individual/clear deletion plus Android clear-storage/uninstall;
- no analytics, Firebase, crash SDK, Calcademy backend, account or cloud sync.

### Repository policy and published GitHub Pages copy

`docs/privacy_policy.md` is more complete than the live developer-domain page. It contains optional Supabase Auth, Google Play Billing, purchase-token validation, entitlement metadata and account-deletion sections (`docs/privacy_policy.md:83-99,113-155`). The corresponding GitHub Pages URL was also reachable and displayed this expanded content.

The two public pages therefore do **not** carry equivalent disclosures, despite the repository instruction that they must be revised together (`docs/privacy_policy.md:35-37`). The live developer-domain page omits the optional account/billing sections and states that there is no account/backend. Neither page discloses Android Auto Backup. Both remain labeled for `1.8.0 (build 20)` rather than `1.9.3+26`.

### Identity and URL consistency

- App code URL: `https://gundev.dev/gizlilik/calcademy` — matches the requested/live URL (`lib/app/app_metadata.dart:36-38`).
- Live developer/publisher: Ali Gündoğan — matches `AppMetadata.publisherName` (`lib/app/app_metadata.dart:5`).
- Live contact: `calcademyapp@gmail.com` — matches repository policy/account-deletion documents, but `AppMetadata.contactEmail` remains `null` (`lib/app/app_metadata.dart:28-31`). This does not break the live policy link, but prevents a direct in-app contact action.
- `README.md:169` still describes the old GitHub Pages URL as the published policy link. It is reachable, but it is not the URL compiled into the current app.
- The actual privacy URL and account-deletion URL entered in Play Console were not accessible from repository evidence and must be verified by the release owner.

## Code vs Policy Comparison Table

| Topic | Live policy claim | Actual audited behavior | Result |
|---|---|---|---|
| Covered version | Current for `1.8.0 (20)` | Source and existing release artifact are `1.9.3 (26)` | **Mismatch** |
| Calculations | Performed on device | Calculation engines are local | Match |
| Local saved data | Stored in Android app storage/SharedPreferences | Multiple SharedPreferences repositories store the described data | Match, subject to backup |
| Cloud copy | No cloud copy; data stays on device | Auto Backup is not disabled/excluded; SharedPreferences may be uploaded to Google Drive | **Contradiction** |
| Developer server upload of calculations | Not uploaded to Calcademy server | No calculation/saved-work upload path found | Match |
| Advertising | AdMob banner on Home and Saved | Exactly those two placements found | Match |
| AdMob data types | IDs, IP, coarse location, general device information “such as” | Google's current disclosure also lists app interactions and diagnostics | **Incomplete** |
| Analytics/crash | None | No analytics/crash SDK found | Match; AdMob diagnostics must not be mislabeled as no app-performance data in Data Safety |
| Network permissions | `INTERNET`, `ACCESS_NETWORK_STATE` | Direct source permissions match, but merged manifest adds `AD_ID`, Privacy Sandbox, WorkManager/foreground-service and Billing permissions | Partially complete |
| Account/backend | None | Owner confirms no Supabase defines/account surface in the release; source contains dormant future implementation | Match for confirmed release; maintain build guard |
| Billing | Not described on live page | Billing SDK and permission are included in the free AAB; UI/use is gated by Supabase config | **Incomplete / unnecessary surface** |
| Share | User-initiated chooser only | Graph PNG share is explicit user action | Match |
| Clipboard | Not expressly described | Multiple explicit copy actions write to system clipboard | Low-risk omission |
| Data deletion | Individual/clear actions; clear storage/uninstall removes all | Individual deletes exist. Settings clear actions cover only history and legacy saved list; Android backup can restore data after reinstall/device setup | **Overstated** |
| Consent withdrawal | Immediate, no restart | Privacy form refreshes state, but `AdBanner` does not watch that provider or explicitly dispose/reload the current ad; SDK auto-refresh may eventually apply it | Not fully proven by code |
| Children | Academic tool; not designed to collect sensitive data | Educational positioning includes high-school students; target-audience checklist leaves age decisions open; ads age flags are unset | Release-owner decision still required |
| Camera/microphone/location/contacts | No such collection claimed | No permissions or implementations found | Match |

## Android Permissions & Manifest Review

### Source manifest

`android/app/src/main/AndroidManifest.xml` directly requests only:

- `android.permission.INTERNET` (`:5`)
- `android.permission.ACCESS_NETWORK_STATE` (`:6`)

It declares the AdMob application ID (`:16-18`) and one exported launcher activity (`:19-40`). No deep-link intent filter is declared; only `MAIN/LAUNCHER` is exported. No custom `networkSecurityConfig`, cleartext opt-in, camera, microphone, location, contacts, storage/media, notification or Bluetooth permission is present.

The application element does not set `android:allowBackup`, `android:fullBackupContent` or `android:dataExtractionRules` (`android/app/src/main/AndroidManifest.xml:7-10`). Android documents that Auto Backup defaults to enabled for eligible apps and includes shared-preference files by default. See [Android Auto Backup documentation](https://developer.android.com/identity/data/autobackup).

### Existing release merged manifest

The existing `1.9.3+26` release merged manifest reports `minSdkVersion=24` and `targetSdkVersion=36` (`build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml:3-9`). It contains:

| Merged permission | Source | Privacy/Play meaning |
|---|---|---|
| `INTERNET` | app/AdMob/Supabase-capable dependencies | Required for ads; also permits conditional Auth/backend/external SDK traffic |
| `ACCESS_NETWORK_STATE` | app/AdMob | Network awareness |
| `com.google.android.gms.permission.AD_ID` | Google Mobile Ads | Advertising identifier disclosure/Ads declaration |
| `ACCESS_ADSERVICES_AD_ID` | Google Mobile Ads | Privacy Sandbox ad ID API surface |
| `ACCESS_ADSERVICES_ATTRIBUTION` | Google Mobile Ads | Attribution API surface |
| `ACCESS_ADSERVICES_TOPICS` | Google Mobile Ads | Topics API surface; verify actual SDK/config behavior and Data Safety disclosure |
| `WAKE_LOCK` | AdMob/WorkManager transitive code | Background scheduling/runtime support |
| `FOREGROUND_SERVICE` | WorkManager transitive code | Background/foreground service capability; no Calcademy foreground-service feature found |
| `com.android.vending.BILLING` | `in_app_purchase` | Signals Google Play Billing even in the no-account/free release |
| package-scoped dynamic receiver permission | AndroidX | Signature-scoped internal receiver protection |

Evidence: merged manifest lines `66-78`, AdMob/WorkManager/Billing components at `134-324`.

### Build and release configuration

- Namespace/applicationId: `com.aligundogan.calcademy` (`android/app/build.gradle.kts:22,32`).
- Java/Kotlin target: 17 (`android/app/build.gradle.kts:26-29,77-80`).
- Release signing is required; build fails when `key.properties` is missing (`android/app/build.gradle.kts:39-75`).
- Release minification and resource shrinking are enabled (`android/app/build.gradle.kts:50-60`).
- Existing AAB SHA-256: `7D5A9BDC0395FD529F3BAB82BE1F4975F85681181B98A79E767F4D30CF180C8D`; existing APK SHA-256: `74AF67A14BFEADC54A1E0F292D6C697F2DA55CAE8DD35E14595C4857A972EB2C`. These match `docs/production_readiness_report.md:36-44`.
- The working tree has many pre-existing modifications after those artifacts' build time. The artifact cannot be treated as byte-for-byte proof of the current working tree.

## Flutter Dependencies Privacy Review

| Dependency | Actual use | Privacy significance | Assessment |
|---|---|---|---|
| `shared_preferences ^2.5.5` | Settings, history, legacy saves, cross-module saved records, graphs, matrices, LP/IP, favorites | Persistent local data; Auto Backup eligible by default | High relevance; policy incomplete on backup |
| `google_mobile_ads ^9.0.0` | UMP, SDK initialization and Home/Saved banners | Third-party advertising collection/sharing; merged IDs/AdServices permissions | Disclosed but Data Safety categories incomplete |
| `supabase_flutter 2.16.0` | Conditional Auth, sessions, RPC, Edge Functions | Email, user ID, auth/security/session data, entitlement and purchase validation | Disabled in documented free build; must be separately disclosed if configured |
| `in_app_purchase ^3.3.0` | Google Play product query, purchase/restore stream, purchase token and completion | Purchase history/token; Billing permission and components remain in free artifact | Gated in UI but not removed from artifact |
| `share_plus ^13.2.1` | User-initiated in-memory graph PNG share | Sends chosen content to selected receiving app | Correctly disclosed |
| `url_launcher ^6.3.2` | Privacy page and Play subscription management | External service receives normal navigation/network metadata | User initiated; acceptable |
| `flutter_svg`, `fl_chart`, `intl`, `go_router`, Riverpod | UI, charting, localization, routing/state | No independent remote collection found | Low privacy relevance |

Additional observations:

- `Clipboard.setData` is used for calculations, formulas and results. No clipboard read was found.
- `supabase_flutter` is initialized only when both compile-time values form a valid HTTPS configuration (`lib/app/config/app_config.dart:2-18`; `lib/main.dart:13-24`).
- The free-build release instructions explicitly require no `--dart-define` (`docs/play_store_release_notes.md:43-52`). This is documentation, not cryptographic proof of the uploaded AAB's profile.
- The Premium surface is tied directly to `isAuthConfiguredProvider` (`lib/app/premium/premium_surface.dart:17-19`). Free-build tests verify that account/Premium/assistant/camera entry points are hidden (`test/app/premium/free_build_surface_test.dart:47-168`).
- The router still contains account/Premium routes (`lib/app/router.dart:53-70`), but no Android deep link is declared. Ordinary free-build users have no UI entry point.
- The Supabase deletion function derives the user from the access token and calls `admin.deleteUser`; supplied schema foreign keys cascade account-linked profile, entitlement, purchase, validation-event and quota rows (`supabase/functions/delete-account/index.ts:27-72`; migration `:3-5,15-18,45-48,78-81,103-106`).
- No privileged Supabase service-role key is present in the mobile client. It is read only inside Edge Functions.

## Google Play Data Safety Recommendation

Google requires declarations to include third-party SDK behavior and makes the developer responsible for accuracy. See [Google Play Data Safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469) and [User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311). Google's current [Mobile Ads SDK Play data disclosure](https://developers.google.com/admob/android/privacy/play-data-disclosure) says the SDK automatically collects and shares IP address, user-product interactions, diagnostic information, and device/account identifiers for advertising, analytics and fraud prevention; transmitted data is protected with TLS.

### Recommended answers — default ad-supported release with no Supabase defines

These are technical recommendations to map into the exact current Play Console wording; save a dated export of the submitted form.

| Form area | Recommended answer | Notes |
|---|---|---|
| Does the app collect or share required data types? | **Yes** | AdMob third-party SDK behavior counts even though calculations are local |
| Data shared? | **Yes** | Google's provider disclosure says the listed data are collected and shared |
| Encrypted in transit? | **Yes** | Google states Mobile Ads SDK data are protected with TLS; no cleartext developer endpoint found |
| Data deletion request mechanism? | **Conservatively No for the no-account release**, unless the exact current form/provider guidance confirms Android/Google ad controls qualify | Local-only data is generally outside “collected” Data Safety scope; Calcademy cannot delete AdMob-held data from its own server. Do not answer Yes merely because local records can be deleted |
| Account deletion? | **Not applicable** for the exact no-Supabase build | Confirm there is no account creation in the uploaded AAB's reachable UI |
| Contains ads | **Yes** | Home and Saved banners |
| Approximate location | **Collected/shared; optional/SDK-dependent classification must be confirmed** | Google says IP can estimate general location; live policy already says coarse/derived location |
| App activity → App interactions | **Collected and shared** | Google Mobile Ads automatic behavior |
| App info and performance → Diagnostics | **Collected and shared** | Google Mobile Ads automatic behavior |
| Device or other IDs | **Collected and shared** | Advertising ID, app set/group identifiers and other identifiers where available |
| Purposes | **Advertising or marketing; Analytics; Fraud prevention, security and compliance** | Use provider wording and select only purposes shown by the exact SDK/setup |
| Required vs optional | Treat advertising data as required for the ad-supported service unless the current limited-ads configuration/provider guidance supports a narrower answer | Consent variation does not make the SDK absent; `docs/ump_consent.md:144-146` correctly notes this |

The current `docs/data_safety_draft.md:91-94` must be corrected: App activity and App info/performance are not both “No” for an AdMob build. The older `docs/play_console_app_content_checklist.md:53-56` is even more dangerous because it proposes collection/sharing “No” despite AdMob.

### Additional answers — only for a Supabase-configured account/Premium release

If a configured build is ever uploaded, redo the whole form and additionally disclose at least:

- **Personal info → Email address**: collected, not sold; account management/app functionality.
- **User IDs**: Supabase Auth ID/profile association; account management/app functionality.
- **Authentication/security information** as applicable to the current form taxonomy and Supabase behavior.
- **Purchase history** and/or applicable financial-information subtype: Google Play product/subscription status; Calcademy does not receive card/bank details.
- **Purchase token and derived hash**, product ID, validation status/events and timestamps sent to/retained in Supabase for purchase validation, fraud prevention and entitlement management.
- Account deletion **Yes** only after verifying both in-app deletion and the public external URL against the production project. Google requires both in-app and external deletion for apps that allow account creation.
- Identify Supabase and Google Play as service providers/third parties according to the form's current sharing definitions.

### Security practices

- Data in transit: HTTPS/TLS is enforced for Supabase configuration (`lib/app/config/app_config.dart:14-18`) and Google states TLS for Mobile Ads.
- Local at-rest data: ordinary `SharedPreferences`, not application-level encrypted storage. Do not claim app-level encryption at rest.
- Independent security review: no evidence; do not claim one.
- Families commitment: only if the target audience selection actually brings the app under Families and all requirements are met.
- Account deletion: the supplied backend design is sound at source level, but production deployment, exact project, session revocation behavior and Play Console external URL were not verified.

## Findings by Severity

### Critical

No Critical findings.

### High

#### H-01 — “Device-only/no cloud copy” is false under default Android Auto Backup

- **Finding:** No backup opt-out or data-extraction rules are declared. Android Auto Backup defaults to enabled and includes SharedPreferences, allowing calculations, notes, saved work and settings to be uploaded to the user's Google Drive and restored later.
- **Evidence:** `android/app/src/main/AndroidManifest.xml:7-10`; merged manifest `:80-85` contains no backup attributes; all persistent stores listed in App Data Flow Summary use SharedPreferences.
- **Policy text:** “Bu bilgiler bir Calcademy sunucusuna yüklenmez… bulut senkronizasyonu… yoktur”; “Bulut kopyası bulunmadığından…”; repository equivalent at `docs/privacy_policy.md:76-81,137-155`.
- **Why it matters:** “Not a Calcademy server” is true, but “stays on device/no cloud copy/uninstall deletes it” is not. User notes and calculation records may contain personal, financial or health information despite the warning not to enter it.
- **Required fix type:** **Code/config and policy.** Either disable/exclude backup for stored work, or explicitly disclose Android/Google system backup, encryption, restore and deletion limitations. Reassess Data Safety under the exact current form.

#### H-02 — AdMob Data Safety categories are materially incomplete

- **Finding:** Repository drafts say App activity and App info/performance are not collected. Google's current Mobile Ads SDK disclosure says user-product interactions and diagnostic information are automatically collected and shared, alongside IP and identifiers.
- **Evidence:** `docs/data_safety_draft.md:91-94`; `docs/play_console_app_content_checklist.md:53-56`; `pubspec.yaml:47`; merged `AD_ID`/AdServices permissions at lines `66-69`; active banner load `lib/app/ads/ad_banner.dart:68-94`.
- **Policy text:** Live policy lists identifiers, IP, coarse location and general device information but not app interactions/diagnostics.
- **Why it matters:** An inaccurate Play Data Safety label can cause enforcement and conflicts with the User Data policy requirement that third-party SDK collection/sharing be reflected accurately.
- **Required fix type:** **Play Console/Data Safety and policy wording.** Correct the drafts and submitted form; name interactions and diagnostics, purposes and sharing.

### Medium

#### M-01 — Live policy and store/legal documents are stale and drifted

- **Finding:** Live/repository policies cover `1.8.0+20`; app is `1.9.3+26`. GitHub Pages contains Supabase/Billing sections missing from developer-domain live page. Several Play checklists still describe older branch/version states and mutually contradictory Data Safety answers.
- **Evidence:** `pubspec.yaml:19`; `lib/app/app_metadata.dart:6-8`; `docs/privacy_policy.md:27,43-53`; `docs/play_store_final_checklist.md:3-21`; `docs/play_console_app_content_checklist.md:3-9,53-56`.
- **Policy text:** “Bu politika Calcademy 1.8.0 (sürüm 20) yapısı için geçerlidir.”
- **Why it matters:** Users/reviewers cannot determine which statements govern the current artifact; stale operational docs can cause an incorrect Console submission.
- **Required fix type:** **Policy/docs/Play Console.** Establish one canonical policy source and versioned release matrix; archive or clearly supersede old checklists.

#### M-02 — Free artifact includes Billing and Supabase-related native surface it claims not to ship

- **Finding:** UI/config gating prevents normal use, but `in_app_purchase` and `supabase_flutter` remain direct dependencies. The merged manifest includes Billing permission/components and transitive browser/app-link support.
- **Evidence:** `pubspec.yaml:48-49`; merged manifest `:59-63,72,259-275`; `.flutter-plugins-dependencies` lists `in_app_purchase_android`, `app_links`, path provider and WebView transitive plugins.
- **Policy text:** Live scope is an account-free AdMob product; repository release notes say account/subscription surface is compiled out (`docs/play_store_release_notes.md:37-52`).
- **Why it matters:** “Compiled out” is inaccurate at dependency/manifest level. Play review and automated SDK/permission scanning can detect Billing even when UI is hidden; unnecessary code increases supply-chain and privacy attack surface.
- **Required fix type:** **Dependency/build architecture.** Produce a genuinely free dependency graph/flavor or remove Billing/Supabase from the free release line.

#### M-03 — “Clear saved” does not clear all saved data categories

- **Finding:** Settings calls `savedProvider.clear()`, which clears only `calculator.saved`. It does not clear the cross-module saved repository, graphs, matrices, LP/IP models or formula favorites. Those have individual deletion, and one controller has a clear method that Settings does not invoke.
- **Evidence:** `lib/features/settings/presentation/settings_page.dart:173-201`; `lib/features/saved/presentation/saved_controller.dart:57-67`; `lib/features/saved_calculations/presentation/saved_calculations_controller.dart:127-137`; storage keys listed in App Data Flow Summary.
- **Policy text:** “Kullanıcılar tek tek geçmiş/kayıtlı öğeleri silebilir ve mevcut tümünü temizle eylemlerini kullanabilir.”
- **Why it matters:** The UI label “all saved calculations” can reasonably be understood as global, while substantial saved work remains.
- **Required fix type:** **Code/UI or policy wording.** Implement a true global clear with category confirmation, or accurately scope labels/policy to the legacy collection.

#### M-04 — Consent-withdrawal “immediate” behavior is not guaranteed by app code

- **Finding:** Settings refreshes `adConsentStateProvider`, but `AdBanner` does not watch it, dispose the current ad or explicitly issue a new request. A future SDK banner refresh may pick up the new status, but immediate application is not proven by code.
- **Evidence:** `lib/app/ads/consent_providers.dart:15-32`; `lib/app/ads/ad_banner.dart:38-118`; docs claim banner reads refreshed state at `docs/ump_consent.md:59-67`.
- **Policy text:** “Onayı geri çekmek, uygulamayı yeniden başlatmadan anında etkili olur.”
- **Why it matters:** The policy uses an absolute timing promise. Device notes report success, but there is no app-level state linkage and no automated test of a live banner transition.
- **Required fix type:** **Code/test or wording.** Observe consent changes and reload/dispose deterministically, or remove “anında” and describe SDK application accurately.

#### M-05 — Target-audience/children decision remains unresolved

- **Finding:** Calcademy is marketed to high-school students, while the target-audience checklist still has blocking age decisions unchecked. Ad age-treatment flags are unset; the UMP document says no age assertion is made.
- **Evidence:** `docs/target_audience_checklist.md:3-31,43-48`; `docs/ump_consent.md:147-150`; store listing `docs/store_listing.md:25-42`.
- **Policy text:** Live policy only says the app is an academic tool and not designed to collect sensitive information; it does not state a defined minimum age or child-directed status.
- **Why it matters:** Google states that any selected child-inclusive age group triggers Families requirements; under-21 audiences can be children under local law. Ads must then meet the Families SDK/age-screen requirements.
- **Required fix type:** **Play Console/product/legal decision.** Record intended age groups and regions before release. If any child group is selected, perform a full Families review and configure ads/age treatment accordingly.

#### M-06 — Dormant Supabase/Billing code needs a release guard

- **Finding:** The owner confirms these features are inactive, so they are not current data collection. However, valid Supabase defines would enable account creation/login, email/Auth processing, sessions, entitlement RPC calls, Play Billing and purchase-token submission without changing the package identity.
- **Evidence:** `lib/main.dart:13-29`; `lib/app/premium/premium_surface.dart:4-19`; `lib/app/auth/supabase_auth_repository.dart:27-107`; `lib/app/premium/entitlement_sync_service.dart:25-52`; free release command at `docs/play_store_release_notes.md:43-52`.
- **Policy text:** Live policy says there is no account, login or Calcademy backend; this is correct for the owner-confirmed release profile.
- **Why it matters:** A future or mistaken build command could silently create a materially different privacy profile.
- **Required fix type:** **Release configuration.** Keep Supabase defines forbidden in this release line and add an auditable build assertion. Update policy/Data Safety only before intentionally activating these features.

### Low

#### L-01 — Clipboard behavior is not disclosed

- **Finding:** Explicit copy actions write expressions/results/formulas to the system clipboard.
- **Evidence:** `lib/core/widgets/result_action_bar.dart:18-24`; `lib/features/calculator/presentation/calculator_page.dart:228-236`; other copy sites found across formula, LP/IP and saved-result screens.
- **Policy text:** Share chooser is disclosed, clipboard is not.
- **Why it matters:** Clipboard is user initiated and no read occurs, so this is low risk, but a short disclosure improves transparency.
- **Required fix type:** **Policy wording only** unless more restrictive clipboard handling is desired.

#### L-02 — Contact is not exposed as an in-app action

- **Finding:** The live policy has a valid email, but `AppMetadata.contactEmail` is null.
- **Evidence:** `lib/app/app_metadata.dart:28-31`; live/repo policy contact at `docs/privacy_policy.md:29-35`.
- **Policy text:** `calcademyapp@gmail.com`.
- **Why it matters:** Not a policy violation by itself; it makes privacy requests less discoverable in-app.
- **Required fix type:** **Optional app metadata/UI improvement.** Verify monitored ownership first.

### Info

1. **No analytics/crash SDK found.** `pubspec.yaml:30-50` contains no Firebase, Analytics, Crashlytics or Sentry package; error logs do not include calculation content in reviewed paths.
2. **No sensitive Android runtime permission found.** Camera, microphone, location, contacts, calendar, SMS/call log and media/storage permissions are absent from source and existing merged release manifest.
3. **No remote AI or camera processing found.** AI uses a local mock; Camera Solver is a placeholder.
4. **Ad placement matches policy.** `AdBanner` is on Home and Saved only.
5. **Sharing is user initiated.** Graph PNG stays in memory until Android chooser transfer; no developer upload.
6. **Supabase backend source uses appropriate authorization basics.** User identity is derived from verified token, privileged key stays server-side, RLS is enabled and account-linked rows cascade. Live deployment/advisors were not inspected.
7. **Release security settings are reasonable.** Release signing is mandatory, minification/resource shrinking enabled, target SDK 36, min SDK 24, launcher activity export is appropriate and no deep link is configured.

## Required Fixes Before Wider Release

1. **Choose and implement the backup posture.** For a strict local-only promise, disable cloud backup and exclude all SharedPreferences/user work with explicit Android 11 and Android 12+ rules; test backup/restore on target devices. If backup is desired, update policy, deletion text and UX to disclose Google/Android backup and restore.
2. **Correct Data Safety before the next closed/open/production submission.** At minimum include AdMob app interactions, diagnostics, device/other IDs and evaluate approximate location/IP mapping; mark sharing and purposes from Google's current SDK guidance.
3. **Update the live developer-domain policy to `1.9.3+26`** and make it equivalent to the canonical repository/GitHub source for the release profile actually shipped.
4. **Prove the exact AAB profile.** Record Git SHA, AAB hash, build command and an automated binary/config assertion that Supabase defines are absent for the free release. Do not rely only on a checklist.
5. **Keep dormant features inactive.** Add a build assertion that rejects Supabase defines for this release profile. If those features are intentionally activated later, treat that as a new privacy review and update app metadata/policy/Data Safety before release.
6. **Remove Billing/Supabase dependencies from the free artifact if feasible.** At minimum explain the Billing permission in release records and verify Play Console Monetization/App Content behavior.
7. **Fix or relabel “Clear saved.”** Ensure the action clears every promised saved category, including cross-module archives, graphs, matrices, LP/IP and favorites, or scope the wording precisely.
8. **Finalize target audience.** Do not select child-inclusive groups until Families, ads SDK eligibility, age treatment, consent and policy implications are complete.
9. **Verify Play Console directly.** Confirm privacy URL, Data Safety export, Contains Ads=Yes, app access, target audience, financial-features declaration and (only for account builds) external account-deletion URL.

## Recommended Privacy Policy Wording Changes

The exact legal language should be reviewed by qualified counsel for the distribution regions. At a minimum, replace absolute/incorrect statements with release-specific factual language.

### Version and build scope

> Bu politika Calcademy 1.9.3 (sürüm 26) için geçerlidir. Bu sürüm Google AdMob banner reklamlarını içerir. Bu mağaza yapısı Supabase hesabı veya Premium aboneliği etkinleştirilmeden derlenmiştir.

If configured account builds will exist, publish a separate clearly identified paragraph/table rather than mixing historical and active behavior.

### Android backup — if backup remains enabled

> Android'in sistem yedekleme özelliği açıksa, uygulamanın SharedPreferences içinde tuttuğu ayarlar, geçmiş, kaydedilen hesaplamalar, notlar ve çalışma alanları kullanıcının Google hesabına bağlı Android yedeklemesine dahil edilebilir ve yeni bir cihaza ya da yeniden kuruluma geri yüklenebilir. Bu yedekleme Calcademy sunucusu tarafından işletilmez; Google/Android'in yedekleme ve güvenlik koşulları geçerlidir. Uygulamayı kaldırmak cihazdaki kopyayı siler, ancak mevcut sistem yedeğini her durumda silmeyebilir.

If backup is disabled/excluded, instead say it is excluded and test that claim.

### AdMob data categories

> Google Mobile Ads SDK; reklam sunma, ölçüm/analiz ve sahtekârlığı önleme amaçlarıyla IP adresi, yaklaşık konum çıkarımı, uygulama etkileşimleri (ör. uygulama açılışı veya reklam etkileşimi), tanılama/performance bilgileri ve reklam/cihaz/hesap tanımlayıcılarını otomatik olarak toplayabilir ve Google ile reklam ortaklarıyla paylaşabilir. Aktarım Google tarafından TLS ile korunur. Güncel kapsam Google'ın Mobile Ads veri açıklamasında yer alır.

Avoid implying that rejection stops all AdMob data processing. State only the behavior verified for the exact consent/ad-serving configuration.

### Local deletion

Until a true global clear exists:

> Geçmiş ve farklı kayıt türleri ilgili ekranlardan tek tek silinebilir. Ayarlar'daki temizleme eylemleri yalnızca ekranda belirtilen veri kategorisini temizler. Tüm cihaz içi Calcademy verilerini kaldırmak için Android uygulama depolaması temizlenebilir. Sistem yedekleme açıksa, yedeklenmiş veriler ayrıca Android/Google hesap ayarlarından yönetilmelidir.

### Conditional Supabase/account release

Before such a release, include:

> Hesap özelliği etkin olan sürümlerde Supabase; e-posta adresi, kullanıcı kimliği, kimlik doğrulama ve güvenlik verileri ile oturum belirteçlerini hesap yönetimi için işler. Google Play aboneliği kullanıldığında ürün kimliği, satın alma belirteci ve abonelik durumu doğrulama amacıyla yetkili Supabase fonksiyonuna gönderilir; tam belirteç kalıcı olarak saklanmaz, ancak kriptografik özeti ve doğrulama/abonelik denetim kayıtları hesapla ilişkilendirilebilir.

Also state precise retention periods or objective criteria, recipients/service providers, account deletion effects, and the external deletion URL.

### Clipboard and share

> Kullanıcı Kopyala veya Paylaş eylemini seçtiğinde, seçilen metin sistem panosuna yazılabilir veya üretilen grafik görseli Android paylaşım seçicisiyle kullanıcının seçtiği uygulamaya aktarılabilir. Calcademy bu içeriği kendi sunucusuna göndermez; alıcı uygulama ve işletim sistemi özellikleri kendi politikalarına tabidir.

## Recommended Code / Config Changes

No code/config change was made during this audit. Recommended implementation work, after owner approval:

1. Add an explicit Android backup configuration. Preferred local-only implementation: `android:allowBackup="false"` plus Android 12+ `android:dataExtractionRules` and legacy `fullBackupContent` exclusions for defense in depth; explicitly decide whether device-to-device transfer is permitted.
2. Add automated merged-manifest tests for backup attributes and the full permission list, not just source-manifest permissions.
3. Split the free and Premium dependency graphs/build flavors. The free artifact should not contain Billing/Supabase native components if it claims those features are absent.
4. Add a release build task that fails if `SUPABASE_URL`/`SUPABASE_ANON_KEY` are present in the free profile and fails if the wrong policy/version metadata is compiled.
5. Make About & Legal flags conditional on the same verified release profile; never show “No account” when Auth is configured.
6. Implement a global local-data inventory/reset service covering history, legacy saves, cross-module saved calculations, graphs, matrices, LP/IP and formula favorites. Provide category-level confirmation and tests.
7. Bind `AdBanner` to consent-state changes and explicitly dispose/reload after privacy-option changes; add a platform/device integration test for grant → reject and reject → grant.
8. Consider moving session/auth material to storage behavior recommended by the current Supabase Flutter SDK and exclude it from backup. Re-run Supabase security advisors against the deployed production project before account launch.
9. Remove stale legal/store drafts or mark them clearly superseded. Generate the live policy from one canonical source to prevent manual drift.
10. Add a release evidence bundle: Git SHA, AAB hash, merged manifest, dependency tree, Data Safety CSV export, Play App Content screenshots and live URL checks.

## Evidence Appendix with file paths and line references

### Release identity and build

- `pubspec.yaml:19` — `1.9.3+26`.
- `lib/app/app_metadata.dart:2-8,36-38` — app identity, version/build and live privacy URL.
- `android/app/build.gradle.kts:21-37` — namespace/applicationId and Flutter min/target/version wiring.
- `android/app/build.gradle.kts:39-75` — release signing/minify/shrink configuration.
- `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml:3-9` — resolved package/version/minSdk/targetSdk.
- `docs/production_readiness_report.md:36-44` — existing build commands, artifacts and hashes.

### Android permissions and components

- `android/app/src/main/AndroidManifest.xml:1-18` — direct network permissions and AdMob ID.
- `android/app/src/main/AndroidManifest.xml:19-40` — exported launcher activity only.
- `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml:66-78` — merged AD_ID, AdServices, wake lock, foreground service, Billing and receiver permissions.
- Same merged manifest `:134-324` — AdMob, WorkManager, share provider, URL launcher, Billing, Room and transport components.
- Absence evidence: no `allowBackup`, `fullBackupContent` or `dataExtractionRules` in source or merged manifest.

### Local storage and deletion

- `lib/main.dart:10-29` — SharedPreferences initialization and conditional Supabase initialization.
- `lib/features/history/data/local_calculation_repository.dart:13-63` — history/legacy saved JSON.
- `lib/features/saved_calculations/data/saved_calculations_repository.dart:59-190` — versioned saved calculation repository, delete/clear.
- `lib/features/graph/data/graph_repository.dart:47-79` — saved graphs.
- `lib/features/matrix/data/matrix_repository.dart:48-81` — saved matrices.
- `lib/features/linear_programming/data/linear_program_repository.dart:50-80` — saved LP.
- `lib/features/integer_programming/data/integer_program_repository.dart:51-81` — saved IP.
- `lib/features/formula_library/application/formula_favorites_controller.dart:10-22` — favorites.
- `lib/features/settings/presentation/settings_controller.dart:13-92` — settings keys and persistence.
- `lib/features/settings/presentation/settings_page.dart:173-201` — Settings clear actions only target history and legacy saved provider.

### Advertising and consent

- `pubspec.yaml:47` — Google Mobile Ads dependency.
- `lib/app/ads/ad_config.dart:17-50,142-155` — production identifiers and Android/iOS/release gating.
- `lib/app/ads/consent_gateway.dart:48-117` — UMP request, form and status read.
- `lib/app/ads/consent_service.dart:48-90` — session consent flow and privacy options.
- `lib/app/ads/ad_banner.dart:43-130` — consent → SDK init → banner load; no consent-provider watch.
- `lib/features/home/presentation/home_page.dart:70-73`; `lib/features/saved/presentation/saved_page.dart:65-68` — only placements.
- `docs/ump_consent.md:23-40,59-67,144-150` — product assumptions, withdrawal claim, Data Safety and age-treatment caveats.

### Conditional Auth, Billing and backend

- `lib/app/config/app_config.dart:1-18` — compile-time Supabase config and HTTPS validation.
- `lib/app/premium/premium_surface.dart:4-19` — config enables whole account/Premium surface.
- `lib/app/auth/supabase_auth_repository.dart:27-107,124-131` — email sign-in/up, password reset, account deletion and mapped email/user ID.
- `lib/app/billing/play_billing_repository.dart:12-50,92-138,171-179` — Billing client, product query, purchase/restore and server verification token.
- `lib/app/premium/entitlement_sync_service.dart:25-52` — token submission to Edge Function.
- `lib/app/premium/backend_entitlement_repository.dart:26-45` — entitlement RPC.
- `supabase/functions/delete-account/index.ts:27-72` — authenticated server deletion.
- `supabase/functions/validate-play-purchase/handler.ts:50-98` — authenticated body, purchase token hashing and unsupported response.
- `supabase/functions/validate-play-purchase/index.ts:8-54` — hashed token audit inserts.
- `supabase/migrations/20260804111930_entitlement_backend_foundation.sql:3-137,139-196,233-290` — account-linked schema, RLS/policies, user trigger and entitlement RPC.

### Share, clipboard, AI and camera

- `lib/features/graph/data/graph_export_service.dart:42-51` — user-initiated in-memory PNG share.
- `lib/core/widgets/result_action_bar.dart:18-24` — clipboard write.
- `lib/features/ai_assistant/application/ai_assistant_controller.dart:10-11` — local mock provider.
- `lib/features/camera_solver/presentation/camera_solver_page.dart:31-44` — placeholder/no permission/OCR/upload message.

### Legal and store documents

- `docs/privacy_policy.md:27-53` — stale current-version statement and release matrix.
- `docs/privacy_policy.md:67-99` — local data and conditional Auth.
- `docs/privacy_policy.md:101-155` — AdMob, Billing, network/share and deletion.
- `docs/data_safety_draft.md:67-95` — proposed top-level answers and incorrect App activity/diagnostics rows.
- `docs/play_console_app_content_checklist.md:3-9,53-83` — stale/contradictory collection, account, purchase and permission declarations.
- `docs/play_store_release_notes.md:37-52` — documented no-define free build profile.
- `docs/target_audience_checklist.md:14-31` — unresolved blocking target-age decisions.
- `docs/account_deletion_request.md:16-73` — external deletion procedure and retention statements.
- `README.md:134-169` — conditional Auth/Billing architecture and stale published-policy link.

### External authoritative sources checked on 2026-08-11

- [Live Calcademy privacy policy](https://gundev.dev/gizlilik/calcademy)
- [Published GitHub Pages privacy copy](https://synnergndgn.github.io/Calcademy/privacy_policy)
- [Published account deletion page](https://synnergndgn.github.io/Calcademy/account_deletion_request)
- [Google Play Data Safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Google Play User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311)
- [Google Play target audience guidance](https://support.google.com/googleplay/android-developer/answer/9867159)
- [Google Mobile Ads SDK Play data disclosure](https://developers.google.com/admob/android/privacy/play-data-disclosure)
- [Android Auto Backup documentation](https://developer.android.com/identity/data/autobackup)

### Limitations

- Play Console fields and submitted Data Safety CSV were not available; recommendations must be mapped to the live Console by the account owner.
- The AAB actually uploaded to each Play track was not obtained from Play Console. The local AAB predates some current working-tree edits.
- No dynamic network interception was performed. Static code and existing artifact/manifest evidence cannot prove every runtime request made by closed-source SDKs.
- A targeted Flutter test command covering the free-build surface, consent gate and About/Legal screen produced no output and timed out after 120 seconds; it was not treated as either passing or failing evidence. No Flutter/Dart process remained afterward.
- AdMob console messages, limited-ads settings, UMP production configuration and SDK Index record were not inspected.
- Supabase production/staging deployment state, project settings, logs and advisors were not inspected. Findings describe source behavior when configured.
- The live `app-ads.txt` fetch was blocked by the browser client during this audit; repository/device-test notes say it is published, but this audit does not independently confirm its contents.

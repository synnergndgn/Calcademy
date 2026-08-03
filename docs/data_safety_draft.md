# Google Play Data Safety Draft

> **1.4.0+13 Supabase Auth Foundation note:** The app now contains optional
> email/password Auth client code and account UI. With no `--dart-define`
> configuration, Auth is inactive and no account data is transmitted. Before
> production account creation is enabled, this draft must change to declare
> email address/user ID collection as applicable, and secure in-app plus public
> web deletion must be live and verified.

> **1.3.0+12 Premium Architecture note:** This build adds architecture and
> coming-soon UI only. It has no real account creation, purchase flow, Gemini
> API, camera/OCR, image upload, or new data collection. Mock entitlement and
> usage state remain local.

> **1.2.0+11 AI Assistant note:** AI Assistant Foundation is local-only in
> 1.2.0+11. No prompts are sent to an external AI provider in this build. The
> feature adds no camera/OCR access, backend, account, analytics, or persistent
> chat history. Existing AdMob data handling remains unchanged.

> **Branch-scoped draft (`feature/supabase-auth-foundation`,
> 1.4.0+13).** Recheck
> the final AAB and current Google/AdMob disclosures immediately before Play
> Console submission.
> See `docs/monetization_strategy.md`.

This worksheet reflects 1.4.0+13 with the **Google AdMob banner SDK** and a
config-gated Supabase Auth client. Classify the release based on whether Auth
runtime configuration and account creation are enabled in the exact AAB. Play
Billing, cloud Saved sync, analytics, crash reporting, Gemini, and camera/OCR
remain absent.

Google defines data collection for this form around data transmitted off the device. Data processed only on the device generally does not need to be disclosed as collected. Even apps declaring no collection must complete the form for applicable Play tracks and provide a privacy-policy link. See the [official Data Safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469).

## Proposed top-level answers

| Question area | Current draft | Evidence / caveat |
| --- | --- | --- |
| Does the app collect required user-data types? | Yes (via AdMob) | Calcademy's own features are on-device, but the Google AdMob SDK collects device/advertising identifiers and related data. Confirm the exact categories from AdMob's current disclosure |
| Does the app share user data with third parties? | Yes | Ad/device identifiers are shared with Google/AdMob and its ad partners for advertising |
| Is all transmitted data encrypted in transit? | Yes | AdMob traffic uses HTTPS; confirm against AdMob's current disclosure |
| Does the app provide a deletion mechanism? | Local deletion is available | Delete/clear Saved Calculations, clear app storage, or uninstall. Ad identifiers are managed via device settings/consent |
| Is account deletion offered? | Foundation only; not production-ready | In-app route and web-page draft exist, but account creation must remain disabled until the backend and public URL work end to end |

Do not present **Not applicable** as a substitute if Play Console asks a differently scoped mandatory yes/no question; follow the current form wording.

## Data-type worksheet

| Data type | Collected by developer? | Shared? | Current behavior |
| --- | --- | --- | --- |
| Personal information | Conditional | Supabase as service provider when Auth is enabled | Email address, Auth user ID, and authentication/security metadata are transmitted only when runtime Auth configuration and account creation are enabled; absent config means no Auth transmission |
| Financial information | No | No | Educational numeric inputs are processed locally; no bank/payment/account data is requested or transmitted |
| Location | No | No | No location permission or feature |
| Contacts | No | No | No contacts permission or access |
| Messages | No | No | No messaging feature |
| Photos/videos/audio | No | No | Graph export/share is user-initiated; Calcademy does not upload it to a developer service |
| Files/documents | No | No | No developer server upload |
| Calendar | No | No | No calendar access |
| App activity | No | No | No analytics or remote activity collection |
| Web browsing | No | No | No embedded browsing/collection feature |
| App info/performance | No | No | No crash reporting, diagnostics, or performance telemetry SDK |
| Device identifiers | Yes (AdMob) | Yes | Google AdMob may collect/share advertising ID, device identifiers, and IP for ad serving, measurement, and fraud prevention. Confirm exact categories from AdMob's current Data Safety guidance |

## On-device processing that still belongs in the privacy policy

The following are handled locally and should not be described as if they do not exist:

- mathematical, statistical, optimization, and financial-calculator inputs;
- calculation history, saved calculations, titles/notes/favorites, and compact result payloads;
- graph, matrix, LP/IP, and supported workspace records;
- theme, language, angle mode, precision, haptic, and sound preferences.

They are processed/stored on the device but are not currently transmitted to the developer.

## Manual copy/share actions

Copy writes selected result text to the system clipboard. Share actions invoke an Android chooser and transfer only the user-selected content to the app chosen by the user. Calcademy does not receive that data on a developer server. Recheck current Data Safety exemptions and every receiving/share SDK behavior before final submission.

## Deletion draft

- Individual saved/history items can be deleted where the UI provides the action.
- Saved Calculations supports delete/clear actions.
- Android Settings → Apps → Calcademy → Storage → Clear storage removes application-local data.
- Uninstalling removes application-local data, subject to Android backup/restore settings outside Calcademy's own backend because Calcademy has no backend copy.

Do not claim that server deletion is operational in 1.4.0+13. The in-app route
and public-page draft are foundations only; production account creation remains
blocked until secure backend deletion is deployed and verified.

## AdMob note (already integrated)

Google AdMob (banner only) is integrated as of 1.0.0+5. The answers above must be reconciled with Google's published [AdMob Data Safety guidance](https://support.google.com/admob/answer/9760862) and the plugin's declared data types before submission. Interstitial, rewarded, native ads, and mediation are **not** used and would each require a fresh re-evaluation.

## Mandatory re-evaluation triggers

Discard and redo this draft before releasing any version that adds:

- additional ad technology beyond the current AdMob banner (mediation, interstitial, rewarded, native);
- analytics, crash reporting, performance monitoring, or remote configuration;
- Firebase or another backend/cloud synchronization service;
- account creation, authentication, subscriptions, billing, or user profiles;
- network permission or any SDK that transmits data off device;
- remote support logging or telemetry;
- a webview controlled by Calcademy that collects user data.

## Final verification

- [ ] Inspect the final merged manifest and dependency tree.
- [ ] Review every SDK's current Data Safety disclosure.
- [ ] Confirm production behavior with network inspection where appropriate.
- [ ] Match the privacy policy, store listing, Ads declaration, and Data Safety form.
- [ ] Save a dated copy of submitted answers with the release record.

This is a technical draft, not legal advice or a guarantee of Play approval. Official documentation must be rechecked immediately before upload.

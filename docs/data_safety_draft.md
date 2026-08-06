# Google Play Data Safety Draft

## 1.8.0 (build 20) — the answers to actually submit

**Declare what this build does, not what the codebase can do.** 1.8.0+20 is
compiled without Supabase config, so accounts, subscriptions, the assistant, and
the camera solver do not exist in it — not as dormant code paths, but as
surfaces the user cannot reach and network calls that are never made. Declaring
them would describe collection that does not happen, and that claim is the one
you would have to defend later.

What this build actually does: shows an AdMob banner on Home and Saved, gathers
advertising consent through UMP first, and keeps every calculation on the
device.

### Top-level

| Question | Answer | Why |
| --- | --- | --- |
| Does the app collect or share required user-data types? | **Yes** | Not by Calcademy's own features, but the AdMob SDK collects and shares advertising identifiers |
| Is all collected data encrypted in transit? | **Yes** | AdMob traffic is HTTPS |
| Do users have a way to request deletion? | See below | Calcademy holds no server-side user data in this build |

### Data types

Only one row is a yes.

| Data type | Collected | Shared | Notes |
| --- | --- | --- | --- |
| **Device or other IDs** | **Yes** | **Yes** | AdMob advertising ID and device identifiers, for advertising. Confirm the exact set against AdMob's current Data Safety guidance rather than from memory |
| Personal info (name, email, …) | No | No | No account exists in this build |
| Financial info | No | No | No purchase is possible; the Premium surface is compiled out |
| Location | No | No | No permission, no feature |
| Contacts, Messages, Calendar | No | No | Not accessed |
| Photos, videos, audio | No | No | Sharing a graph is user-initiated to an app of their choosing; nothing reaches a developer server |
| Files and docs | No | No | No upload |
| App activity | No | No | No analytics SDK |
| Web browsing | No | No | No browsing feature |
| App info and performance | No | No | No crash reporting |
| Other user-generated content | No | No | The assistant is local-only and compiled out of this build; this becomes **Yes** the day the Gemini build ships |

### Purpose and control for Device IDs

- Purpose: **Advertising or marketing**. Not analytics, not personalisation of
  app content, not fraud prevention on Calcademy's behalf.
- Whether to mark collection **optional**: users are asked through UMP and can
  decline, but declining yields non-personalised ads rather than no ad
  identifiers at all. Read the form's exact wording before choosing — "users can
  choose whether this data is collected" means something narrower than "users
  can decline personalisation".

### Deletion

Calcademy stores nothing on a server in this build. Calculations, history, and
saved work live only on the device and are removed by the in-app clear actions
or by uninstalling. Advertising identifiers are managed by the device's own
Android settings, not by Calcademy, so the app cannot delete them on request.

Answer the deletion question about **Calcademy's own** collection, not Google's.
Do not claim an account-deletion mechanism: there are no accounts here.

### Submitted answers — 2026-08-06

Recorded because the next release re-opens this form, and reconstructing why an
answer was chosen is harder than writing it down once.

**Device or other IDs** — the only data type declared.

| Field | Answer |
| --- | --- |
| Collected | Yes |
| Shared | Yes |
| Processed ephemerally | No |
| Required or optional | **Required** |
| Purposes (collection) | Advertising or marketing; Fraud prevention, security, and compliance |
| Purposes (sharing) | Advertising or marketing |

Every other data type: not collected, not shared.

**Why "required" rather than "users can choose".** The UMP prompt appears only
where consent law applies, and the Settings privacy-options row follows the same
rule — so most users have no in-app way to switch this off. Declaring it
optional would print "optional" on the store listing for every user, including
the ones who are never offered the choice. It understates an EEA user's control,
who does get a real prompt, but overstating control for everyone else is the
worse error.

**Why fraud prevention is a collection purpose but not a sharing purpose.** The
privacy policy already tells users that Google processes this data to serve,
measure, cap the frequency of, **and prevent fraud in** these ads; omitting it
here would put the two declarations in conflict. Sharing with ad partners,
though, is for serving and measurement — invalid-traffic detection is Google's
own processing, not an onward transfer.

**Not declared, and why:** app functionality (the ad ID is not needed by any
Calcademy feature), analytics (no SDK), personalisation (that field means
personalising *app content*, not ads), account management (no accounts in this
build).

**Account questions.** Users cannot sign in with externally created accounts:
No. A way to request data deletion: No — Calcademy holds nothing server-side in
this build, so there is nothing to request deletion of. That is not a withheld
right; it becomes Yes when the account build ships and `delete-account` is the
mechanism.

### Before submitting

- [ ] Answers describe build 20, not the repository.
- [ ] Device IDs confirmed against AdMob's current published guidance.
- [ ] The privacy policy URL in the form matches `AppMetadata.privacyPolicyUrl`.
- [ ] "Contains ads" is declared in App content.
- [ ] Re-open this form before the first build that ships accounts or the
      Gemini assistant — both change the answers, and Play expects the
      declaration to be correct *before* that version goes live.

## 1.7 entitlement backend foundation reassessment

Calcademy 1.7 adds source code for account-scoped subscription entitlement
records and an authenticated Supabase validation-function stub. When the
function is deployed and invoked, a Google Play purchase token may be sent over
TLS solely for validation. The full token is not logged, echoed, or stored
persistently; a SHA-256 hash and subscription status/audit metadata may be
retained and associated with the Supabase Auth user ID.

The backend may store profile email, user ID, product/base-plan identifiers,
subscription state, period timestamps, acknowledgement/renewal flags, and safe
validation events. Google Play continues to process payment/card information;
Calcademy does not receive card or bank details.

This foundation does not add Gemini, camera access, OCR, image upload,
analytics, crash reporting, cloud Saved sync, or external payment. The final
Play Data Safety form must be re-evaluated after staging deployment and again
before real Developer API validation or production sales.

> **1.6.0+16 Play Billing foundation note:** The Android build includes the
> official Google Play Billing client and can run license-tester transactions.
> Subscription purchases are processed by Google Play. The client models a
> future authenticated entitlement-validation request, but the default service
> is a non-networking stub: no purchase token is persisted and no durable
> Premium entitlement is granted. Before production sales, reassess financial
> information/purchase-history declarations against the exact Play transaction
> and backend implementation. Gemini and camera/OCR remain inactive, and there
> are no external payment links.

> **1.5.0+14 staging Auth note:** When Supabase runtime configuration is present,
> email address and Auth user ID are transmitted to Supabase for account
> management and app functionality. Authenticated account deletion is available
> through a server-side Edge Function. Core tools remain usable without an
> account. Play Billing, Gemini, camera/OCR, cloud Saved sync, analytics, and
> crash reporting remain absent.

> **1.4.0+13 historical foundation note:** That build contained config-gated
> email/password Auth client code and account UI, but its deletion backend was
> not operational. The 1.5 note above supersedes that behavior.

> **1.3.0+12 Premium Architecture note:** This build adds architecture and
> coming-soon UI only. It has no real account creation, purchase flow, Gemini
> API, camera/OCR, image upload, or new data collection. Mock entitlement and
> usage state remain local.

> **1.2.0+11 AI Assistant note:** AI Assistant Foundation is local-only in
> 1.2.0+11. No prompts are sent to an external AI provider in this build. The
> feature adds no camera/OCR access, backend, account, analytics, or persistent
> chat history. Existing AdMob data handling remains unchanged.

> **Branch-scoped draft (`feature/supabase-staging-auth-deletion`,
> 1.5.0+14).** Recheck
> the final AAB and current Google/AdMob disclosures immediately before Play
> Console submission.
> See `docs/monetization_strategy.md`.

This worksheet reflects 1.5.0+14 with the **Google AdMob banner SDK**, a
config-gated Supabase Auth client, and an account-deletion Edge Function client.
Classify the release based on whether Auth runtime configuration is enabled in
the exact AAB. Play Billing, cloud Saved sync, analytics, crash reporting,
Gemini, and camera/OCR remain absent.

Google defines data collection for this form around data transmitted off the device. Data processed only on the device generally does not need to be disclosed as collected. Even apps declaring no collection must complete the form for applicable Play tracks and provide a privacy-policy link. See the [official Data Safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469).

## Proposed top-level answers

| Question area | Current draft | Evidence / caveat |
| --- | --- | --- |
| Does the app collect required user-data types? | Yes (via AdMob) | Calcademy's own features are on-device, but the Google AdMob SDK collects device/advertising identifiers and related data. Confirm the exact categories from AdMob's current disclosure |
| Does the app share user data with third parties? | Yes | Ad/device identifiers are shared with Google/AdMob and its ad partners for advertising |
| Is all transmitted data encrypted in transit? | Yes | AdMob traffic uses HTTPS; confirm against AdMob's current disclosure |
| Does the app provide a deletion mechanism? | Yes | In-app authenticated account deletion; email request path; local Saved deletion/clear app storage/uninstall; ad identifiers remain device-managed |
| Is account deletion offered? | Yes when Auth is configured and the Edge Function is deployed | In-app confirmation invokes server-side Auth deletion; public page must be published and verified before Play submission |

Do not present **Not applicable** as a substitute if Play Console asks a differently scoped mandatory yes/no question; follow the current form wording.

## Data-type worksheet

| Data type | Collected by developer? | Shared? | Current behavior |
| --- | --- | --- | --- |
| Personal information | Conditional | Supabase as service provider when Auth is enabled | Email address, Auth user ID, and authentication/security metadata are transmitted only when runtime Auth configuration and account creation are enabled; absent config means no Auth transmission |
| Financial information | Recheck for 1.7/backend testing | Google Play processes subscription purchases | Calcademy does not collect card or bank details. When configured and deployed, the validation stub can receive a purchase token, retain only its hash and safe subscription/audit metadata, and associate that state with the account. Real Google validation remains disabled, so the final Data Safety classification must be reviewed again when it is implemented |
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

The 1.5 client and Edge Function source implement server deletion, but the exact
staging/production deployment and public GitHub Pages URL must still be verified
before Play submission. Local-only Saved data remains device-managed.

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

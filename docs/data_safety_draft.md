# Google Play Data Safety Draft

This worksheet reflects the current Calcademy build only: no production Internet permission, account, backend, cloud synchronization, advertising, analytics, or crash-reporting SDK. Re-audit the exact final AAB and all transitive SDKs before submitting the form.

Google defines data collection for this form around data transmitted off the device. Data processed only on the device generally does not need to be disclosed as collected. Even apps declaring no collection must complete the form for applicable Play tracks and provide a privacy-policy link. See the [official Data Safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469).

## Proposed top-level answers

| Question area | Current draft | Evidence / caveat |
| --- | --- | --- |
| Does the app collect required user-data types? | No | Inputs and saved calculations are processed/stored on device only |
| Does the app share user data with third parties? | No | No automatic third-party transfer or SDK collection detected |
| Is all transmitted data encrypted in transit? | Not applicable | Current production build has no network permission or developer-controlled transmission |
| Does the app provide a deletion mechanism? | Local deletion is available | Delete/clear Saved Calculations, clear app storage, or uninstall |
| Is account deletion offered? | Not applicable | No account creation or server-side account data |

Do not present **Not applicable** as a substitute if Play Console asks a differently scoped mandatory yes/no question; follow the current form wording.

## Data-type worksheet

| Data type | Collected by developer? | Shared? | Current behavior |
| --- | --- | --- | --- |
| Personal information | No | No | No name, email, address, user ID, or account system |
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
| Device identifiers | No | No | No ads/analytics SDK or identifier collection detected |

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

Do not claim a server deletion-request service: no server-side collection or account currently exists.

## Mandatory re-evaluation triggers

Discard and redo this draft before releasing any version that adds:

- AdMob, mediation, advertising ID, or other ad technology;
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

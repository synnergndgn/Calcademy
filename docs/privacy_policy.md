# Calcademy Privacy Policy

> **1.5.0+14 staging Auth update (2026-08-03):** Calcademy supports optional
> Supabase email/password accounts when runtime configuration is supplied. Core
> tools remain available without an account. Auth account deletion is handled
> by a server-side Edge Function, and the public deletion page source is in
> `docs/`. The older internal-test status below remains release history.

**Status:** Current for Calcademy **1.0.0 (build 8)**, the build distributed through Google Play **internal testing**. This build displays banner advertisements through the Google AdMob SDK. Consent (Google UMP) is **not** implemented in this build; see “Advertising (Google AdMob)” below.

**Developer/publisher name:** `Ali Gündoğan`

**Effective date:** `2026-08-03`

**Contact email:** `calcademyapp@gmail.com`

**Public policy URL:** `https://synnergndgn.github.io/Calcademy/privacy_policy`

**Jurisdiction/legal address:** `Nilüfer/Bursa Türkiye`

The publisher, contact, effective-date, and jurisdiction details must be reverified during final legal and store review before a production release.

## Which versions this policy covers

| Version | Distribution | Advertising |
|---|---|---|
| 1.5.0 (build 14) | Staging Auth / pre-production | Google AdMob banner on Home and Saved; optional Supabase email auth and authenticated account deletion when configured |
| 1.4.0 (build 13) | Auth foundation / pre-production | Google AdMob banner on Home and Saved; optional Supabase email auth only when configured |
| 1.0.0 (build 8) | Play internal testing | Google AdMob banner on Home and Saved |
| Earlier builds | not publicly distributed | no ads SDK |

Advertising applies to the build described above. Calculation, graph, matrix, and optimization screens do not display ads in any build.

## In-app access

Calcademy includes a localized **About & Legal** screen with an on-device summary of current data handling, local storage, the Google AdMob disclosure, educational use, and the financial disclaimer. It is reachable from Home and Settings and provides an external-browser action for the public policy URL.

The local summary remains available alongside the public policy link. The production Android manifest for build 8 requests the `INTERNET` and `ACCESS_NETWORK_STATE` permissions, which the Google AdMob SDK requires to fetch banner ads.

## What Calcademy does

Calcademy is an academic calculation application for mathematics, statistics, finance, optimization, and operations research. Calculations are performed on the device.

## Data stored on the device

Calcademy may store the following locally with Android application storage and SharedPreferences:

- application preferences such as theme, language, angle mode, precision, haptic feedback, and key sound;
- calculation history and user-selected saved calculations;
- saved graph, matrix, and optimization workspaces supported by the current application;
- titles, notes, favorites, compact input/result summaries, and timestamps attached to saved items.

This local calculation and Saved information is not uploaded to a Calcademy
server. Calcademy has no cloud synchronization, analytics SDK, or crash-reporting
SDK. Version 1.5 can use optional Supabase Auth for account management, and the
app integrates the **Google AdMob** advertising SDK (see “Advertising” below).

Calcademy does process user-entered expressions, values, matrices, models, notes, and result data locally to provide its calculation and saved-work features. “No developer collection” does not mean that the app performs no data processing on the device, nor that Google AdMob performs no processing for advertising.

## Optional account authentication

This section supersedes legacy “no account or login” release-history statements
for 1.5.0+14.

Calcademy 1.5 includes a config-gated Supabase Auth client. When configuration
is absent, no account request is sent and auth controls display a disabled
state. If account creation is later enabled, Supabase will process the email
address, Auth user ID, password-authentication data, session tokens, and related
security metadata needed to provide the account. Calcademy does not store the
password as readable text. The Auth Foundation does not upload calculation or
local Saved content and does not enable cloud synchronization.

Only a public client key may be present in the mobile app. Privileged server
credentials remain backend-only. Accounts are optional: Calculator, Formula
Library, local AI Assistant, Saved, and the other core tools do not require
sign-in.

## Advertising (Google AdMob)

Calcademy displays banner advertisements through the **Google AdMob** SDK, on the Home and Saved screens only. To serve, measure, cap the frequency of, and prevent fraud in these ads, Google and its ad partners may process data such as advertising and device identifiers, IP address, coarse/derived location, and general device information under [Google's own policies](https://policies.google.com/privacy). This processing is performed by Google/AdMob, not by a Calcademy server; Calcademy does not receive your calculations or saved work through it.

**Consent is not yet implemented in this build.** The Google User Messaging Platform (UMP) consent flow is not present in build 8. Because of this, the build is limited to Play internal/closed testing and is **not** released in regions that require a consent mechanism (for example the EEA, UK, and Switzerland). A UMP consent/ad-choice flow will be implemented and verified before any production release, and this policy will be updated at that time. Until then, personalized advertising must not be assumed.

The third-party involved is **Google AdMob**. Calcademy does not add Firebase, Google Analytics, or any analytics/crash-reporting SDK.

## Network access and sharing

The production Android manifest requests the `INTERNET` and `ACCESS_NETWORK_STATE` permissions. These are used by the Google AdMob SDK to fetch ads. Debug/profile builds also use `INTERNET` for Flutter development tooling and are not store artifacts.

When a user explicitly chooses a system share action, Android may pass the selected text or generated graph image to an app chosen by the user. The receiving app's privacy policy then applies. Calcademy does not initiate that transfer without the user's action.

## Data deletion

Users can delete individual history/saved items and can use the available clear-all actions. All Calcademy data can also be removed through Android Settings by clearing application storage or uninstalling the app. Deleted local data cannot be restored by Calcademy because no cloud copy exists.

Advertising identifiers are controlled through Android system settings rather than through Calcademy.

## Account deletion

The app includes **Settings → Account → Delete account**. When Supabase is
configured and the user is signed in, explicit confirmation invokes a secure
Edge Function that derives the user ID from the verified session and deletes the
Auth user. The privileged key is not present in the mobile app. The public
[Calcademy account deletion page](account_deletion_request.md) also documents an
email request path. Limited legal, security, fraud-prevention, or transaction
records may be retained for a documented period when necessary.

Local-only Saved content is not available to the deletion server. It can be
removed by clearing Calcademy app data or uninstalling the app. No cloud Saved
sync exists in 1.5.

## Children and sensitive data

Calcademy is an academic tool and is not designed to collect personal or sensitive information. Users should not place personal, confidential, financial-account, or health information in titles, notes, expressions, or saved calculation fields.

## Financial disclaimer

Financial tools are provided for education and general calculation only. They are not financial, investment, tax, or legal advice. Results depend on user inputs and numerical methods.

## Future analytics or accounts

For 1.5.0+14, the optional Supabase Auth client described above supersedes the
legacy “no account SDK” statement in the historical paragraph below.

Calcademy contains banner advertising through Google AdMob and optional account
authentication through Supabase, but no analytics, crash-reporting, cloud Saved
sync, Play Billing, Gemini, or camera/OCR integration. If those services or
additional ad technologies (mediation, interstitial, rewarded, native) are
added, this policy and the applicable store Data Safety disclosures must be
updated before release. Where required, consent controls must be implemented
before collection begins.

## Changes

Material changes will be reflected by updating this policy's effective date and publication text.

## Publication checklist

- [x] Provide a monitored support/privacy contact address.
- [x] Confirm the publisher name and effective date for this release candidate.
- [x] Host the policy at a stable public HTTPS URL through GitHub Pages.
- [x] Disclose Google AdMob before distributing an ad-supported build.
- [ ] Record the same verified URL in Play Console and release records.
- [x] Provide accessible, localized in-app privacy/data-handling text without a broken external link.
- [x] Connect About & Legal to the public policy URL with safe failure feedback.
- [ ] Compare this policy with the exact final AAB, merged manifest, dependencies, Data Safety form, and Ads declaration.
- [ ] Implement UMP consent and update this policy before any production release.
- [ ] Publish `app-ads.txt` at the developer website root before production.
- [ ] Obtain legal review appropriate to the publisher and target jurisdictions where needed.
- [ ] Recheck the [official Google Play User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311) immediately before upload.

This document is a factual product description, not legal advice or a guarantee of compliance.

---

## Türkçe özet

Calcademy hesaplamaları cihazda yapar; ayarlar, geçmiş ve kaydedilen hesaplamalar
yalnızca uygulamanın yerel depolamasında tutulur. 1.5 sürümünde runtime config
verilmişse isteğe bağlı Supabase e-posta hesabı kullanılabilir; temel araçlar
hesap olmadan çalışır. Hesap silme, ayrıcalıklı anahtarı mobil uygulamaya
koymadan güvenli Edge Function üzerinden yapılır. Bulut Saved eşitleme,
analytics, crash-reporting, Play Billing, Gemini ve kamera/OCR yoktur.

Google Play dahili testine dağıtılan **1.0.0 (sürüm 8)** yapısı, **Google AdMob** SDK’sı aracılığıyla yalnızca Ana Sayfa ve Kayıtlı ekranlarında banner reklam gösterir. Hesaplama, grafik, matris ve optimizasyon ekranlarında reklam yoktur. Google/AdMob; reklamların sunulması, ölçülmesi ve sahtekârlığın önlenmesi için reklam/cihaz tanımlayıcıları, IP adresi ve benzeri verileri kendi politikaları kapsamında işleyebilir.

**Bu yapıda onay (UMP) mekanizması bulunmamaktadır.** Bu nedenle yapı yalnızca dahili/kapalı testle sınırlıdır ve onay mekanizması gerektiren bölgelerde (ör. AEA, Birleşik Krallık, İsviçre) yayınlanmamaktadır. Üretim sürümünden önce UMP onay akışı uygulanacak ve bu politika güncellenecektir. O zamana kadar kişiselleştirilmiş reklam varsayılmaz.

Ana manifest, AdMob’un reklam getirmesi için `INTERNET` ve `ACCESS_NETWORK_STATE` izinlerini ister. Kullanıcı sistem paylaşımını açıkça seçerse seçilen içerik kullanıcının tercih ettiği uygulamaya aktarılabilir. Kayıtlar uygulama içinden silinebilir; tüm veriler Android ayarlarından uygulama verisi temizlenerek veya uygulama kaldırılarak silinebilir. Reklam tanımlayıcıları Android sistem ayarlarından yönetilir. Ek reklam teknolojileri veya veri toplayan başka bir servis eklenmeden önce bu politika ve mağaza beyanları güncellenmelidir.

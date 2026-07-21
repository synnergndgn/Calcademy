# Calcademy Privacy Policy — Draft

**Status:** Public URL live on GitHub Pages; publisher metadata completed; final legal and store review pending

**Developer/publisher name:** `Ali Gündoğan`

**Effective date:** `2003-01-15`

**Contact email:** `calcademyapp@gmail.com`

**Public policy URL:** `https://synnergndgn.github.io/Calcademy/privacy_policy`

**Jurisdiction/legal address:** `Nilüfer/Bursa Türkiye`

This document describes Calcademy's current release candidate. The policy is published through GitHub Pages at the URL above. The publisher, contact, effective-date, and jurisdiction details must be reverified during final legal and store review before submission.

## In-app access

Calcademy includes a localized **About & Legal** screen with an on-device summary of current data handling, local storage, educational use, and the financial disclaimer. It is reachable from Home and Settings and provides an external-browser action for the verified public policy URL.

The local summary remains available alongside the public policy link. Opening the hosted page is a user-initiated external-browser action and does not require an Android INTERNET permission in Calcademy's main manifest.

## Public URL status

- Hosting: **GitHub Pages**
- Public HTTPS URL: `https://synnergndgn.github.io/Calcademy/privacy_policy`
- App integration: `AppMetadata.privacyPolicyUrl` and About & Legal external-browser action
- Play Console field: use the same URL after release-owner verification

The app validates the metadata as a non-empty public HTTPS URL and rejects common placeholder/example hosts. If the URL is removed or becomes invalid, the external action is hidden while the local privacy summary remains available. If advertising, analytics, cloud sync, accounts, or other data-affecting SDKs are introduced, update the hosted policy, this source document, Data Safety answers, and in-app wording before release.

## What Calcademy does

Calcademy is an academic calculation application for mathematics, statistics, finance, optimization, and operations research. Calculations are performed on the device.

## Data stored on the device

Calcademy may store the following locally with Android application storage and SharedPreferences:

- application preferences such as theme, language, angle mode, precision, haptic feedback, and key sound;
- calculation history and user-selected saved calculations;
- saved graph, matrix, and optimization workspaces supported by the current application;
- titles, notes, favorites, compact input/result summaries, and timestamps attached to saved items.

This information is not uploaded by Calcademy. There is currently no account, login, backend, cloud synchronization, advertising SDK, analytics SDK, or crash-reporting SDK.

Calcademy does process user-entered expressions, values, matrices, models, notes, and result data locally to provide its calculation and saved-work features. “No developer collection” does not mean that the app performs no data processing on the device.

## Network access and sharing

The production Android manifest does not request the Internet permission. Debug/profile builds use it only for Flutter development tooling and are not store artifacts.

When a user explicitly chooses a system share action, Android may pass the selected text or generated graph image to an app chosen by the user. The receiving app's privacy policy then applies. Calcademy does not initiate that transfer without the user's action.

## Data deletion

Users can delete individual history/saved items and can use the available clear-all actions. All Calcademy data can also be removed through Android Settings by clearing application storage or uninstalling the app. Deleted local data cannot be restored by Calcademy because no cloud copy exists.

## Children and sensitive data

Calcademy is an academic tool and is not designed to collect personal or sensitive information. Users should not place personal, confidential, financial-account, or health information in titles, notes, expressions, or saved calculation fields.

## Financial disclaimer

Financial tools are provided for education and general calculation only. They are not financial, investment, tax, or legal advice. Results depend on user inputs and numerical methods.

## Future advertising or analytics

Calcademy currently contains no ads or advertising identifiers. If advertising, analytics, cloud services, or accounts are added, this policy and the applicable store Data Safety disclosures must be updated before that version is released. Where required, consent controls must be implemented before collection begins.

## Changes

Material changes will be reflected by updating this policy's effective date and publication text.

## Publication checklist

- [x] Provide a monitored support/privacy contact address.
- [x] Confirm the publisher name and effective date for this release candidate.
- [x] Host the policy at a stable public HTTPS URL through GitHub Pages.
- [ ] Record the same verified URL in Play Console and release records.
- [x] Provide accessible, localized in-app privacy/data-handling text without a broken external link.
- [x] Connect About & Legal to the public policy URL with safe failure feedback.
- [ ] Compare this policy with the exact final AAB, merged manifest, dependencies, Data Safety form, and Ads declaration.
- [ ] Verify local deletion wording against the release UI.
- [ ] Obtain legal review appropriate to the publisher and target jurisdictions where needed.
- [ ] Recheck the [official Google Play User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311) immediately before upload.

This document is a factual product draft, not legal advice or a guarantee of compliance.

---

## Türkçe özet

Calcademy hesaplamaları cihazda yapar; ayarlar, geçmiş ve kaydedilen hesaplamalar yalnızca uygulamanın yerel depolamasında tutulur. Mevcut sürümde hesap, sunucu, bulut senkronizasyonu, reklam, analytics veya crash-reporting SDK’sı yoktur. Kullanıcı sistem paylaşımını açıkça seçerse seçilen içerik kullanıcının tercih ettiği uygulamaya aktarılabilir. Kayıtlar uygulama içinden silinebilir; tüm veriler Android ayarlarından uygulama verisi temizlenerek veya uygulama kaldırılarak silinebilir. Reklam veya veri toplayan bir servis eklenmeden önce bu politika ve mağaza beyanları güncellenmelidir.

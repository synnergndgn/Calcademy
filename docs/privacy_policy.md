# Calcademy Privacy Policy — Draft

**Status:** Draft — not ready for publication until every placeholder below is replaced

**Developer/publisher name:** `[REQUIRED — legal or verified publisher name]`

**Effective date:** `[REQUIRED — YYYY-MM-DD]`

**Contact email:** `[REQUIRED — monitored support/privacy email]`

**Public policy URL:** `[REQUIRED — stable public HTTPS URL]`

**Jurisdiction/legal address:** `[OPTIONAL OR REQUIRED BY APPLICABLE LAW/PUBLISHER TYPE]`

This draft describes Calcademy's current release candidate. It must be reviewed and published at a stable public URL before a store submission.

## In-app access

Calcademy includes a localized **About & Legal** screen with an on-device summary of current data handling, local storage, educational use, and the financial disclaimer. It is reachable from Home and Settings and does not expose a broken placeholder link.

This local summary improves user access but does not replace the complete policy that must be finalized and hosted at a stable public HTTPS URL for the Play Store release.

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

- [ ] Replace developer/publisher, effective date, contact, and public URL placeholders.
- [ ] Confirm the publisher name matches the Play Store listing.
- [ ] Host the complete policy at a stable HTTPS URL accessible without login.
- [x] Provide accessible, localized in-app privacy/data-handling text without a broken external link.
- [ ] Connect the app to the final public policy URL if required after that URL is published and verified.
- [ ] Compare this policy with the exact final AAB, merged manifest, dependencies, Data Safety form, and Ads declaration.
- [ ] Verify local deletion wording against the release UI.
- [ ] Obtain legal review appropriate to the publisher and target jurisdictions where needed.
- [ ] Recheck the [official Google Play User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311) immediately before upload.

This document is a factual product draft, not legal advice or a guarantee of compliance.

---

## Türkçe özet

Calcademy hesaplamaları cihazda yapar; ayarlar, geçmiş ve kaydedilen hesaplamalar yalnızca uygulamanın yerel depolamasında tutulur. Mevcut sürümde hesap, sunucu, bulut senkronizasyonu, reklam, analytics veya crash-reporting SDK’sı yoktur. Kullanıcı sistem paylaşımını açıkça seçerse seçilen içerik kullanıcının tercih ettiği uygulamaya aktarılabilir. Kayıtlar uygulama içinden silinebilir; tüm veriler Android ayarlarından uygulama verisi temizlenerek veya uygulama kaldırılarak silinebilir. Reklam veya veri toplayan bir servis eklenmeden önce bu politika ve mağaza beyanları güncellenmelidir.

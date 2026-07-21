# Calcademy Privacy Policy — Draft

**Effective date:** Replace before publication
**Contact:** Replace with the publisher's support email and postal/legal details before publication

This draft describes Calcademy's current release candidate. It must be reviewed and published at a stable public URL before a store submission.

## What Calcademy does

Calcademy is an academic calculation application for mathematics, statistics, finance, optimization, and operations research. Calculations are performed on the device.

## Data stored on the device

Calcademy may store the following locally with Android application storage and SharedPreferences:

- application preferences such as theme, language, angle mode, precision, haptic feedback, and key sound;
- calculation history and user-selected saved calculations;
- saved graph, matrix, and optimization workspaces supported by the current application;
- titles, notes, favorites, compact input/result summaries, and timestamps attached to saved items.

This information is not uploaded by Calcademy. There is currently no account, login, backend, cloud synchronization, advertising SDK, analytics SDK, or crash-reporting SDK.

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

---

## Türkçe özet

Calcademy hesaplamaları cihazda yapar; ayarlar, geçmiş ve kaydedilen hesaplamalar yalnızca uygulamanın yerel depolamasında tutulur. Mevcut sürümde hesap, sunucu, bulut senkronizasyonu, reklam, analytics veya crash-reporting SDK’sı yoktur. Kullanıcı sistem paylaşımını açıkça seçerse seçilen içerik kullanıcının tercih ettiği uygulamaya aktarılabilir. Kayıtlar uygulama içinden silinebilir; tüm veriler Android ayarlarından uygulama verisi temizlenerek veya uygulama kaldırılarak silinebilir. Reklam veya veri toplayan bir servis eklenmeden önce bu politika ve mağaza beyanları güncellenmelidir.

# Calcademy Privacy Policy

**Status:** Current for Calcademy **1.9.4 (builds 28–29)**, the offline,
accountless, ad-supported production release.

**Developer/publisher name:** `Ali Gündoğan`

**Effective date:** `2026-08-12`

**Contact email:** `calcademyapp@gmail.com`

**Public policy URL:** `https://gundev.dev/gizlilik/calcademy`

**Jurisdiction/legal address:** `Nilüfer/Bursa Türkiye`

This document is the repository's record of what the shipped application does.
The authoritative public text is the page at the URL above, in Turkish and
English. The two are maintained by hand and must be revised together.

> **Note on the former address.** `https://synnergndgn.github.io/Calcademy/privacy_policy`
> was the policy URL compiled into builds 1.0.0+5 through 1.7.0+18. Every build
> from 1.8.0+20 onward points at the developer domain, and the Play Console
> field names the developer domain. If the repository is made private the
> GitHub Pages copy stops resolving; that affects only the in-app button of
> those older builds, not the store-declared link.

## Which versions this policy covers

| Version | Distribution | Advertising and features |
|---|---|---|
| 1.9.4 (builds 28–29) | Google Play production | Google AdMob banner on Home and Saved, behind a UMP consent flow. No account, sign-in, subscription, remote AI or camera feature. |
| 1.8.0 (build 20) and earlier | closed/internal testing, superseded | See the release history in Git. Those builds variously included an optional Supabase account client, the Play Billing foundation and an entitlement backend stub. **None of that is present in 1.9.4.** |

Calculation, graph, matrix and optimization screens display no ads in any build.

## What Calcademy does

Calcademy is an academic calculation application for mathematics, statistics,
finance, optimization and operations research. Calculations are performed on the
device.

## Data stored on the device

Calcademy stores the following locally through Android application storage and
SharedPreferences:

- application preferences such as theme, language, angle mode, precision,
  haptic feedback and key sound;
- calculation history and user-selected saved calculations;
- saved graph, matrix and optimization workspaces;
- titles, notes, favorites, compact input/result summaries and timestamps
  attached to saved items.

Calcademy does not upload this content to its own server and offers no account
or cloud synchronization. The 1.9.4 Android configuration excludes application
data from Android Auto Backup, cloud backup and device-to-device transfer.
Uninstalling the app or clearing its storage through Android Settings removes
on-device Calcademy data, and Calcademy cannot restore it.

This claim rests on `android:allowBackup="false"`, the legacy full-backup
exclusions in `android/app/src/main/res/xml/backup_rules.xml` and the Android
12+ cloud-backup and device-transfer exclusions in
`android/app/src/main/res/xml/data_extraction_rules.xml`. Reverify the merged
manifest for every release.

Calcademy does process user-entered expressions, values, matrices, models, notes
and results locally to provide its features. "No developer collection" does not
mean the app performs no on-device processing, nor that Google AdMob performs
none for advertising.

## Advertising (Google AdMob)

Calcademy displays banner advertisements through the **Google AdMob** SDK, on
the Home and Saved screens only.

The Google Mobile Ads SDK may automatically collect and share with Google and
its advertising partners the IP address, an approximate location inference, app
interactions, diagnostic and performance information, and advertising, device
and account identifiers, for the purposes of serving ads, measurement and
analytics, frequency capping and fraud prevention. Transmission is protected by
Google using TLS. Calcademy does not attach the content of your calculations or
saved work to an ad request. This processing is performed by Google under
[Google's own policies](https://policies.google.com/privacy), not by a Calcademy
server.

**Consent (Google UMP).** Where consent is required, Google's
User Messaging Platform collects the user's choice before any ad is requested.
Declining
restricts the use of personalised advertising; it does not mean that all
technical processing — IP address, app interactions, diagnostic information and
fraud-prevention signals — stops. Where UMP reports that consent is required,
the choice can be reviewed or changed from **Ad privacy options** in Settings.
A change applies to the Google Mobile Ads SDK's subsequent eligible ad
operations. Nothing in Calcademy is withheld for declining, and no feature is
locked behind consent.

Where local law does not require consent, Google reports that none is needed and
no form is shown.

Calcademy does not add Firebase, Google Analytics, or any analytics or
crash-reporting SDK.

## Android permissions

The production Android manifest includes `INTERNET`, `ACCESS_NETWORK_STATE`, the
Google advertising identifier (`AD_ID`) and the Android Privacy Sandbox
ad-services permissions for ad delivery. The Google Mobile Ads SDK and Android
runtime components may also merge technical permissions such as `WAKE_LOCK` and
`FOREGROUND_SERVICE` into the merged manifest. The application requests no
access to the camera, microphone, location, contacts, calendar or device files.

## Clipboard and sharing

When the user chooses Copy or Share, the selected text may be written to the
system clipboard, or a generated graph image may be passed through the Android
share sheet to an application the user chooses. Calcademy does not send this
content to its own server; the operating system's and the receiving
application's own terms then apply. Calcademy never initiates that transfer
without the user's action.

## Data deletion

History and saved items can be cleared individually or, where offered, by
category from the relevant screens. The clear actions in Settings clear only the
data category named on screen. To remove all on-device Calcademy data, clear the
application storage through Android Settings or uninstall the app. Calcademy
application data is excluded from Android cloud backup and device-to-device
transfer.

There is no account and no server-side profile, so there is nothing to request
deletion of from a server.

Advertising identifiers are controlled through Android system settings rather
than through Calcademy.

## In-app access

Calcademy includes a localized **About & Legal** screen summarizing on-device
data handling, local storage, the Google AdMob disclosure, educational use and
the financial disclaimer. It is reachable from Home and Settings and provides an
external-browser action for the public policy URL.

## Children and sensitive data

Calcademy is an academic tool and is not designed to collect personal or
sensitive information. Users should not place personal, confidential,
financial-account or health information in titles, notes, expressions or saved
calculation fields.

## Financial disclaimer

Financial tools are provided for education and general calculation only. They
are not financial, investment, tax or legal advice. Results depend on user
inputs and numerical methods.

## Future features

Calcademy 1.9.4 contains no Supabase, no account or sign-in, no in-app purchase
or subscription, no remote AI, no camera and no analytics or crash-reporting
SDK. Sources for several of these remain in the repository for reference but are
excluded from the analyzer and are not linked into the release build; see
`docs/release_privacy_remediation_1.9.4_28.md`. If any of them is enabled in
future, this policy and the Google Play Data Safety declarations must be updated
before data processing begins and before that version is published. Where
required, consent controls must be implemented before collection begins.

## Changes

Material changes are reflected by updating this policy's effective date and
publication text, in both the repository copy and the published page.

## Publication checklist

- [x] Provide a monitored support/privacy contact address.
- [x] Confirm the publisher name and effective date for this release.
- [x] Host the policy at a stable public HTTPS URL on the developer domain.
- [x] Disclose Google AdMob before distributing an ad-supported build.
- [x] Record the same verified URL in Play Console and release records.
- [x] Provide accessible, localized in-app privacy/data-handling text without a broken external link.
- [x] Connect About & Legal to the public policy URL with safe failure feedback.
- [x] Implement UMP consent and update this policy before any production release.
- [x] Compare this policy with the exact final AAB, merged manifest, dependencies, Data Safety form and Ads declaration.
- [ ] Publish `app-ads.txt` at the developer website root.
- [ ] Obtain legal review appropriate to the publisher and target jurisdictions where needed.
- [ ] Recheck the [official Google Play User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311) immediately before each upload.

This document is a factual product description, not legal advice or a guarantee
of compliance.

---

## Türkçe özet

Bu politika Calcademy **1.9.4 (sürüm 28–29)** için geçerlidir. Bu sürüm,
çevrimdışı ve hesapsız çalışan hesaplama araçları ile Ana Sayfa ve Kayıtlı
ekranlarında Google AdMob banner reklamları içerir. Supabase, hesap oluşturma
veya oturum açma, uygulama içi satın alma/abonelik, uzaktan AI asistanı ve
kamera erişimi bu sürümde etkin değildir.

Hesaplamalar cihazda yapılır; ayarlar, geçmiş ve kaydedilen çalışmalar yalnızca
uygulamanın yerel depolamasında tutulur. Calcademy bu içeriği kendi sunucusuna
yüklemez ve bulut senkronizasyonu sunmaz. Uygulama verileri Android Auto Backup,
bulut yedeklemesi ve cihazdan cihaza aktarım kapsamı dışında tutulur; uygulama
kaldırıldığında veya Android Ayarlar üzerinden depolama temizlendiğinde
cihazdaki veriler kalır ve Calcademy tarafından geri getirilemez.

Google Mobile Ads SDK; reklam sunma, ölçüm/analiz, sıklık sınırlama ve
sahtekârlığı önleme amaçlarıyla IP adresi, yaklaşık konum çıkarımı, uygulama
etkileşimleri, tanılama ve performans bilgileri ile reklam/cihaz/hesap
tanımlayıcılarını otomatik olarak toplayabilir ve Google ile reklam
ortaklarıyla paylaşabilir. Aktarım Google tarafından TLS ile korunur. Calcademy,
kullanıcının hesaplama veya kayıtlı çalışma içeriğini reklam isteğine eklemez.

**Onay (Google UMP).** Onay gereken bölgelerde Google UMP kullanıcının seçimini
toplar. Seçimin reddedilmesi kişiselleştirilmiş reklam kullanımını sınırlar;
ancak IP adresi, uygulama etkileşimleri, tanılama bilgileri ve sahtekârlık
önleme sinyalleri gibi tüm teknik işlemenin durduğu anlamına gelmez. UMP
tarafından gerekli görüldüğünde Ayarlar içindeki
**Reklam gizlilik seçenekleri** bölümünden seçim yeniden görüntülenebilir veya
değiştirilebilir.
Değişiklik, Google Mobile Ads SDK'sının sonraki uygun reklam işlemlerine
uygulanır.

Üretim Android manifesti reklam sunumu için `INTERNET`, `ACCESS_NETWORK_STATE`,
Google reklam kimliği (`AD_ID`) ve Android Privacy Sandbox reklam servisleri
izinlerini içerir. Google Mobile Ads ve Android çalışma bileşenleri ayrıca
`WAKE_LOCK` ve `FOREGROUND_SERVICE` gibi teknik izinleri birleştirilmiş
manifeste ekleyebilir. Uygulama kamera, mikrofon, konum, kişi, takvim veya cihaz
dosyalarına erişim izni istemez.

Kullanıcı Kopyala veya Paylaş eylemini seçtiğinde, seçilen metin sistem panosuna
yazılabilir veya üretilen grafik görseli Android paylaşım seçicisiyle
kullanıcının seçtiği uygulamaya aktarılabilir. Calcademy bu içeriği kendi
sunucusuna göndermez; işletim sistemi ve alıcı uygulamanın kendi gizlilik
koşulları geçerlidir.

Geçmiş ve kayıtlı öğeler ilgili ekranlardaki silme eylemleriyle temizlenebilir;
Ayarlar'daki temizleme eylemleri yalnızca ekranda belirtilen veri kategorisini
temizler. Tüm cihaz içi verileri kaldırmak için Android Ayarlar üzerinden
uygulama depolaması temizlenebilir veya uygulama kaldırılabilir. Hesap ve sunucu
profili bulunmadığından sunucudan silinmesi istenecek bir veri yoktur. Reklam
tanımlayıcıları Android sistem ayarlarından yönetilir.

Calcademy akademik bir araçtır ve kişisel ya da hassas bilgi toplamak üzere
tasarlanmamıştır. Finans araçları yalnızca eğitim ve genel hesaplama içindir;
yatırım, vergi veya hukuk tavsiyesi değildir. Yeni bir veri işleyen özellik
etkinleştirilmeden önce bu politika ve Google Play Veri Güvenliği beyanları
güncellenecektir.

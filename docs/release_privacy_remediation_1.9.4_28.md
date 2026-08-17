# Calcademy 1.9.4+28 — Release Privacy Remediation

**Prepared:** 2026-08-12  
**Release profile:** offline, accountless, AdMob-supported  
**Live policy checked:** https://gundev.dev/gizlilik/calcademy

## Release artifact result

- Removed direct `supabase_flutter` and `in_app_purchase` dependencies.
- Removed Supabase initialization and account/Premium/AI/Camera routes from the release app.
- Removed account and Premium entry points from Settings and Home.
- Removed Premium entitlement gating from the AdMob banner.
- Generated release AAB: `build/app/outputs/bundle/release/app-release.aab`.
- Version: `1.9.4+28` (`versionName 1.9.4`, `versionCode 28`).
- Size: `65,949,451` bytes (`62.9 MB` as reported by Flutter).
- SHA-256: `FE0ADA777858D29688B8B2A27D6DC44BC8E56FFE0A0035D75E85BF2A662AD623`.
- Release merged manifest contains no `com.android.vending.BILLING`, Billing component, Supabase marker or App Links plugin marker.
- Release merged manifest contains `android:allowBackup="false"` and references both packaged backup-rule resources.
- AdMob application ID and advertising permissions remain present.
- `flutter analyze --no-pub`: no issues.
- Active release regression suite: 112 tests passed; the final backup/version/About verification added another 24 passing tests.

Dormant/future feature sources are retained for reference but excluded from the release application and analyzer. The shipped dependency graph and generated plugin registry do not contain Supabase or Play Billing.

## Live privacy page — required changes

Apply every substantive change to both the Turkish and English versions. Set the effective/update date to the actual publication date.

### 1. Version scope and release table

Replace every `1.8.0 (sürüm 20)` reference with `1.9.4 (sürüm 28)` and replace the current release-table row with:

> **1.9.4 (sürüm 28) — Google Play dağıtımı — Ana Sayfa ve Kayıtlı ekranlarında Google AdMob banner reklamları; hesap, oturum açma, abonelik, uzaktan AI ve kamera özelliği yoktur.**

Suggested opening paragraph:

> Bu politika Calcademy 1.9.4 (sürüm 28) için geçerlidir. Bu sürüm çevrimdışı ve hesapsız çalışan hesaplama araçları ile Ana Sayfa ve Kayıtlı ekranlarında Google AdMob banner reklamları içerir. Supabase, hesap oluşturma veya oturum açma, uygulama içi satın alma/abonelik, uzaktan AI asistanı ve kamera erişimi bu sürümde etkin değildir.

### 2. Local data and Android system backup

Keep the existing local-data inventory, but replace the absolute “only on the device / no cloud copy” language with:

> Calcademy bu içeriği kendi sunucusuna yüklemez ve hesap ya da bulut senkronizasyonu sunmaz. Calcademy 1.9.4 (sürüm 28) Android yapılandırması, uygulama verilerini Android Auto Backup, bulut yedeklemesi ve cihazdan cihaza veri aktarımı kapsamı dışında tutar. Uygulama kaldırıldığında veya Android Ayarlar üzerinden uygulama depolaması temizlendiğinde cihazdaki Calcademy verileri kaldırılır ve Calcademy tarafından geri getirilemez.

This claim is backed by `android:allowBackup="false"`, legacy full-backup exclusions, Android 12+ cloud-backup exclusions and Android 12+ device-transfer exclusions. Reverify the merged manifest for every release.

### 3. AdMob data categories

Replace the sentence that lists only identifiers, IP, approximate location and general device data with:

> Google Mobile Ads SDK; reklam sunma, ölçüm/analiz, sıklık sınırlama ve sahtekârlığı önleme amaçlarıyla IP adresi, yaklaşık konum çıkarımı, uygulama etkileşimleri, tanılama ve performans bilgileri ile reklam/cihaz/hesap tanımlayıcılarını otomatik olarak toplayabilir ve Google ile reklam ortaklarıyla paylaşabilir. Aktarım Google tarafından TLS ile korunur. Calcademy, kullanıcının hesaplama veya kayıtlı çalışma içeriğini reklam isteğine eklemez.

### 4. Consent wording

Remove these absolute claims:

- rejecting consent means no data is written to or read from the device for advertising;
- changing consent takes effect instantly without restarting the app.

Use this narrower wording:

> Onay gereken bölgelerde Google UMP kullanıcının seçimini toplar. Seçimin reddedilmesi kişiselleştirilmiş reklam kullanımını sınırlar; ancak IP adresi, uygulama etkileşimleri, tanılama bilgileri ve sahtekârlık önleme sinyalleri gibi tüm teknik işlemenin durduğu anlamına gelmez. UMP tarafından gerekli görüldüğünde Ayarlar içindeki Reklam gizlilik seçeneklerinden seçim yeniden görüntülenebilir veya değiştirilebilir. Değişiklik, Google Mobile Ads SDK'sının sonraki uygun reklam işlemlerine uygulanır.

### 5. Android permissions

Replace the claim that the production manifest only requests `INTERNET` and `ACCESS_NETWORK_STATE` with:

> Üretim Android manifesti reklam sunumu için `INTERNET`, `ACCESS_NETWORK_STATE`, Google reklam kimliği (`AD_ID`) ve Android Privacy Sandbox reklam servisleri izinlerini içerir. Google Mobile Ads ve Android çalışma bileşenleri ayrıca `WAKE_LOCK` ve `FOREGROUND_SERVICE` gibi teknik izinleri birleştirilmiş manifeste ekleyebilir. Uygulama kamera, mikrofon, konum, kişi, takvim veya cihaz dosyalarına erişim izni istemez.

### 6. Data deletion

Replace “all current clear actions” and “uninstall removes everything because there is no cloud copy” with:

> Geçmiş ve kayıtlı öğeler ilgili ekranlardaki mevcut silme eylemleriyle tek tek veya desteklenen kategori kapsamında temizlenebilir. Ayarlar'daki temizleme eylemleri yalnızca ekranda belirtilen veri kategorisini temizler. Tüm cihaz içi Calcademy verilerini kaldırmak için Android Ayarlar üzerinden uygulama depolaması temizlenebilir veya uygulama kaldırılabilir. Calcademy uygulama verileri Android bulut yedeklemesi ve cihazdan cihaza aktarım kapsamı dışında tutulur.

### 7. Clipboard and sharing

Append to the sharing section:

> Kullanıcı Kopyala veya Paylaş eylemini seçtiğinde, seçilen metin sistem panosuna yazılabilir veya üretilen grafik görseli Android paylaşım seçicisiyle kullanıcının seçtiği uygulamaya aktarılabilir. Calcademy bu içeriği kendi sunucusuna göndermez; işletim sistemi ve alıcı uygulamanın kendi gizlilik koşulları geçerlidir.

### 8. Future-features section

Replace the current generic future paragraph with:

> Calcademy 1.9.4 (sürüm 28); Supabase, hesap/oturum, uygulama içi satın alma veya abonelik, uzaktan AI, kamera, analytics ya da çökme raporlama SDK'sı içermez. Bu özelliklerden biri gelecekte etkinleştirilirse, veri işleme başlamadan ve ilgili sürüm yayımlanmadan önce bu politika ile Google Play Veri Güvenliği beyanları güncellenecektir.

## Google Play Data Safety changes

For the exact AAB above, reconcile the Play Console form with Google Mobile Ads SDK disclosure. At minimum review and declare:

- **App activity / App interactions:** collected and shared by AdMob; purposes include advertising/marketing, analytics and fraud prevention/security.
- **App info and performance / Diagnostics:** collected and shared by AdMob; purposes include analytics and fraud prevention/security.
- **Device or other IDs:** collected and shared by AdMob; advertising/marketing, analytics and fraud prevention/security.
- **Approximate location:** review as derived from IP under the current Google disclosure and Console taxonomy.
- **Data encrypted in transit:** yes for Google Mobile Ads SDK transfers.
- **Account creation:** no.
- **Data deletion request:** no account/server profile exists; describe on-device deletion and Android backup management accurately.
- **Contains ads:** yes.

Do not declare calculations, saved workspaces, notes or favorites as developer-collected server data: the app processes these locally and does not put their contents into AdMob requests.

## Remaining release blockers

Removing Billing/Supabase and disabling Android backup resolve the two code/artifact risks. The wider-release decision remains blocked until the live publication task below is completed:

1. Publish the corrected live policy in Turkish and English, including the verified no-backup posture and complete AdMob categories.

The owner reports that the Play Console Data Safety form has been corrected. Preserve an export or screenshots of the submitted answers with the release evidence.

## 1.9.4+29 rebuild (2026-08-17)

The build 28 artifact above was produced from an uncommitted working tree, so
it could not be reproduced from the repository. Everything it depended on is
now committed, and the artifact was rebuilt from that committed state. Build 28
is the approved production upload, so the rebuild takes the next versionCode.

- Version: `1.9.4+29` (`versionName 1.9.4`, `versionCode 29`), confirmed in the
  merged manifest rather than only in `pubspec.yaml`.
- Size: `65,949,486` bytes (`62.9 MB` as reported by Flutter).
- SHA-256: `8309585E62B952A57B8E3C6C2173B295ADE248BF2605AD02ED6724A3334D7477`.
- Merged manifest permissions, exactly: `INTERNET`, `ACCESS_NETWORK_STATE`,
  `com.google.android.gms.permission.AD_ID`, `ACCESS_ADSERVICES_AD_ID`,
  `ACCESS_ADSERVICES_ATTRIBUTION`, `ACCESS_ADSERVICES_TOPICS`, `WAKE_LOCK`,
  `FOREGROUND_SERVICE` — the set the published policy names, with nothing else.
- Merged manifest contains `android:allowBackup="false"` and references both
  packaged backup-rule resources.
- No `com.android.vending.BILLING`, Billing component or Supabase marker.
- `flutter analyze --no-pub`: no issues. `flutter test`: 733 passing, none
  skipped or excluded at the runner level.

The only behavioural difference from build 28 is none: the sole source change
in the binary is the corrected `privacyPolicyEffectiveDate` constant, which
nothing renders.

Outstanding before upload: the published page still scopes itself to build 28
and needs widening to builds 28–29 to match `docs/privacy_policy.md`.

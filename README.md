# Calcademy

**Calculate. Visualize. Optimize. Learn.**

![Calcademy logosu](assets/branding/calcademy_logo.svg)

Calcademy; matematik, istatistik, finans ve yöneylem araştırması problemlerini tek bir çevrimdışı çalışma alanında birleştiren, Flutter ile geliştirilmiş akademik hesaplama platformudur. Uygulama; güvenilir sayısal sonuç, açık yöntem bilgisi, responsive kullanım ve cihaz içi veri gizliliğine odaklanır.

Android release identity: `com.aligundogan.calcademy` · Publisher: Ali Gündoğan

## Aktif çalışma alanları

| Kategori | Modüller |
| --- | --- |
| Matematik | Bilimsel Hesap Makinesi, Grafik Çizici, Matrisler ve Lineer Cebir, Denklem Çözücü, Calculus |
| Optimizasyon ve Yöneylem Araştırması | Lineer Programlama, Tam Sayılı Programlama, Operations Research |
| Veri ve İstatistik | Statistics |
| Finans | Financial Calculator |
| Referans | Formula Library |
| Yardımcı | Calcademy Assistant (varsayılan lokal; isteğe bağlı Gemini destekli gelişmiş mod) |
| Çalışma Alanı | Saved Calculations |

Camera Solver rotası mevcuttur ancak henüz bir placeholder ekranıdır: kamera
izni, OCR ve görüntü yükleme bu sürümde yoktur.

Home ekranı modülleri bu bilgi mimarisine göre gruplar. Lokalize arama; modül adı, açıklaması ve kategori üzerinden çalışır. Telefonlarda tek sütun, tablet ve masaüstünde responsive grid kullanılır.

## Öne çıkan yetenekler

- Bilimsel ifade değerlendirme, DEG/RAD, `Ans`, geçmiş ve haptic/key sound ayarları
- Adaptif örnekleme, pan/zoom ve cihaz içi grafik çalışma alanları
- Matris işlemleri, Gauss/Gauss-Jordan adımları ve lineer sistem sınıflandırması
- Analitik ve sayısal denklem çözümü; türev, integral ve fonksiyon analizi
- Betimsel istatistik, olasılık dağılımları ve güven aralıkları
- TVM, nakit akışı, kredi amortismanı ve başabaş analizi
- Simpleks tabanlı LP, Branch-and-Bound tabanlı IP
- Transportation, Assignment, Weighted Goal Programming ve CPM/PERT
- Modüller arası ortak, sürümlenmiş ve boyut limitli Saved Calculations kayıtları
- Home ve Ayarlar üzerinden erişilebilen, lokalize Hakkında ve Yasal Bilgiler alanı
- Türkçe/İngilizce, Material 3 light/dark tema ve çevrimdışı çalışma

## Mimari

Proje feature-first düzeni kullanır. Matematiksel modeller ve çözücüler UI katmanından ayrıdır; Riverpod controller/state akışını, repository katmanı ise yerel kalıcılığı yönetir.

```text
lib/
├── app/                    # Uygulama, router, navigation ve design token'ları
│   ├── ads/                # AdBanner ve AdMob başlatma koruması
│   ├── auth/               # Supabase/local auth repository ve controller'ları
│   ├── billing/            # Play Billing repository, controller ve state
│   ├── config/             # Derleme zamanı runtime config (SUPABASE_URL vb.)
│   └── premium/            # Entitlement, feature gate ve kullanım kotaları
├── core/                   # Ortak servisler ve yeniden kullanılabilir UI
├── features/
│   ├── calculator/
│   ├── graph/
│   ├── matrix/
│   ├── equation_solver/
│   ├── calculus/
│   ├── statistics/
│   ├── financial_calculator/
│   ├── linear_programming/
│   ├── integer_programming/
│   ├── operations_research/
│   ├── formula_library/
│   ├── ai_assistant/
│   ├── camera_solver/      # Placeholder ekran
│   ├── account/
│   ├── premium/
│   └── saved_calculations/
└── l10n/                   # TR/EN kullanıcı metinleri

supabase/
├── migrations/             # Profil, entitlement, satın alma ve kota şeması
└── functions/
    ├── delete-account/
    └── validate-play-purchase/
```

### Tasarım sistemi

Material 3 `ColorScheme`, ortak spacing/radius/breakpoint değerleri ve tema türevi yüzeyler kullanılır. Ortak section header, empty state, status banner ve result action bar bileşenleri; light/dark temada tutarlı hiyerarşi sağlar. Ana etkileşimler en az 48 dp dokunma alanını, 320 px genişliği ve %200 metin ölçeğini hedefler.

## Teknoloji

- Flutter / Dart
- Riverpod
- go_router
- SharedPreferences
- fl_chart
- flutter_svg
- share_plus
- supabase_flutter (Auth ve entitlement; yalnızca runtime config verildiğinde)
- in_app_purchase (Google Play Billing)
- google_mobile_ads (Home ve Saved banner)

Matematik ifadeleri `eval` kullanmadan kontrollü lexer/parser katmanlarında işlenir. Büyük veya sayısal olarak riskli problemler merkezi limit ve toleranslarla sınırlandırılır.

## Saved Calculations

Başarılı sonuçlar desteklenen modüllerden ortak Saved Calculations repository’sine kaydedilebilir. Kayıtlar; modül, hesaplama tipi, giriş/sonuç özeti, küçük sürümlenmiş payload, zaman damgası ve favori durumunu içerir. Arama, modül filtresi, sıralama, favori, kopyalama ve silme cihaz içinde çalışır. Saved Calculations için bulut senkronizasyonu yoktur; kayıtlar yalnızca cihazda tutulur ve hesaba bağlanmaz.

## Operations Research

- Transportation: North-West Corner, Least Cost ve MODI/U-V; dengeli/dengesiz problem desteği
- Assignment: Hungarian algoritması; kare/dikdörtgen ve min/max modeller
- Weighted Goal Programming: hard constraint, hedef ilişkisi ve sapma ağırlıkları
- CPM/PERT: activity-on-node ağları, forward/backward pass, bolluk ve kritik yol

Başlangıç feasible transportation çözümü optimal olarak etiketlenmez; dummy satır/sütun ve limit durumları kullanıcıya açıkça bildirilir.

## Çalıştırma

Gereksinimler: Flutter 3.44 veya uyumlu kararlı sürüm, Dart 3.12+, Android SDK.

```bash
flutter pub get
flutter run
```

## Test ve kalite kapısı

Unit testler domain servislerini, solver sonuçlarını, validation ve kayıt adapter’larını; widget testleri navigasyon, form/result akışları, copy/save eylemleri, dark mode ve responsive geometrileri kapsar. 1.7.0+18 tabanında 664 test geçmektedir.

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test --concurrency=1
flutter build apk --debug
git diff --check
```

## Hesap, Premium ve reklamlar

Calcademy giriş yapmadan kullanılabilir. Hesap yalnızca abonelik işlemleri ve
kalıcı Premium hakkı için gereklidir; tüm hesaplama modülleri, Formula Library,
yerel Saved kayıtları ve lokal Assistant hesapsız çalışır.

- **Auth:** İsteğe bağlı Supabase e-posta hesabı. `SUPABASE_URL` ve
  `SUPABASE_ANON_KEY` derleme zamanı tanımlanmadıysa hiçbir Auth trafiği
  oluşmaz. Hesap silme, ayrıcalıklı anahtar mobil uygulamaya konmadan
  `delete-account` Edge Function'ı üzerinden yapılır.
- **Billing:** `in_app_purchase` ile Google Play aboneliği. İstemcideki
  `purchased`/`restored` durumu tek başına Premium açmaz.
- **Entitlement:** Üretim Premium durumunun tek kaynağı, giriş yapılmış hesabın
  Supabase entitlement kaydıdır (`get_my_premium_status()`). Yalnızca geçerli
  dönem sonuna sahip `active` ve `grace_period` kayıtları Premium sayılır.
- **Doğrulama:** `validate-play-purchase` fonksiyonu bu sürümde güvenli bir
  iskelettir; kimlik doğrular, satın alma tokenını SHA-256 ile özetler, denetim
  kaydı yazar ve `unsupported` döner. Gerçek Google Play Developer API
  doğrulaması henüz uygulanmamıştır.
- **Reklamlar:** Banner yalnızca Home ve Saved ekranlarında gösterilir.
  Hesaplama, grafik, matris ve optimizasyon ekranları reklamsızdır. Aktif bir
  backend entitlement'ı bu banner'ları gizler.
- **Gelişmiş asistan:** Cihaz dışına metin gönderen tek özellik. Dört koşulun
  tamamı gerekir — Supabase config, giriş yapılmış hesap, aktif Premium hakkı ve
  kullanıcının Ayarlar'dan verdiği açık onay. Varsayılan kapalıdır; her koşul her
  istekte yeniden değerlendirilir. Kota, doğrulama ve model çıktısı filtreleme
  sunucu tarafındadır; her hata durumunda lokal kural motoruna düşülür.

Ayrıntı: [Premium mimarisi](docs/premium_architecture.md),
[entitlement şeması](docs/supabase_entitlement_schema.md),
[Play Billing backend doğrulaması](docs/play_billing_backend_validation.md),
[Gemini destekli asistan](docs/ai_assistant_gemini.md).

## Gizlilik ve release yaklaşımı

Hesaplamalar cihazda yapılır; ayarlar, geçmiş ve kaydedilen hesaplamalar yalnızca uygulamanın yerel depolamasında tutulur ve hiçbir zaman asistana gönderilmez. Bulut Saved eşitleme, analytics, crash-reporting ve kamera/OCR yoktur. Gelişmiş asistan açıkken yalnızca kullanıcının yazdığı soru metni cihazdan çıkar; Calcademy bu metni ve yanıtı saklamaz. Lokalize Hakkında ve Yasal Bilgiler ekranı bu yaklaşımı uygulama içinde açıklar ve [yayınlanmış gizlilik politikasını](https://synnergndgn.github.io/Calcademy/privacy_policy) harici tarayıcıda açabilir. Android adaptive/monochrome launcher kaynakları mevcut Calcademy işaretinden türetilmiştir; final 512×512 store icon ve feature graphic ayrıca görsel onay gerektirir. Debug APK CI/yerel kalite kapısından üretilebilir; Play Store imzalama ve mağaza metadata’sı ayrı release adımlarıdır.

Release hazırlık belgeleri:

- [Android release signing](docs/android_release_signing.md)
- [Privacy policy taslağı](docs/privacy_policy.md)
- [Google Play store listing taslağı](docs/store_listing.md)
- [Screenshot checklist](docs/release_screenshot_checklist.md)
- [Release smoke test](docs/release_smoke_test.md)
- [Monetization stratejisi](docs/monetization_strategy.md)
- [1.0.0 release notes taslağı](docs/release_notes_v1_0_0.md)
- [Play Store final karar checklist](docs/play_store_final_checklist.md)
- [Package name karar belgesi](docs/package_name_decision.md)
- [Play App Signing karar rehberi](docs/play_app_signing_decision.md)
- [Final release build checklist](docs/final_release_build_checklist.md)
- [Track promotion checklist](docs/track_promotion_checklist.md)
- [Play Console App Content checklist](docs/play_console_app_content_checklist.md)
- [Data Safety taslağı](docs/data_safety_draft.md)
- [Store asset checklist](docs/store_asset_checklist.md)
- [Screenshot capture plan](docs/release_screenshot_checklist.md)
- [Screenshot sample data](docs/screenshots_sample_data.md)
- [Content rating checklist](docs/content_rating_checklist.md)
- [Target audience checklist](docs/target_audience_checklist.md)
- [CI ve quality gate rehberi](docs/ci_quality_gate.md)

Hesap, abonelik ve backend belgeleri:

- [Supabase auth foundation](docs/supabase_auth_foundation.md)
- [Supabase staging kurulumu](docs/supabase_staging_setup.md)
- [Supabase entitlement şeması](docs/supabase_entitlement_schema.md)
- [Premium mimarisi](docs/premium_architecture.md)
- [Play Billing kurulumu](docs/play_billing_setup.md)
- [Play Billing backend doğrulaması](docs/play_billing_backend_validation.md)
- [Play Billing manuel test runbook](docs/play_billing_manual_test_runbook.md)
- [Auth manuel test runbook](docs/auth_manual_test_runbook.md)
- [Hesap silme akışı](docs/account_deletion.md)
- [AI Assistant foundation](docs/ai_assistant_foundation.md)
- [Gemini destekli asistan](docs/ai_assistant_gemini.md)
- [Formula Library planı](docs/formula_library_plan.md)

Release build, repoya eklenmeyen özel bir upload keystore ve `android/key.properties` gerektirir. R8 ve resource shrinking release varyantında etkindir; debug varyantı bu ayarlardan etkilenmez.

## Bilinen sınırlamalar

- Kompleks sayı ve tam sembolik CAS desteği yoktur.
- Sayısal motorlar `double` hassasiyeti ve modüle özel toleranslarla çalışır.
- Grafik Çizici gerçek, tek değişkenli Kartezyen fonksiyonlarla sınırlıdır.
- Büyük matris/optimizasyon/OR problemleri güvenli merkezi limitlerle sınırlandırılır.
- Saved Calculations için bulut senkronizasyonu ve tüm modüllerde full restore yoktur.
- PDF/CSV dışa aktarma ve üretim mağaza dağıtımı bu sürümün kapsamı dışındadır.
- Calcademy Assistant varsayılan olarak lokal ve kural tabanlıdır; gelişmiş mod yalnızca giriş yapmış Premium hesap açıkça onay verdiğinde çalışır.
- Camera Solver yalnızca placeholder ekrandır; kamera izni, OCR ve görüntü yükleme yoktur.
- Gerçek Google Play Developer API abonelik doğrulaması ve RTDN işleme henüz uygulanmamıştır.
- UMP consent akışı uygulanmamıştır; EEA/UK reklam dağıtımı öncesinde gereklidir.

## Yol haritası

- Google Payments merchant hesabı, abonelik ürünü ve gerçek sandbox satın alma doğrulaması
- Google Play Developer API tabanlı sunucu taraflı abonelik doğrulaması ve RTDN işleme
- Sunucu taraflı kimlik bilgisiyle çalışan, kota sınırlı ve tool allow-list'li Gemini destekli Assistant
- Kamera/OCR için ayrı izin, veri akışı ve Data Safety değerlendirmesi
- UMP consent akışı ve gizlilik seçenekleri giriş noktası
- Release signing, mağaza görselleri ve erişilebilirlik saha doğrulaması
- Saved Calculations restore kapsamının kontrollü genişletilmesi
- Sembolik matematik için güvenilir, ayrı bir mimari değerlendirme
- OR için EOQ, Decision Analysis ve kaynak kısıtlı proje planlama
- Profiling tabanlı performans ve APK boyutu iyileştirmeleri

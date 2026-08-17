# Play Store release notes

Play Console allows 500 characters per language. Paste the block for each
language exactly as written; both are within the limit.

## Calcademy 1.9.4 (28)

### Türkçe

```
Grafik çizimi ve manuel eksen sınırları daha hızlı ve güvenli hale getirildi. Üstel, logaritmik, trigonometrik ve asimptotlu fonksiyonlarda taşma ve tanımsız değerler artık kontrollü işleniyor. Hızlı aralık değişikliklerinde gereksiz hesaplamalar azaltıldı; geçersiz X/Y girişleri grafiği bozmadan açıklayıcı geri bildirim gösteriyor. Ana ekran, hesap makinesi, kayıtlı çalışmalar ve ayarlar genelinde arayüz iyileştirmeleri yapıldı.
```

### English

```
Graph rendering and manual axis bounds are now faster and safer. Overflow and undefined values in exponential, logarithmic, trigonometric, and asymptotic functions are handled gracefully. Rapid range changes trigger less redundant work, while invalid X/Y input shows clear feedback without disrupting the graph. This release also refines the Home, Calculator, Saved work, and Settings interfaces.
```

## Calcademy 1.8.0 (20)

The first release of the ad-supported product: no account, no subscription, no
assistant. It supersedes 1.0.0 (8) on the closed track.

### Türkçe

```
Formül Kütüphanesi eklendi: temel formülleri inceleyin ve ilgili araca tek dokunuşla geçin. Reklam onayı artık Avrupa'daki kullanıcılara reklam istenmeden önce soruluyor; tercihini değiştirmek isteyenler için Ayarlar'a "Reklam gizlilik seçenekleri" eklendi. Reklamlar yalnızca Ana Sayfa ve Kayıtlılar ekranlarında görünür; hesaplama, grafik, matris ve optimizasyon ekranları reklamsızdır. Tüm hesaplamalar cihazda yapılır.
```

### English

```
Added the Formula Library: browse key formulas and jump to the matching tool in one tap. Advertising consent is now requested before any ad for users in Europe, and Settings gains an "Ad privacy options" entry for changing that choice later. Ads appear only on the Home and Saved screens; calculation, graph, matrix, and optimization screens stay ad-free. Every calculation still runs on your device.
```

### What is deliberately absent

No account, no subscription, no assistant, and no camera. Those exist in the
codebase but are compiled out of this build, so nothing in the UI advertises a
feature the user cannot reach. See `track_promotion_checklist.md`.

### Build command

```powershell
flutter build appbundle --release
```

**No `--dart-define`.** Supplying the Supabase values would turn on the entire
account and Premium surface, which is not what this release ships. Supplying
`UMP_DEBUG_GEOGRAPHY` would force a consent form on users whose law does not
require one.

### Internal-testing checklist

- [x] Consent form appears before any banner (forced EEA, 2026-08-06).
- [x] Refusing records zero purpose consents; a non-personalised banner still
      serves, and the app stays fully usable.
- [x] Settings shows **Ad privacy options** only after the user was asked.
- [x] Changing the answer there takes effect without a restart.
- [x] First launch in airplane mode starts cleanly with no banner.
- [x] No assistant, account, or Premium entry point anywhere in the UI.

## Calcademy 1.3.0 (12) — history

### English

- Added the account-optional Calcademy Premium architecture foundation.
- Added local entitlement, feature-gate, and usage-quota models.
- Added Premium and Camera Solver coming-soon pages and a locked Gemini teaser.
- No account, purchase, Gemini API, camera, or OCR flow is active in this build.

### Türkçe

- Hesap zorunluluğu olmayan Calcademy Premium mimari temeli eklendi.
- Yerel entitlement, özellik kapısı ve kullanım kotası modelleri eklendi.
- Premium ve Kamera Çözücü yakında ekranları ile kilitli Gemini tanıtımı eklendi.
- Bu sürümde hesap, satın alma, Gemini API, kamera veya OCR akışı aktif değildir.

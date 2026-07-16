# Calcademy

**Calculate. Visualize. Optimize. Learn.**

Calcademy, üniversite öğrencilerinin bilimsel hesaplama ve problem çözme ihtiyaçlarını tek bir modüler mobil çalışma alanında birleştirmeyi amaçlayan Flutter uygulamasıdır. İlk sürüm çevrimdışı çalışan Bilimsel Hesap Makinesi modülüne odaklanır.

## Bu sürümde

- Temel işlemler, parantez, üs, karekök, faktöriyel, yüzde, mod ve örtük çarpma
- `sin`, `cos`, `tan`, ters trigonometrik fonksiyonlar, `log`, `ln`, `exp`, `floor`, `ceil`, `round`, `abs`
- `π`, `e` ve `Ans` desteği
- DEG/RAD açı modu ve ayarlanabilir sonuç hassasiyeti
- Türkçe ve İngilizce arayüz
- Sistem, açık ve koyu tema
- Aranabilir, tarihe göre gruplu hesaplama geçmişi
- Başlık ve not içeren kaydedilmiş hesaplamalar
- SharedPreferences ile çevrimdışı kalıcılık
- Responsive telefon/tablet arayüzü ve fiziksel klavye girişi
- Gelecek modüller için açıklayıcı “Yakında” ekranları

## Çalıştırma

Gereksinimler: Flutter 3.44.0 veya uyumlu kararlı sürüm, Dart 3.12.0+, Android Studio/Android SDK.

```bash
flutter pub get
flutter run
```

Bağlı cihazları görmek için `flutter devices`, belirli bir cihazı çalıştırmak için `flutter run -d <device-id>` kullanılabilir.

## Önemli paketler

- `flutter_riverpod`: ayarlar, hesap makinesi, geçmiş ve kayıt durumları
- `go_router`: tipik uygulama rotaları ve alt navigasyon kabuğu
- `shared_preferences`: geçmiş, kaydedilenler ve ayarların yerel saklanması
- `intl`: yerelleştirilmiş tarih/saat biçimlendirme
- `flutter_localizations`: Material bileşenlerinin Türkçe/İngilizce yerelleştirmesi

Matematik ifadeleri `eval` kullanmadan, uygulamaya ait kontrollü lexer ve recursive-descent parser ile değerlendirilir.

## Proje yapısı

```text
lib/
├── app/                 # Uygulama, router, tema ve navigasyon
├── core/                # Ortak servisler ve widgetlar
├── features/
│   ├── calculator/      # Güvenli motor, state ve hesap makinesi UI
│   ├── history/         # Modeller, yerel repository ve geçmiş UI
│   ├── home/            # Modül kataloğu, ana sayfa ve splash
│   ├── saved/           # Kaydedilen hesaplamalar
│   └── settings/        # Ayarlar ve hakkında
└── l10n/                # Türkçe/İngilizce metinler
```

## Testler ve kalite

```bash
flutter test
flutter analyze
```

Unit testler işlem önceliği, fonksiyonlar, DEG/RAD, sabitler, `Ans`, biçimlendirme ve hata durumlarını; widget testleri hesap makinesi tuş akışını, AC davranışını ve geçmiş boş durumunu kapsar.

## Bilinen sınırlamalar

- Kompleks sayılar desteklenmez.
- Yüzde postfix olarak `x / 100` anlamına gelir.
- n’inci dereceden kök, matris ve grafik motorları henüz uygulanmamıştır.
- Veriler yalnızca cihazda tutulur; bulut senkronizasyonu yoktur.
- Tuş sesi platformun sistem tıklama sesini kullanır.

## Gelecek modüller

Grafik çizici, matrisler ve lineer cebir, denklem çözücü, calculus, istatistik, lineer/integer programlama, nonlinear optimizasyon, dinamik programlama ve sayısal yöntemler.

## Ekran görüntüleri

Ekran görüntüleri Android cihaz doğrulamasından sonra bu bölüme eklenebilir.

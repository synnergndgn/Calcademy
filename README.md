# Calcademy

**Calculate. Visualize. Optimize. Learn.**

![Calcademy resmi logosu](assets/branding/calcademy_logo.svg)

Calcademy, üniversite öğrencilerinin bilimsel hesaplama ve problem çözme ihtiyaçlarını tek bir modüler mobil çalışma alanında birleştirmeyi amaçlayan Flutter uygulamasıdır. Mevcut sürüm çevrimdışı çalışan Bilimsel Hesap Makinesi, Grafik Çizici, Matrisler ve Lineer Cebir, Lineer Programlama ve Tam Sayılı Programlama modüllerini içerir.

## Marka kimliği

Resmî Calcademy logosu `assets/branding/calcademy_logo.svg` yolunda tutulur ve uygulamada ortak `CalcademyLogo` bileşeni üzerinden kullanılır. SVG'nin özgün renkleri, oranları ve çizimi korunur; tema tarafından yeniden renklendirilmez.

| Rol | Renk |
| --- | --- |
| Açık adaçayı yeşili | `#8FAE9E` |
| Ana koyu yeşil | `#63897A` |
| Sıcak kırık beyaz | `#FBFAF5` |
| Veri noktası aksanı | `#E7B77D` |

Marka sloganı İngilizce “Calculate. Visualize. Optimize. Learn.”, Türkçe “Hesapla. Görselleştir. Optimize et. Öğren.” şeklindedir. Turuncu, logodaki veri noktası gibi küçük ve anlamlı vurgularla sınırlıdır.

Launcher icon henüz bu SVG'den üretilmemiştir. Android adaptive icon güvenli bölge ve küçük boyut okunabilirliği ayrı bir ikon çalışmasında doğrulanacak; o zamana kadar mevcut launcher icon korunacaktır.

## Bu sürümde

- Temel işlemler, parantez, üs, karekök, faktöriyel, yüzde, mod ve örtük çarpma
- `sin`, `cos`, `tan`, ters trigonometrik fonksiyonlar, `log`, `ln`, `exp`, `floor`, `ceil`, `round`, `abs`
- `π`, `e` ve `Ans` desteği
- DEG/RAD açı modu ve ayarlanabilir sonuç hassasiyeti
- Türkçe ve İngilizce arayüz
- Sistem, açık ve koyu tema
- Aranabilir, tarihe göre gruplu hesaplama geçmişi
- Başlık ve not içeren kaydedilmiş hesaplamalar ile sekmeli grafik kayıtları
- SharedPreferences ile çevrimdışı kalıcılık
- Responsive telefon/tablet arayüzü ve fiziksel klavye girişi
- Gelecek modüller için açıklayıcı “Yakında” ekranları
- Beş fonksiyona kadar güvenli, çevrimdışı Kartezyen grafik çizimi
- Grafiklerde otomatik/manüel ölçek, RAD/DEG, pinch zoom, pan ve nokta inceleme
- Kontrollü adaptif örnekleme, güçlendirilmiş süreksizlik algılama ve LRU örnek cache'i
- Grafik çalışma alanlarını ayrı bir yerel kayıt modeliyle saklama, güncelleme ve kopyalama
- Legend ve Calcademy imzası içeren PNG grafik paylaşımı
- 1×1 ile 10×10 arasında matris düzenleme; genişletilmiş matrislerde 10×11 sınırı
- Toplama, çıkarma, skaler ve matris çarpımı, transpoz, iz, determinant, ters ve rank
- Satır işlemleri, REF, RREF, Gauss ve Gauss-Jordan için ileri/geri adım görünümü
- Kare, fazla ve eksik denklemli lineer sistemlerde tek, sonsuz veya çözümsüz sınıflandırması
- Ondalık ve kesir hücre girişi, `1e-10` merkezi sayısal toleransı
- Hesaplama ve grafiklerden bağımsız yerel matris işlem kayıtları

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
- `flutter_svg`: resmî Calcademy SVG marka varlığının kayıpsız gösterimi
- `fl_chart`: etkileşimli Kartezyen fonksiyon grafikleri
- `share_plus`: PNG byte verisi için güvenli dosya adı ve platformun yerel paylaşım ekranı

Matematik ifadeleri `eval` kullanmadan, uygulamaya ait kontrollü lexer ve recursive-descent parser ile değerlendirilir.

## Proje yapısı

```text
lib/
├── app/                 # Uygulama, router, tema ve navigasyon
├── core/                # Ortak servisler ve widgetlar
├── features/
│   ├── calculator/      # Güvenli motor, state ve hesap makinesi UI
│   ├── graph/           # Güvenli x değerlendiricisi, örnekleme, kayıt ve grafik UI
│   ├── history/         # Modeller, yerel repository ve geçmiş UI
│   ├── home/            # Modül kataloğu, ana sayfa ve splash
│   ├── matrix/          # Immutable model, lineer cebir motoru, kayıt ve matris UI
│   ├── linear_programming/  # LinearProgram modeli, simpleks çözücü ve LP UI
│   ├── integer_programming/ # IntegerProgram, Branch-and-Bound çözücü ve MIP UI
│   ├── saved/           # Hesaplama, grafik, matris ve optimizasyon kayıtlarının ortak görünümü
│   └── settings/        # Ayarlar ve hakkında
└── l10n/                # Türkçe/İngilizce metinler
```

## Testler ve kalite

```bash
flutter test
flutter analyze
```

Unit testler işlem önceliği, fonksiyonlar, DEG/RAD, grafik domain/süreksizlikleri, matris işlemleri, satır replay'i, lineer sistem sınıflandırması, simpleks çözücü, Branch-and-Bound dallanma/budama/limit davranışı ve hazır tam sayılı programlama örneklerinin bağımsız doğrulanmış optimumlarını kapsar. Widget testleri hesap makinesi tuş akışını, grafik etkileşimlerini, matris editörünü, LP/IP model editörlerini, çözüm ve branch ağacı ekranlarını, adım ekranını, tema ve responsive davranışları kapsar.

## Bilinen sınırlamalar

- Kompleks sayılar desteklenmez.
- Yüzde postfix olarak `x / 100` anlamına gelir.
- Matris motoru gerçek sayılarla ve `double` hassasiyetiyle çalışır; çok kötü koşullu veya çok büyük/küçük katsayılı matrislerde yuvarlama hatası oluşabilir.
- Kesir girişi desteklenir ancak sonuçlar tam rational biçimde tutulmaz; yaklaşık ondalık olarak gösterilir.
- Özdeğer, özvektör, karakteristik polinom, kompleks matrisler, LU/QR/Cholesky/SVD ayrıştırmaları henüz yoktur.
- Veriler yalnızca cihazda tutulur; bulut senkronizasyonu yoktur.
- Tuş sesi platformun sistem tıklama sesini kullanır.
- Grafik Çizici yalnızca tek değişkenli gerçek Kartezyen fonksiyonları destekler; sembolik analiz, kök/kesişim bulma, parametrik, polar, implicit ve 3D çizim henüz yoktur.

## Gelecek modüller

Denklem çözücü, calculus, istatistik, nonlinear optimizasyon, dinamik programlama ve sayısal yöntemler. Matris modülünün sonraki aşaması özdeğer/özvektör ve doğrulanmış LU/QR/Cholesky ayrıştırmalarıdır. Tam Sayılı Programlama modülünün sonraki aşaması Gomory cutting planes ve Branch-and-Cut'tır (bkz. "Bilinen sınırlamalar").

## Lineer Programlama 1.0

- 1–10 sürekli ve negatif olmayan karar değişkeni, 1–20 adet `≤`, `≥` veya `=` kısıtı
- Maksimizasyon/minimizasyon; primal ve iki aşamalı simpleks yönteminin otomatik seçimi
- Negatif RHS normalizasyonu, slack/surplus/yapay değişkenler ve incelenebilir Faz I/Faz II tabloları
- Optimal, çoklu optimum, sınırsız, çözümsüz, dejenere, iterasyon sınırı ve sayısal hata ayrımı
- İki değişkenli modellerde uygun köşeler, uygun bölge ve optimum nokta için grafiksel görünüm
- Güvenli standart formda dual model üretimi; temel slack, aktif kısıt, baz ve azaltılmış maliyet bilgileri
- Modeller ve sonuç özetleri `linear_programming.saved` anahtarında yalnızca cihazda saklanır

Lineer programlama motoru `double` hassasiyeti ve merkezi `1e-9` toleransıyla çalışır. Big-M, doğrusal olmayan ve kuadratik optimizasyon bu sürümün kapsamı dışındadır. Kesir girişi kabul edilir fakat hesaplamada yaklaşık ondalığa çevrilir. Gölge fiyat ve izin verilen katsayı aralıkları güvenilirliği garanti edilemediğinde gösterilmez.

## Tam Sayılı Programlama 1.0

Beşinci akademik modül: tam sayı, binary ve karma (mixed) doğrusal programları çevrimdışı Branch-and-Bound ile çözer. Lineer Programlama modülünün `LinearProgram` modelini ve simpleks çözücüsünü servis olarak yeniden kullanır; LP modelleri, LP kayıt formatı ve LP çözücüsü değiştirilmemiştir.

- Sürekli, tam sayı (`xᵢ ∈ Z₊`) ve binary (`xᵢ ∈ {0,1}`) karar değişkenleri; en az bir tam sayı/binary değişken zorunludur
- Binary üst sınırı (`x ≤ 1`) modele otomatik eklenir; kullanıcıdan ayrı bir kısıt istenmez
- Maksimizasyon/minimizasyon; her dal düğümünde LP gevşetmesi mevcut simpleks çözücüsüyle çözülür
- Dallanma stratejisi: en çok kesirli (varsayılan) veya ilk kesirli, değişken sırasına göre deterministik eşitlik kırma
- Düğüm seçim stratejisi: derinlik öncelikli (varsayılan) veya en iyi sınır, düğüm oluşturma sırasına göre deterministik
- Incumbent takibi, bound/uygunsuzluk/tam sayılık ile budama, optimality gap (`|incumbent − sınır| / max(1, |incumbent|)`)
- Sonuç durumları: optimal, limit nedeniyle bulunan en iyi çözüm, uygunsuz, gevşetme sınırsız, düğüm/iterasyon limiti, sayısal hata
- Genişletilebilir kartlarla girintili Branch-and-Bound ağacı görünümü ve düğüm detay sayfası (bound, kesirli değişkenler, dallanma kısıtları, budama nedeni)
- Hazır örnekler: 0-1 sırt çantası, proje seçimi (bağımlılık kısıtı), 3×3 atama, sabit maliyetli üretim, saf tam sayılı ürün karması, uygunsuz tam sayı modeli, kesirli gevşetme
- Modeller ve sonuç özetleri `integer_programming.saved` anahtarında yalnızca cihazda saklanır; Kaydedilenler ekranındaki tek "Optimizasyon" sekmesinde Lineer Programlama kayıtlarıyla birlikte listelenir

### Model boyutu ve limitler

Merkezi sabitler `lib/features/integer_programming/domain/mip_constants.dart` dosyasındadır:

| Sabit | Değer |
| --- | --- |
| Toplam değişken (LP modülünden miras) | 10 |
| Önerilen tam sayı/binary değişken | 8 (aşılırsa arayüzde performans uyarısı gösterilir, model reddedilmez) |
| Kısıt | 20 |
| Maksimum düğüm | 5000 |
| Maksimum derinlik | 50 |
| Maksimum toplam LP iterasyonu | 100000 |
| `mipEpsilon` | `1e-9` |
| `integerEpsilon` | `1e-7` |

Derinlik limitine takılan dallar ağaçta "daha fazla genişletilmedi" olarak işaretlenir ve nihai sonucun gap hesabına dahil edilir; böylece kesilen bir dal varken yanlışlıkla `%0` gap gösterilmez.

### Isolate ve iptal

Branch-and-Bound çözümü `compute()` ile arka plan isolate'inde çalışır; arayüz yalnızca "Model çözülüyor" belirsiz ilerleme göstergesi gösterir (gerçek yüzde ilerleme yoktur). Isolate gerçek anlamda iptal edilemediğinden, controller nesil (generation) sayacı kullanır: model değişirse, yeni bir çözüm başlatılırsa veya sayfadan çıkılırsa önceki isolate sonucu geldiğinde sessizce yok sayılır.

### Bilinen sınırlamalar (Tam Sayılı Programlama)

- Gomory/cutting-plane, branch-and-cut, clique/cover/MIR cuts, column generation, Lagrangian relaxation, Benders decomposition, doğrusal olmayan/kuadratik tam sayı programlama, constraint programming, genetik algoritma, simulated annealing ve dağıtık/bulut çözüm bu sürümün kapsamı dışındadır.
- Kök LP gevşetmesi sınırsızsa sonuç doğrudan "gevşetme sınırsız" olarak raporlanır; tam sayılık kısıtının problemi yine de sınırlı kılıp kılmayacağı ayrıca ispatlanmaz.
- Warm-start (üst düğüm simpleks bazının yeniden kullanımı) yoktur; her düğüm sıfırdan çözülür. Küçük model boyutlarında bu kabul edilebilir performans sağlar.
- Presolve sınırlıdır; karmaşık dönüşümler (ör. katsayı sıkılaştırma) yapılmaz, doğruluk performanstan önceliklidir.
- Canlı düğüm ilerlemesi (işlenen düğüm sayısı, güncel incumbent/bound) arayüzde akış olarak gösterilmez; yalnızca nihai sonuç ve tam ağaç sunulur.

## Denklem Çözücü 1.0

Altıncı akademik modül: tek değişkenli denklemler, n×n lineer sistemler ve klasik sayısal kök bulma yöntemleri, tamamen çevrimdışı.

- **Tek denklem**: `2x + 5 = 17` gibi `=` içeren girişler veya çıplak ifadeler (`x^2 - 4`). Grafik Çizici'nin ifade derleyicisi yeniden kullanılır: `+ - * / ^`, parantez, tekli eksi, ondalık, `sin cos tan`, `sqrt`, `ln log`, `exp`, `pi`, `e` ve `2x` / `3(x+1)` gibi örtük çarpım desteklenir. Trigonometri radyan modundadır.
- **Analitik yol**: fonksiyon, doğrulamalı sayısal uyum ile derece ≤ 2 polinom olarak algılanırsa lineer/ikinci derece formülüyle **kesin** çözülür (kararlı q-formülü ile katastrofik iptal önlenir); ayrıca her analitik kök gerçek fonksiyona karşı artık-değer kontrolünden geçer — yanlış algılama durumunda sessizce sayısal taramaya düşülür. Negatif diskriminantta "gerçek kök yok (karmaşık kök olabilir)" ayrımı, `0=0` özdeşliği ve `5=7` çelişkisi ayrı sonuç türleridir.
- **Sayısal yol**: kullanıcı tarafından değiştirilebilir tarama aralığında (varsayılan [-10, 10], 400 örnek) işaret değişimi köşeleme + bisection iyileştirme; çift katlı (teğet) kökler |f| minimumlarından Newton ile denenir ve uyarıyla işaretlenir; her aday artık-değer kontrolünden geçer (1/x'in 0'daki süreksizliği kök sanılmaz); yinelenen kökler toleransla birleştirilir. Sonuç yalnızca "taranan aralıkta bulunan kökler" iddiasındadır.
- **Lineer sistem (matris modu)**: 2–10 boyut; katsayı ızgarası + RHS. Çözüm, Matris modülünün test edilmiş Gauss eliminasyon motoruna (`MatrixEngine.solveLinearSystem`) devredilir — tek/sonsuz/çözümsüz sınıflandırması epsilon tabanlıdır, ikinci bir eliminasyon kopyalanmamıştır. Denklem-metni modu bu sürümün kapsamı dışında bırakıldı (yarım özellik olarak eklenmedi).
- **Sayısal yöntemler**: Bisection (alt/üst sınır), Newton-Raphson (simetrik fark sayısal türevi; türev ≈ 0 tipli hata), Secant (iki tahmin). Her sonuç yakınsama durumu, iterasyon sayısı, artık değer ve son tahmini raporlar; tolerans 1e-14 tabanına, iterasyon 500 tavanına kıskaçlanır.
- Sonuç kartı: Kesin/Yaklaşık rozeti, kullanılan yöntem, artık değer, taranan aralık, uyarı kartları ve kopyalama. Tüm hata durumları (boş girdi, sözdizimi, bilinmeyen değişken/fonksiyon, geçersiz aralık/bracket, türev≈0, iterasyon limiti, tekil matris...) tipli ve TR/EN yerelleştirilmiş; ham exception UI'ya çıkmaz.
- Limitler merkezi: `lib/features/equation_solver/domain/equation_solver_limits.dart`.

Kapsam dışı (sonraki sürümler): sembolik CAS, adım adım cebir, karmaşık düzlem görselleştirme, denklem-grafik bindirmesi, geçmiş/favoriler, denklem-metni sistem girişi.

## Calculus 1.0

Yedinci akademik modül: tamamen sayısal analiz odaklı türev, integral ve fonksiyon analizi. Bu sürümde sembolik CAS, sembolik türev veya belirsiz integral yoktur; her sonuç açıkça "yaklaşık" rozetiyle sunulur.

- **Sayısal türev**: İleri, geri ve merkezi fark (varsayılan merkezi). Adım boyutu kullanıcı tarafından ayarlanabilir (1e-10…1 aralığına doğrulanır). Hata tahmini, adım ile yarım adımın Richardson karşılaştırmasından yöntem mertebesine göre ölçeklenir; gösterilen değer daha doğru olan yarım-adım sonucudur.
- **Sayısal integral**: Yamuk ve Simpson 1/3 kuralları. Simpson için tek alt aralık sayısı sessizce düzeltilmez — doğrulama hatası olarak gösterilir. Hata tahmini n ile 2n karşılaştırmasından (yamuk /3, Simpson /15).
- **Fonksiyon analizi**: Kullanıcı aralığında (varsayılan [-10, 10], değiştirilebilir) örnekleme tabanlı yaklaşık kökler (Denklem Çözücü'nün `scanForRoots`'u yeniden kullanılır), sayısal birinci/ikinci türev üzerinden ekstremum ve büküm noktaları, artan/azalan aralıklar ve örnekler üzerinde gözlenen min/maks. Düz kritik noktalar ve kısmen tanımsız bölgeler uyarıyla raporlanır; hiçbir bulgu "kesin" olarak sunulmaz.
- **Grafik entegrasyonu**: Yeni grafik motoru yazılmadı — Grafik Çizici'nin `GraphSampler`'ı (kutup/süreksizlik segmentasyonu dahil) eğriyi üretir, uygulamanın mevcut fl_chart bağımlılığı çizer. Türev sekmesinde hesaplanan türev değerinden üretilen kesikli teğet doğrusu + değerlendirme noktası; integral sekmesinde örneklenen eğriyi birebir izleyen tema-türevi gölgeli alan (dark mode uyumlu).
- İfade değerlendirme Denklem Çözücü'nün `ParsedEquation` sarmalayıcısı üzerinden Grafik parser'ını kullanır (ikinci parser yok); ifade her çözümde bir kez derlenir ve tüm örneklemelerde yeniden kullanılır.
- Limitler merkezi: `lib/features/calculus/domain/calculus_limits.dart`. Hata durumları (geçersiz adım/sınır/alt aralık, tek Simpson sayısı, tanımsız bölge…) tipli ve TR/EN yerelleştirilmiş.

Kapsam dışı (sonraki sürümler): sembolik türev/integral, Taylor/Fourier/Laplace, ODE/PDE, adım adım sembolik çözüm.

## Statistics 1.0

Sekizinci akademik modül; veri özetleme, temel olasılık dağılımları ve güven aralıkları için çevrimdışı, tipli ve doğrulanmış bir çalışma alanı sunar.

- Virgül, boşluk, noktalı virgül ve satır sonu ayrımlı veri girişi; belirsiz tek virgülün sessizce yanlış yorumlanmasını önleyen doğrulama
- Ortalama, medyan, mod, min/maks, açıklık, anakütle/örneklem varyansı ve standart sapması, Q1/Q3/IQR ve 1,5×IQR aykırı değerleri
- Normal CDF için erf yaklaşımı; Binom ve Poisson için taşmaya dayanıklı logaritmik toplam hesapları
- Bilinen sigma için z, bilinmeyen sigma için doğrulanmış t kritik değerleri ve oran için Wilson güven aralıkları
- Merkezi limitler, TR/EN hata ve varsayım mesajları, yaklaşık sonuç rozeti ve sonuç kopyalama

Kapsam dışı: regresyon, korelasyon, ANOVA, hipotez testleri, ki-kare, parametrik olmayan testler, histogram/grafikler ve veri içe/dışa aktarma.

## Ekran görüntüleri

Ekran görüntüleri Android cihaz doğrulamasından sonra bu bölüme eklenebilir.

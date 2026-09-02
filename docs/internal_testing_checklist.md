# Calcademy Play Store Internal Testing Checklist

Bu checklist, Play Store Internal Testing'e yuklenecek **ayni release AAB** uzerinde
tamamlanmalidir. Her cihaz kosusunda cihaz modeli, Android surumu, ekran boyutu,
dil, tema, uygulama surumu/build numarasi, test tarihi ve sonucu kaydedilmelidir.

## Release Candidate Kaydi

| Alan | Beklenen / Kaydedilecek deger | Sonuc |
| --- | --- | --- |
| Artifact | `build/app/outputs/bundle/release/app-release.aab` | [ ] |
| Version | `1.10.3 (35)` | [ ] |
| Package | `com.aligundogan.calcademy` | [ ] |
| Install source | Play Store Internal Testing opt-in linki | [ ] |
| Git revision | `0ea48403f2f5e93909b222c387f557d9ff012736` | [ ] |
| AAB SHA-256 | `df88dce91789eaba46f6b2e6411ef6abe6960a8baa7f0ce2355aa50e4077f8c0` | [ ] |
| Tester / tarih | Ad ve tarih | [ ] |
| Cihaz / Android | Model ve Android surumu | [ ] |

> Play Console ayni `versionCode` degerini iki kez kabul etmez. `34` uretime
> cikmistir; bu release `35` ile cikar. Kaynak metadata'si ve release notlari da
> birlikte guncellenmis, tum release gate'leri yeniden calistirilmistir.

## 1.10.3 (35) Surum Notu

Yukaridaki AAB `0ea4840` agacindan uretildi; manifest `versionName 1.10.3`,
package `com.aligundogan.calcademy` bildiriyor. Imza sertifikasi
`CN=Ali Gundogan, OU=Calcademy`, SHA-256
`8D:C0:F8:44:C9:FB:C9:F1:B8:FF:69:64:DB:FD:39:85:46:B5:C2:E3:17:95:07:40:64:9A:34:2F:F0:08:BC:D1`.
Yuklemeden once bu parmak izi Play Console > App integrity > App signing >
Upload key certificate degeriyle karsilastirilmalidir.


Bu surum yalnizca yerlesim duzeltmesi tasir. **1.10.2 (34) ayni hatayi
duzelttigini kaydetmisti; duzeltme eksikti.** 34'teki cozum tek bir hedefte --
360x800 dp, uc dugmeli gezinme -- dogrulanmisti ve yalnizca orada yetiyordu:

- Android **ekran boyutu (display size)** ayari yukseltildiginde ayni panel daha
  az mantiksal dp olur (ornegin 1080x2400 varsayilanda 360x800 dp iken bir
  kademe yukaride ~328x729 dp'dir). Kalan yukseklik dokuz tus sirasina yetmez.
- **Yazi olcegi** buyudugunde ifade alani ve sonuc paneli buyur, tus takimina
  kalan yukseklik azalir.
- `=` tusuna basildiginda sonuc paneline aksiyon satiri eklendigi icin panel
  116 dp'den 149 dp'ye cikiyordu; **duzeltmenin dogrulandigi 360x800 hedefinde
  bile** alt iki tus sirasi bu anda ekran disina itiliyordu.

Yetersiz kalan durumda tus takimi sessizce kendi icinde kaydirilabilir hale
geliyor, fakat hicbir kaydirma isareti gostermiyordu; kullanici alt tuslarin
var oldugunu goremiyordu.

35'te tus takimi, ifade alani ve sonuc paneli yerlesimden **once** olculur:
sonuc paneli sabit yukseklikte kalir, yer daralinca once ifade alani ve panel
kuculur, gerekirse tus takimi 5 sutun/9 satir yerine 6 sutun/7 satir duzenine
gecer, ve hicbiri yetmezse grid gorunur bir kaydirma cubugu ile kaydirilir.

Bu surume ozel dogrulanacaklar:

- [ ] **Ekran boyutu matrisi.** Ayarlar > Ekran > Ekran boyutu: varsayilan,
  bir kademe buyuk ve en buyuk degerde bilimsel hesap makinesi acilir ve
  `0`, `.`, `AC`, `⌫`, `+`, `=` tuslarinin tamami kaydirmadan gorunur.
- [ ] **Yazi tipi boyutu matrisi.** Ayni ekran varsayilan, buyuk ve en buyuk
  yazi tipi boyutunda tasma vermeden calisir.
- [ ] Yukaridaki her kombinasyonda `1+2=` hesaplandiktan **sonra** da alt tus
  sirasi ayni yerde durur; sonuc paneli buyuyup tuslari disari itmez.
- [ ] Uc dugmeli gezinme ve hareketle gezinme modlarinin ikisinde de alt tus
  sirasi sistem cubugunun altina girmez.
- [ ] Yatay modda sayfanin tamami kaydirilabilir; `=` tusuna erisilir.
- [ ] Hesaplama sonuclari degismemistir (Calculator Manual Test tablosu).
- [ ] Yayinlanan gizlilik politikasi sayfasinin yururluk tarihi
  `AppMetadata.privacyPolicyEffectiveDate` ile ayni: `2026-09-02`.

## 1.10.2 (34) Surum Notu

`versionCode 33` (1.10.1) ic teste yuklenmis ve tuketilmistir; o yapi Testler
modulunu hala sunuyordu ve asagidaki hesap makinesi hatasini tasiyordu. Bu
surum uretime cikacak yapidir ve iki degisiklik tasir:

- **Bilimsel hesap makinesi yerlesim duzeltmesi.** Tus takimi ifade alanini ve
  sonuc panelini ekranin disina itebiliyordu. Artik ikisi sabit; tus takimi
  kalan yuksekligi kullanir. Dar gorunumlerde (yatay mod, buyuk yazi olcegi)
  eski kaydirmali duzene doner.
- **Testler (practice) modulu bu surumde kullanima sunulmaz.** Kod pakette yer
  alir; ana sayfa kategorisi, hizli erisim karti, modul aramasi ve kategori
  filtresi kaldirilmistir (`AppFeatures.practiceEnabled = false`). Uygulama
  derin baglanti tanimlamadigi icin `/quiz` rotalarina ulasilamaz.

Bu surume ozel dogrulanacaklar:

- [ ] Ana sayfada Testler kategorisi, filtre cipi, hizli erisim karti ve arama
  sonucu gorunmuyor.
- [ ] Bilimsel hesap makinesinde ifade alani ve sonuc paneli her zaman
  gorunur; `+` ve `=` dahil tum tus siralari erisilebilir. (34'te bu madde
  yalnizca varsayilan ekran boyutunda ve hesaplama yapilmadan dogrulanmisti;
  35 icin yukaridaki matris gecerlidir.)
- [ ] Ayni ekran yatay modda ve %200 yazi olceginde tasma vermeden calisiyor.
- [ ] Yayinlanan gizlilik politikasi sayfasinin yururluk tarihi
  `AppMetadata.privacyPolicyEffectiveDate` ile ayni: `2026-08-23`.

## Device Smoke Test

- [ ] Temiz kurulumdan sonra uygulama ilk acilista crash, ANR, bos/beyaz ekran,
  debug banner veya gelistirici metni gostermiyor.
- [ ] Splash tamamlandiktan sonra Home aciliyor ve ana icerik eksiksiz render
  ediliyor.
- [ ] Home, History, Saved ve Settings dahil tum ana navigation item'lari dogru
  sayfayi aciyor; aktif item durumu dogru gorunuyor.
- [ ] Home'daki aktif tum modul kartlari aciliyor; kapali/gelecek moduller
  yaniltici bicimde etkilesimli gorunmuyor.
- [ ] Android sistem back button sayfa ve modal hiyerarsisinde dogal calisiyor;
  Home'da uygulamadan cikis davranisi beklenen sekilde.
- [ ] Force-stop ve app restart sonrasinda uygulama aciliyor; ayarlar ve yerel
  veriler korunuyor.
- [ ] Desteklenen ekranlarda portrait/landscape gecisinde overflow, kirpilma,
  kayip state veya crash yok. Desteklenmeyen yon icin beklenti kaydedildi.
- [ ] Kucuk telefon (~320-360 dp), normal/buyuk telefon (~390-480+ dp) ve en az
  bir tablet (7-10 inc) uzerinde layout kullanilabilir.
- [ ] Klavye acikken birincil aksiyonlar ve bottom navigation erisilebilir;
  safe-area alanlari ihlal edilmiyor.
- [ ] Arka plana alma, recent apps'ten donme ve ekran kilidi/acma state kaybina
  veya crash'e yol acmiyor.

## Calculator Manual Test

Asagidaki girdiler hem gosterilen sonuc/hata hem de uygulamanin stabil kalmasi
acisindan kontrol edilmelidir. Trigonometri testi icin angle mode **DEG** olmali.

| Girdi / senaryo | Beklenen | Sonuc |
| --- | --- | --- |
| `1+1` | `2` | [ ] |
| `2-5` | `-3` | [ ] |
| `3*4` | `12` | [ ] |
| `10/2` | `5` | [ ] |
| `10/0` | Kontrollu division-by-zero hatasi; NaN/Infinity sonuc olarak kaydedilmez | [ ] |
| `2^3` | `8` | [ ] |
| `sqrt(16)` | `4` | [ ] |
| `sin(30)` | DEG modunda `0.5` (precision'a uygun gosterim) | [ ] |
| `(2+3)*4` | `20` | [ ] |
| Negatif sayilar (`-5+2`, `2*-3`) | Sonuclar sirasiyla `-3`, `-6` | [ ] |
| Ondalikli sayilar (`1.5+2.25`) | `3.75` | [ ] |
| Tam 512 karakter | UI yanit vermeye devam eder; gecerliyse kontrollu hesaplanir | [ ] |
| 513+ karakter | Kontrollu invalid-expression hatasi; donma/crash yok | [ ] |
| Bos input | Lokalize bos-input geri bildirimi; history kaydi yok | [ ] |
| Hatali parantez (`(2+3`) | Kontrollu invalid-expression hatasi | [ ] |
| Sadece operator (`+`, `*`) | Kontrollu invalid-expression hatasi | [ ] |

Ek akislar:

- [ ] Hizli tus girisi, silme, clear ve tekrar hesaplama sirasinda tus kaybi,
  cift hesaplama veya UI donmasi yok.
- [ ] Sonuc kopyalama, save ve history entegrasyonu dogru ifade/sonucu kullaniyor.
- [ ] Precision ve scientific notation degisiklikleri yeni sonuc gosterimine
  beklenen sekilde yansiyor.

## Graph Manual Test

Graph modulu aktifse her fonksiyon icin cizim, tanim kumesi ve etkilesim
kontrolleri tamamlanmalidir.

| Fonksiyon | Cizim basarili | Invalid range crash yok | Zoom/pan | UI donmuyor | NaN/Infinity guvenli |
| --- | --- | --- | --- | --- | --- |
| `(1/30)^x+e^(x/4)` | [ ] | [ ] | [ ] | [ ] | [ ] |
| `e^(x/4)` | [ ] | [ ] | [ ] | [ ] | [ ] |
| `(1/30)^x` | [ ] | [ ] | [ ] | [ ] | [ ] |
| `sin(x)*e^x` | [ ] | [ ] | [ ] | [ ] | [ ] |
| `1/(x-1)` | [ ] | [ ] | [ ] | [ ] | [ ] |
| `sqrt(x)` | [ ] | [ ] | [ ] | [ ] | [ ] |
| `ln(x)` | [ ] | [ ] | [ ] | [ ] | [ ] |
| `tan(x)` | [ ] | [ ] | [ ] | [ ] | [ ] |

- [ ] `xMin >= xMax`, bos/non-numeric deger ve asiri genis aralik kontrollu
  geri bildirim veriyor; mevcut grafik/state bozulmuyor.
- [ ] `1/(x-1)` ve `tan(x)` asimptotlar uzerinden yanlis birlestirme yapmiyor.
- [ ] `sqrt(x)` ve `ln(x)` tanim disi bolgelerde crash veya cizgi artefakti
  olusturmuyor.
- [ ] Hizli aralik/fonksiyon degisikliklerinde eski sampling sonucu yeni state'i
  ezmiyor.
- [ ] Reset/auto-range ve varsa graph save/reopen/share akislarinda release-only
  R8/resource-shrinking sorunu yok.

## History / Saved

- [ ] Yeni ve basarili bir hesaplama History'ye tek kayit olarak dusuyor.
- [ ] Today / Yesterday / This Week / Older gruplamasi cihaz saat dilimi ve gun
  sinirlarinda dogru.
- [ ] Save calisiyor; hizli cift dokunma beklenmeyen duplicate olusturmuyor.
- [ ] Tek kayit Delete calisiyor ve dogru kaydi kaldiriyor.
- [ ] Reuse dogru expression ve ilgili ayarlari Calculator'a tasiyor.
- [ ] App force-stop/restart sonrasinda History ve Saved verileri korunuyor.
- [ ] History clear ve Saved/data reset yalniz hedeflenen veriyi, confirm sonrasi
  siliyor; cancel hicbir seyi degistirmiyor.
- [x] Bozuk veri fallback'i otomatik testlerde kapsaniyor:
  `test/features/history/data/local_calculation_repository_test.dart` malformed,
  wrong-shaped ve karisik valid/corrupt payload senaryolarini dogruluyor.
- [x] Graph, Matrix, Linear Programming ve Integer Programming repository
  testleri tek bozuk kaydin komsu gecerli kayitlari gizlemedigini dogruluyor.
- [ ] Cihazda eski surumden upgrade senaryosu uyumlu yerel veriyi koruyor.

## Settings

- [ ] Light theme aninda uygulanir; tum ana ekranlarda okunabilir.
- [ ] Dark theme aninda uygulanir; tum ana ekranlarda okunabilir.
- [ ] System theme cihaz tema degisikligini dogru takip eder.
- [ ] TR/EN dil degisimi acik ekran ve navigation metinlerine yansir; eksik key
  veya tasma yok.
- [ ] Precision ayari 4-15 araliginda calisir ve Calculator sonucuna yansir.
- [ ] History/Saved/data reset islemleri dogru kapsama sahiptir.
- [ ] Tum destructive aksiyonlarda confirm dialog vardir; Cancel ve Confirm
  davranislari dogrudur.
- [ ] App restart sonrasinda tema, dil, angle mode, precision, haptics, sound ve
  scientific notation ayarlari korunur.
- [ ] About & Legal ekrani `1.10.2 (34)`, package bilgisi ve calisan privacy-policy
  aksiyonunu gosterir.

## Accessibility

- [ ] Sistem text scale %200 iken kritik ekranlarda overflow/kirpilma yok;
  butonlar ve sonuclar scroll ile erisilebilir.
- [ ] Dokunma hedefleri pratikte en az 48x48 dp ve birbirinden yeterince ayrik.
- [ ] Light/dark temada metin, ikon, hata ve disabled-state kontrasti yeterli.
- [ ] TalkBack ile Splash/Home ve ana bottom navigation sirali, anlamli ve
  tekrarsiz okunuyor.
- [ ] Calculator tuslari, Calculate/Save/Delete/Reuse ve graph kontrolleri
  anlamli label, role ve state ile okunuyor.
- [ ] Yalniz ikon kullanan kritik butonlarda semantics/tooltip eksikligi yok.
- [ ] Focus, switch-access ve fiziksel klavye ile temel navigation'da odak tuzagi
  yok.

## Performance

- [ ] Cold start suresi en az bir dusuk/orta seviye cihazda olculdu; uzun bos
  frame veya ANR yok.
- [ ] Calculator hizli input ve 512 karakter siniri yakininda akici kaliyor.
- [ ] Graph agir fonksiyonlarda ve hizli zoom/range degisiminde ana isolate/UI
  akici kaliyor.
- [ ] History/Saved cok kayitla scroll, arama, filtre, delete ve reopen sirasinda
  kabul edilebilir hizda.
- [ ] Theme switch belirgin frame drop veya yanlis renk gecisi yaratmiyor.
- [ ] Dil switch layout thrash, kayip state veya uzun donma yaratmiyor.
- [ ] Navigation hizli gecislerde crash, cift route, stale state veya kayda deger
  frame drop yaratmiyor.
- [ ] 20-30 dakikalik calculator/graph/navigation soak testinde bellek artisi,
  isinma veya stabilite sorunu gozlenmiyor.

## Play Console Readiness

### Kaynak/artifact tarafinda dogrulananlar

- [x] `versionCode`: **34** (`pubspec.yaml`: `1.10.2+34`; Gradle Flutter
  metadata'sini kullanir).
- [x] `versionName`: **1.10.2**; `AppMetadata` ile uyumlu.
- [x] Package name / application ID: `com.aligundogan.calcademy`; namespace ve
  manifest activity yolu ile uyumlu.
- [x] App label: `Calcademy`.
- [x] Launcher icon: legacy density fallback'lari, adaptive icon ve Android 13
  monochrome kaynagi mevcut.
- [x] Privacy policy URL uygulamada tanimli:
  `https://gundev.dev/gizlilik/calcademy`.
- [x] Target SDK: Flutter/Android release config uzerinden **36**.
- [x] Min SDK: Flutter/Android release config uzerinden **24**.
- [x] Uygulamanin dogrudan izinleri `INTERNET` ve `ACCESS_NETWORK_STATE`.
  Release merged manifest; AdMob/Privacy Sandbox, WorkManager ve Billing
  bagimliliklarindan `AD_ID`, `ACCESS_ADSERVICES_*`, `WAKE_LOCK`,
  `FOREGROUND_SERVICE` ve `com.android.vending.BILLING` izinlerini de iceriyor.
  Bunlar Data Safety/Ads/App Content cevaplariyla eslestirilmeli ve Play Console
  pre-launch report'ta tekrar incelenmeli.
- [x] AAB release build yolu ve build gate'i tanimli.
- [x] Release signing zorunlu; `android/key.properties` mevcut, git-ignore'da ve
  release build signing yoksa acikca fail ediyor.
- [x] R8/minify ve resource shrinking acik; optimize ProGuard dosyasi ile proje
  keep kurallari kullaniliyor.
- [x] Uygulama asset'i kucuk (marka SVG'si); buyuk AAB katkisi native/SDK
  bagimliliklari. Play'in download-size raporu upload sonrasinda kaydedilmeli.
- [x] Bulunan `debugPrint` kullanimlari yalniz hata/fallback yollarinda; normal
  akis veya kullanici hesaplama verisini loglayan bir kalinti bulunmadi.
  `debugPrint` release'te de log uretebildigi icin Play-delivered release logcat'i
  hassas veri ve gereksiz stack trace acisindan tekrar kontrol edilmeli.

### Play Console / sahip onayi gerekenler

- [ ] Play Console bu uygulama icin `versionCode 34` degerini daha once kabul
  etmemis.
- [ ] AAB upload validation, Play App Signing ve upload certificate dogrulamasi
  basarili.
- [ ] Upload edilen AAB'nin version/package/signing bilgileri bu checklist ile
  ayni.
- [ ] 512x512 store icon, 1024x500 feature graphic ve guncel ekran goruntuleri
  yuklu ve marka sahibi tarafindan onayli.
- [ ] Privacy policy URL public, HTTPS ve uygulamanin gercek veri/SDK davranisiyla
  uyumlu.
- [ ] Ads declaration **Yes**; Data Safety, target audience, content rating ve
  App Content cevaplari final AAB'deki AdMob/Supabase/Billing SDK'lariyla uyumlu.
- [ ] Support email/website, store listing ve TR/EN release notes guncel.
- [ ] Internal tester listesi/Google Group, opt-in URL ve desteklenen ulkeler
  dogru.
- [ ] Play pre-launch report'ta crash, ANR, accessibility veya policy blocker yok.
- [ ] Play-delivered kurulumda UMP/AdMob, Billing ve varsa Supabase auth gercek
  hesap/cihaz kosullarinda dogrulandi.

## Exit Criteria

Internal Testing artifact'i ancak release AAB build'i basariliysa ve package,
version, signing ile Play Console deklarasyonlarinda blocker yoksa yuklenir.
Internal track'ten daha genis bir track'e promotion; cihaz smoke, persistence,
TalkBack, Play-delivered ads/consent/billing ve pre-launch kontrolleri gecmeden
yapilmaz. Crash, ANR, veri kaybi, yanlis signing/package/version, calismayan
privacy URL veya tamamlanmamis zorunlu Play deklarasyonu **NO-GO** nedenidir.

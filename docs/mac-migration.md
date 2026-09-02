# Mac geliştirme notları

Bu repo Windows'tan alınan kaynaklarla Intel Mac üzerinde incelendi.
Makineye özel yolları ve üretilmiş bağımlılık/derleme dosyalarını Git'e eklemeyin.

SDK gereksinimi: Flutter >=3.44.0 / Dart >=3.12.0. İnceleme için Flutter 3.44.0
seçildi. `flutter pub get --enforce-lockfile`, `flutter analyze` ve `flutter test`
ile başlayın; Android build için ayrıca Java ve Android SDK gerekir.

Repoda Android, iOS, web ve Windows hedefleri var; macOS hedefi yok.
iOS projesi FlutterGeneratedPluginSwiftPackage kullanıyor; Podfile bulunmaması
tek başına eksik kurulum kanıtı değildir. Plugin çözümlemesi ve iOS build ayrıca
çalıştırılmalıdır. Eski dağıtım rehberindeki Windows yolu belge örneğidir.

Bu Codex oturumunda Dart CPU bilgisi sorgusunda çöktüğü için Flutter araç
başlatması, bağımlılık çözümü, analiz, test ve build doğrulanamadı. Normal
Terminal'de `flutter doctor -v` ile devam edin. Android SDK/Java da eksiktir.

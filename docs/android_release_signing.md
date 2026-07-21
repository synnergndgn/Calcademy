# Android Release Signing

Calcademy release builds intentionally refuse to use the Android debug key. A private upload key must be configured locally before `apk --release` or `appbundle --release` can run.

## One-time upload key setup

Create the key in a private location outside the repository. Do not reuse the example passwords below; they are placeholders only.

```bash
keytool -genkeypair -v \
  -keystore /secure/path/calcademy-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Copy `android/key.properties.example` to `android/key.properties`, then replace every placeholder:

```properties
storePassword=YOUR_PRIVATE_STORE_PASSWORD
keyPassword=YOUR_PRIVATE_KEY_PASSWORD
keyAlias=upload
storeFile=C:/secure/path/calcademy-upload.jks
```

Use an absolute path with forward slashes. Both `android/key.properties` and common keystore extensions are ignored by Git. Confirm with `git status` before every release.

## Build

```bash
flutter build apk --release
flutter build appbundle --release
```

Release builds enable R8 code shrinking and Android resource shrinking. The upload key signs the local artifact; Google Play App Signing should hold the app-signing key used for distributed APKs.

## Key custody

- Keep at least two encrypted offline backups of the upload key and passwords.
- Never send the key through source control, chat, issue attachments, or CI logs.
- Store CI secrets only in the CI provider's encrypted secret store.
- Record the certificate SHA-256 fingerprint separately.
- Follow Google Play's upload-key reset process if the upload key is lost; do not rotate casually.

The validation artifacts produced during development are not production-ready unless they were signed with the final protected upload key.

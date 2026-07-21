# Android Release Signing and Upload Key Custody

Calcademy release builds intentionally refuse to use the Android debug key. A private upload key must be configured locally before `apk --release` or `appbundle --release` can run.

Google Play App Signing uses two identities:

- **Upload key:** retained by the publisher and used to sign AAB uploads. Play verifies that an authorized publisher produced the upload.
- **App signing key:** used by Google Play to sign the optimized APKs delivered to users after Play App Signing enrollment.

Use different keys for these roles. For the decision between a Google-generated and developer-generated app-signing key, complete [Play App Signing Decision Guide](play_app_signing_decision.md) and recheck the [official Google documentation](https://support.google.com/googleplay/android-developer/answer/9842756).

## One-time production upload key setup

Create the key in a private location outside the repository. Enter passwords interactively; do not embed real passwords in commands, scripts, shell history, or documentation. The following paths and names are templates only.

### Windows PowerShell

```powershell
keytool -genkeypair -v `
  -keystore "D:/secure/calcademy-upload.jks" `
  -alias upload `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000
```

### macOS/Linux

```bash
keytool -genkeypair -v \
  -keystore /secure/path/calcademy-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Use a publisher-controlled secure path, not the repository, synced project folder, or a temporary directory. Confirm current Play key requirements before generation.

## Configure `key.properties`

Copy `android/key.properties.example` to `android/key.properties`, then replace every placeholder:

```properties
storePassword=YOUR_PRIVATE_STORE_PASSWORD
keyPassword=YOUR_PRIVATE_KEY_PASSWORD
keyAlias=upload
storeFile=C:/secure/path/calcademy-upload.jks
```

Use an absolute path with forward slashes. Both `android/key.properties` and common keystore extensions are ignored by Git. Confirm with `git status` before every release.

`android/key.properties.example` is safe to copy because it contains placeholders only. The copied `android/key.properties` is private local configuration and must never be committed.

## Inspect the upload certificate

```bash
keytool -list -v -keystore /secure/path/calcademy-upload.jks -alias upload
```

Record the public SHA-256 certificate fingerprint in the private release record. Clearly label it **upload certificate** so it is not confused with the Play app-signing certificate. Public fingerprints are not private keys, but release records should still be controlled.

## Build the final AAB

```bash
flutter build apk --release
flutter build appbundle --release
```

Release builds enable R8 code shrinking and Android resource shrinking. The upload key signs the local artifact; Google Play App Signing should hold the app-signing key used for distributed APKs.

Primary Play artifact:

`build/app/outputs/bundle/release/app-release.aab`

Optional sideload/smoke artifact:

`build/app/outputs/flutter-apk/app-release.apk`

Follow [Final Release Build Checklist](final_release_build_checklist.md) for signature, hash, manifest, and pre-upload verification.

## Key custody

- Keep at least two encrypted offline backups of the upload key and passwords.
- Keep keystore backups and password-manager records in separate failure domains.
- Limit access to named release owners and enable Play Console two-step verification.
- Never send the key through source control, chat, issue attachments, or CI logs.
- Store CI secrets only in the CI provider's encrypted secret store.
- Record the certificate SHA-256 fingerprint separately.
- Follow Google Play's upload-key reset process if the upload key is lost; do not rotate casually.

With Play App Signing, Google provides an upload-key reset process; this does not make backups optional and does not mean the app-signing key is interchangeable with the upload key. Without the correct signing/Play configuration, losing keys can block future updates or other distribution channels.

## Before every release

- [ ] `android/key.properties` references the approved production upload key.
- [ ] `git check-ignore -v android/key.properties` confirms it is ignored.
- [ ] No keystore/private-key file appears in `git status` or `git ls-files`.
- [ ] The certificate fingerprint matches the release record.
- [ ] AAB/APK signature verification reports the upload certificate, not `AndroidDebugKey` or a validation certificate.
- [ ] The exact uploaded AAB hash is recorded.

The validation artifacts produced during development are not production-ready unless they were signed with the final protected upload key.

Official documentation and Play Console steps must be rechecked immediately before upload.

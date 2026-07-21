# Final Release Build Checklist

Run this checklist on the exact source revision intended for upload. Production signing material must already exist outside the repository. Do not substitute a temporary validation key.

## 1. Identity and source state

- [ ] Package, app label, version name, and version code are approved.
- [ ] `git status --short` contains only intentional release changes.
- [ ] The release revision/commit identifier is recorded.
- [ ] Release notes match `pubspec.yaml`.
- [ ] `flutter doctor -v` and the Flutter/Dart versions are recorded if reproducibility is required.

## 2. Dependency and quality gate

`flutter clean` is optional. Use it when validating reproducibility, after Android/Gradle configuration changes, or when stale outputs are suspected; it is not required for every local build.

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test --concurrency=1
flutter build apk --debug
git diff --check
```

- [ ] Every command exits successfully.
- [ ] Test count/result is recorded.
- [ ] No dependency or generated-file change is unexplained.

## 3. Production signing preflight

- [ ] `android/key.properties` points to the production upload keystore.
- [ ] The keystore path is outside the repository.
- [ ] Alias and certificate SHA-256 match the approved upload key.
- [ ] The keystore is not `AndroidDebugKey` and not a temporary validation key.
- [ ] Passwords are supplied locally/protected and do not appear in terminal history or logs.
- [ ] `git check-ignore -v android/key.properties` confirms it is ignored.

## 4. Build final artifacts

```bash
flutter build appbundle --release
# Optional sideload/smoke artifact:
flutter build apk --release
```

Expected outputs:

- `build/app/outputs/bundle/release/app-release.aab`
- `build/app/outputs/flutter-apk/app-release.apk`

- [ ] Build uses R8 and resource shrinking.
- [ ] Final artifact sizes and SHA-256 hashes are recorded.
- [ ] AAB version/package metadata matches the final decision sheet.

## 5. Signature inspection

For the optional APK, use the Android SDK `apksigner`:

```bash
apksigner verify --verbose --print-certs build/app/outputs/flutter-apk/app-release.apk
```

For the AAB/JAR signature:

```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

- [ ] Verification succeeds.
- [ ] Signer fingerprint equals the approved **upload** certificate.
- [ ] The artifact is not described as Play-delivered; Google will sign delivered APKs with the **app-signing** key.

## 6. Pre-upload Play checks

- [ ] [Play Store final decision checklist](play_store_final_checklist.md) is complete.
- [ ] [Play Console App Content checklist](play_console_app_content_checklist.md) is complete.
- [ ] Data Safety answers match the exact AAB and included SDKs.
- [ ] Privacy policy is live and accessible without authentication.
- [ ] Store text and assets are final and policy-compliant.
- [ ] Content rating, target audience, ads, app access, and financial-features declarations are saved.
- [ ] Internal-track release notes are final.
- [ ] Bundle upload reports no blocking errors.

## 7. Secret and repository postflight

```bash
git status --short
git ls-files
```

- [ ] `key.properties`, keystores, passwords, service-account files, and local SDK paths are not tracked.
- [ ] No signing secret was copied into docs or screenshots.
- [ ] Release artifact hashes and public certificate fingerprints are stored separately from private material.

## 8. Promotion gate

- [ ] Install/test a Play-delivered internal artifact or bundle-derived APK set.
- [ ] Complete `docs/release_smoke_test.md` on representative devices.
- [ ] Review Play pre-launch reports.
- [ ] Promote only the already-tested AAB; do not rebuild between testing and promotion.

Official references: [Android App Bundle testing](https://developer.android.com/guide/app-bundle/test), [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756). Recheck official documentation before upload.

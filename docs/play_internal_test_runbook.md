# Play Internal Test Runbook — AdMob 1.0.0+8

> Branch-scoped (`feature/admob-retry`). The stable `main` branch is 1.0.0+7 and
> ads-free. **Do not merge to `main`** until the Play-delivered AAB is verified
> on a real device per this runbook.

## Artifact

```
C:\Users\aligu\Documents\Calcademy\build\app\outputs\bundle\release\app-release.aab
```

| Property | Value |
|---|---|
| Size | **62.2 MB** (ads-free 1.0.0+7 was ~57.3 MB) |
| versionCode | 8 |
| versionName | 1.0.0 |
| Package | `com.aligundogan.calcademy` |
| minSdk / targetSdk | 24 / 36 |
| Signing | release keystore (`CALCADEM.RSA`) |
| ABIs | arm64-v8a, armeabi-v7a, x86_64 |
| Minify / shrink | on |

## Why this build should not repeat the 1.0.0+6 crash

Verified in this build's own R8 mapping
(`build/app/outputs/mapping/release/mapping.txt`):

- `androidx.work.impl.WorkDatabase_Impl` is kept **unrenamed**, so Room's
  reflective `Class.forName` lookup resolves.
- Its **no-arg constructor `void <init>()` is retained** — the exact member
  whose loss produced `Failed to create an instance of
  androidx.work.impl.WorkDatabase`.

## Before uploading — Play declarations

- **App content → Ads → Contains ads: `Yes`.** The build ships a Google AdMob
  banner. Leaving this `No` is a policy violation.
- **Data Safety** — rework per `docs/data_safety_draft.md`: collection `Yes (via
  AdMob)`, sharing `Yes`, device/advertising identifiers included. The old
  ads-free answers must not be reused.
- **Privacy policy URL** — must serve the AdMob-disclosing version of
  `docs/privacy_policy.md`. The currently published page still reflects
  ads-free 1.0.0+7; update it **before** rollout.
- **Target audience** — unchanged (adult/academic, not child-directed).
- **app-ads.txt** — not required to start internal testing, but required before
  broad/production release. See `docs/app_ads_txt_setup.md`.

## Upload steps

1. Play Console → **Testing → Internal testing**
2. **Create new release**
3. Upload the AAB from the path above
4. Release notes:

   ```
   Internal AdMob test build for Calcademy 1.0.0.

   This build adds banner ads on Home and Saved only. Calculation screens
   remain ad-free. Startup stability is being verified through Play-delivered
   installation.
   ```

5. **Review release** → resolve any blocking declaration warnings
6. **Start rollout to internal testing**
7. Opt in with the tester account, then install **from the Play link** (not adb)

## Device verification

Install from Play first, then:

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb devices
& $adb logcat -c
& $adb shell am force-stop com.aligundogan.calcademy
& $adb shell monkey -p com.aligundogan.calcademy 1
Start-Sleep -Seconds 10
& $adb logcat -d > admob_internal_aab_log.txt
```

```powershell
Select-String -Path admob_internal_aab_log.txt -Pattern "FATAL EXCEPTION|AndroidRuntime|Caused by|MobileAds|AdMob|Consent|UMP|APPLICATION_ID|GoogleMobileAds|WorkManager|WorkDatabase|InitializationProvider|androidx.startup|calcademy" -Context 8,30
```

Confirm the process survived:

```powershell
& $adb shell pidof com.aligundogan.calcademy
```

### Manual UI checklist

- [ ] App opens; Home renders
- [ ] Home banner loads
- [ ] Saved opens; Saved banner loads
- [ ] Scientific Calculator opens and shows **no** ad
- [ ] About shows **Version 1.0.0 (8)**
- [ ] Privacy policy link opens
- [ ] Back navigation and saved-data restore behave normally

### Pass criteria

- No `FATAL EXCEPTION`
- No `Failed to create an instance of androidx.work.impl.WorkDatabase`
- No `Unable to get provider androidx.startup.InitializationProvider`
- Process alive after launch
- Home / Saved / Calculator all verified above

> `admob_internal_aab_log.txt` is git-ignored — keep it local.

## ⚠️ Do not tap the banner

A release build serves the **real** ad unit
(`AdConfig.useTestAds` is `!kReleaseMode`). Tapping your own ad is invalid
traffic and can get the AdMob account limited or suspended. Viewing is fine;
clicking is not.

To test interactively without risk, register the device and rebuild:

1. Launch the app and read the id from logcat:

   ```powershell
   Select-String -Path admob_internal_aab_log.txt -Pattern "setTestDeviceIds|RequestConfiguration"
   ```

   The SDK logs a line containing the device hash.

2. Rebuild with the define (nothing is committed):

   ```bash
   flutter build appbundle --release --dart-define=ADMOB_TEST_DEVICE_IDS=YOUR_DEVICE_HASH
   ```

Google then serves **test** ads from the real unit id on that device only.
Omitting the define leaves production behaviour unchanged.

## Internal → Closed promotion

If the internal AAB installs and runs clean:

- Play Console → **Internal testing → the 1.0.0+8 release → Promote release →
  Closed testing**
- **Do not re-upload the AAB.** versionCode 8 already exists on the account and
  a second upload will be rejected. Promotion reuses the same artifact.
- Closed testing needs **at least 12 testers opted in**, continuously enrolled
  for **14 days**, before Production access can be requested.

## Merge decision

| Gate | Status |
|---|---|
| Release APK minify off on device | ✅ passed |
| Release APK minify on on device | ✅ passed |
| Play-delivered AAB on device | ⏳ this runbook |
| `flutter analyze` / 524 tests | ✅ passed |
| Play declarations updated | ⏳ before rollout |
| UMP consent implemented | ❌ separate sprint, required before production |
| `app-ads.txt` published | ⏳ before production |

**No merge to `main` yet.** Merge only after the Play-delivered AAB is verified
clean. Production release additionally requires the UMP consent sprint, updated
Data Safety, and a published `app-ads.txt`.

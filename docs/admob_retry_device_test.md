# AdMob Retry 1.0 — real-device verification runbook

> Branch-scoped (`feature/admob-retry`, 1.0.0+8). This is the **only** remaining
> merge gate. Everything else in the sprint is done and green.

Prebuilt artifacts (produced by this sprint, `build/` is git-ignored):

| Stage | Artifact | Minify |
|---|---|---|
| A | `build/admob_retry_artifacts/A_release-apk_minify-off.apk` | off |
| B | `build/admob_retry_artifacts/B_release-aab_minify-off.aab` | off |
| C | `build/admob_retry_artifacts/C_release-aab_minify-on.aab` | **on** |

Stage C is the configuration that crashed in 1.0.0+6. Run the stages in order
and **stop at the first crash**.

## Setup

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb devices
```

`adb devices` must list a device before continuing. If it is empty: enable USB
debugging on the phone, reconnect, and accept the RSA prompt.

## Stage A — release APK, minify off

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb install -r build\admob_retry_artifacts\A_release-apk_minify-off.apk
& $adb logcat -c
& $adb shell am force-stop com.aligundogan.calcademy
& $adb shell monkey -p com.aligundogan.calcademy 1
Start-Sleep -Seconds 8
& $adb logcat -d > admob_retry_crash_log.txt
```

Then inspect:

```powershell
Select-String -Path admob_retry_crash_log.txt -Pattern "FATAL EXCEPTION|AndroidRuntime|Caused by|MobileAds|AdMob|WorkManager|WorkDatabase|InitializationProvider|androidx.startup|calcademy" -Context 8,30
```

## Stages B and C — AAB

An AAB cannot be installed directly. Either upload to a Play **internal test**
track and install from there, or convert locally with
[bundletool](https://github.com/google/bundletool/releases):

```powershell
java -jar bundletool.jar build-apks --bundle=build\admob_retry_artifacts\C_release-aab_minify-on.aab --output=c.apks --connected-device --ks=android\<your-keystore> --ks-key-alias=<alias>
java -jar bundletool.jar install-apks --apks=c.apks
```

Then run the same logcat block as Stage A.

## Pass criteria (all stages)

- [ ] No `FATAL EXCEPTION`
- [ ] No `Failed to create an instance of androidx.work.impl.WorkDatabase`
- [ ] No `Unable to get provider androidx.startup.InitializationProvider`
- [ ] App reaches the Home screen
- [ ] Test banner appears on Home and Saved (debug/profile serve Google's test
      unit; a **release** build serves the real unit — do not click it)
- [ ] No banner on Calculator, Graph, Matrix, Equation Solver, Calculus,
      Statistics, Financial Calculator, or LP/IP/OR screens

## If Stage C crashes but A and B pass

The dependency fix worked and the remaining fault is R8-specific. Next levers,
in order:

1. Re-check `build/app/outputs/mapping/release/mapping.txt` for the class named
   in the new stack trace; add a targeted `-keep ... { <init>(); }` rule.
2. Try `com.google.android.libraries.ads.mobile.sdk` (the next-gen ads SDK)
   via `--dart-define=USE_NEXT_GEN_SDK=true`; it does not go through
   `play-services-ads` and may avoid WorkManager entirely.
3. Last resort, documented in `docs/monetization_strategy.md`: remove
   `androidx.work.WorkManagerInitializer` from the merged manifest. This only
   relocates the failure to ad-load time, so treat it as a diagnostic, not a fix.

## If any stage crashes

Do **not** merge. Keep `main` on ads-free 1.0.0+7, attach
`admob_retry_crash_log.txt`, and reopen the sprint.

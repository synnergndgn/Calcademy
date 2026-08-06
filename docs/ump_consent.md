# UMP consent

Calcademy gathers advertising consent through Google's User Messaging Platform
before requesting any ad. This is what makes an ad-supported release lawful in
the EEA, the UK, and Switzerland; without it those regions have to be excluded,
which is a large share of the addressable market for an ad-funded app.

## Order of operations

Consent is gathered **before** the Mobile Ads SDK is initialized and before any
ad is requested:

```
AdBanner mounts
  → AdConsentService.ensureConsent()
      → requestConsentInfoUpdate
      → loadAndShowConsentFormIfRequired
      → canRequestAds / privacy options status
  → if canRequestAds: AdService.ensureInitialized()
  → BannerAd load
```

`canRequestAds` is decisive, but **it does not mean the user consented.** It
means the consent-gathering flow has completed. A user who pressed *Do not
consent* still returns true here, and the SDK then serves a **non-personalised**
ad: chosen from context, with nothing stored on or read from the device. That is
Google's design, and it is why a refusal does not end in an empty screen.

Verified on device 2026-08-06: after refusing, `IABTCF_PurposeConsents` was all
zeros and a banner still served. The code was correct; an earlier draft of the
privacy policy was not, and claimed refusal meant no ads at all.

Serving nothing to refusers was considered and rejected. It would have made
declining consent a free way to remove ads, which is the subscription's main
value — so the paid tier would have been pointless in exactly the region with
the highest ARPU.

If `canRequestAds` is false the banner stays hidden and the SDK is never asked
for an ad. Outside the regions that require consent, UMP reports that none is
needed and the whole flow is one no-op round trip.

Nothing here runs before `runApp` — the same rule that the AdMob startup crash
established. Consent is driven by the first banner mounting, so a fault in the
consent path degrades to "no banner", never "no app".

## Failure behavior

The three failure modes are deliberately not treated the same way.

| Failure | Result | Why |
| --- | --- | --- |
| `requestConsentInfoUpdate` fails (offline) | Fall through to the cached state | UMP retains the previous decision. Treating a dropped connection as "no consent" would silently cost every offline impression; treating it as consent would be a compliance problem. Reading the cached answer is the only defensible middle. |
| Form cannot be shown | Cached state, which will say ads are blocked | The user genuinely has not consented yet |
| State cannot be read at all | `ConsentState.blocked()` | Never serve on an unknown state |

The starting state is blocked, so a caller that skips the await cannot serve an
ad by accident.

## Privacy options entry point

Google requires that a user who was asked for consent can reopen the choice.
Settings shows an **Ad privacy options** row, but only when UMP reports
`PrivacyOptionsRequirementStatus.required` — so a user outside the consent
regions never sees a control for a decision they were never asked to make.

Choosing to withdraw takes effect without a restart: the form's dismissal
triggers a state refresh, and the banner reads the refreshed state.

## Testing from a non-EEA country

**This is the part that is easy to get wrong.** From Türkiye, UMP correctly
reports that consent is not required, `canRequestAds` returns true immediately,
and the banner appears. The flow looks like it works while the consent form has
never been rendered once.

To actually see it, force the geography and register the device:

```powershell
flutter build apk --release `
  --dart-define=UMP_TEST_DEVICE_IDS=<ump-hashed-id> `
  --dart-define=UMP_DEBUG_GEOGRAPHY=eea
```

**UMP's device identifier is not AdMob's.** They are different hashes of the
same device and neither SDK accepts the other's value. This cost a build cycle
on 2026-08-06: passing the AdMob id left UMP treating the device as ordinary,
so it ignored the debug geography, correctly reported that a Turkish user needs
no consent, and served a banner with no form and no error. The flow was working;
the simulation was not.

Read the right one from logcat on first launch:

```
UserMessagingPlatform: Use new ConsentDebugSettings.Builder()
  .addTestDeviceHashedId("<use this>") to set this as a debug device.
```

Both defines are required — UMP ignores debug geography on a device it does not
recognise. `ADMOB_TEST_DEVICE_IDS` is a separate concern: it makes AdMob serve
test ads from the real unit so a release build can be tapped safely.

`UMP_DEBUG_GEOGRAPHY` must never be set in a shipped build. Forcing EEA on real
users would present a consent form to people whose local law does not call for
one, and would degrade their experience for no reason.

### What to verify on device

- [x] First launch in forced-EEA: the consent form appears before any banner.
- [ ] Consenting: the banner loads on Home and Saved afterwards.
- [x] Refusing: a **non-personalised** banner still serves, and the app remains fully usable. Confirm `IABTCF_PurposeConsents` is all zeros in logcat.
- [x] After refusing, Settings shows **Ad privacy options**.
- [ ] Reopening it and consenting makes the banner appear without a restart.
- [ ] Withdrawing consent hides the banner without a restart.
- [ ] Airplane mode on first launch: the app starts, no crash, no banner.
- [ ] Without the debug defines, in Türkiye: no form, banner behaves as before.

Consent state is cached by UMP across launches. To re-test the first-run
experience, clear app storage — reinstalling alone may not reset it.

## Configuration in the AdMob console

The consent form itself is authored in the AdMob console under Privacy &
messaging, not in this repository. A GDPR message must exist and be published
for the app, otherwise `loadAndShowConsentFormIfRequired` has nothing to show
and users in consent regions will never be asked — which fails closed here,
meaning no ads and no revenue in those regions.

Verify before release:

- [ ] A GDPR message exists and is **published** for `com.aligundogan.calcademy`.
- [ ] Its targeted regions cover the EEA, the UK, and Switzerland.
- [ ] The privacy policy URL in the message matches the published policy.
- [ ] If applicable, a US states message is configured as well.

## What this does not cover

- **`app-ads.txt`.** Still unpublished, and the publisher id in `AdConfig` is
  still `null`. Separate from consent; see `app_ads_txt_setup.md`.
- **Data Safety.** Consent changes how ad identifiers are processed but not
  whether they are collected, so the existing AdMob declaration still applies.
  Re-check it against the shipped SDK version regardless.
- **Child-directed treatment and `tagForUnderAgeOfConsent`.** Left unset, which
  means Calcademy asserts nothing about the user's age. If the target audience
  ever includes children, that becomes a separate decision with its own
  consequences for ad serving.

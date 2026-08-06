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

`canRequestAds` is decisive. If it is false the banner stays hidden and the SDK
is never asked for an ad. Outside the regions that require consent, UMP reports
that none is needed and the whole flow is one no-op round trip.

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
  --dart-define=ADMOB_TEST_DEVICE_IDS=<device-id> `
  --dart-define=UMP_DEBUG_GEOGRAPHY=eea
```

Find the device id in logcat on the first ad request — the Mobile Ads SDK logs
a line naming the test device identifier to add. UMP **ignores debug geography
unless the device is registered as a test identifier**, so both defines are
required; supplying only the geography silently does nothing.

`UMP_DEBUG_GEOGRAPHY` must never be set in a shipped build. Forcing EEA on real
users would present a consent form to people whose local law does not call for
one, and would degrade their experience for no reason.

### What to verify on device

- [ ] First launch in forced-EEA: the consent form appears before any banner.
- [ ] Consenting: the banner loads on Home and Saved afterwards.
- [ ] Refusing: no banner appears anywhere, and the app remains fully usable.
- [ ] After refusing, Settings shows **Ad privacy options**.
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

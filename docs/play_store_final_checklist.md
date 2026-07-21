# Play Store Final Decision Checklist

This is the release-owner decision sheet for Calcademy's first Google Play upload. Do not create the Play Console app or upload an AAB until every **blocking** item is resolved. Google Play requirements change; recheck the linked official documentation immediately before upload.

## Current verified identity

| Field | Current value | Decision |
| --- | --- | --- |
| Application ID | `com.calcademy.calcademy` | Keep unchanged until owner approval |
| App label | `Calcademy` | Candidate final value |
| Version name | `1.0.0` | Candidate first public release |
| Version code | `1` | First upload only |
| Minimum SDK | 24 | Supported by current Flutter configuration |
| Target SDK | 36 | Meets the announced 31 August 2026 mobile requirement |
| Compile SDK | 36 | Current verified build value |

Official reference: [Google Play target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878).

## Package-name decision — blocking

- [ ] The package name matches the long-term publisher/brand identity.
- [ ] The repeated form `com.calcademy.calcademy` is intentionally accepted.
- [ ] These alternatives were considered before creating the Play Console app:
  - `com.aligundogan.calcademy`
  - `com.calcademy.app`
  - `dev.aligundogan.calcademy`
- [ ] Trademark/domain ownership implications were reviewed.
- [ ] The final package name was approved before the first AAB upload.
- [ ] The Play Console app was created only after this decision was recorded.

Changing the package name later creates a different Android application and store identity; it is not a normal update path. This sprint does not change `applicationId`.

## Version decision — blocking

- [ ] Decide whether the first track is an internal beta or a public production release.
- [ ] For internal testing, either `0.1.0+1` or `1.0.0+1` can be reasonable.
- [ ] For public production, `1.0.0+1` is acceptable for Calcademy's broad, tested scope, but communicates a stable first release.
- [ ] Confirm that version name is the user-visible release version.
- [ ] Confirm that version code is a monotonically increasing technical identifier.
- [ ] Reserve a higher version code for every replacement upload; Play Console will not accept the same version code twice for the same app.
- [ ] Ensure release notes, store listing, AAB metadata, and Git tag all agree.

This sprint does not change `version: 1.0.0+1`.

## Branding and assets — blocking

- [ ] App label `Calcademy` is final in both product and store contexts.
- [ ] A production 512×512 store icon exists.
- [ ] Android adaptive launcher icon foreground/background assets exist.
- [ ] A 1024×500 feature graphic exists.
- [ ] Phone screenshots accurately show the release candidate.
- [ ] Store artwork uses only owned/licensed assets and preserves the Calcademy brand.

The repository currently contains legacy density-based launcher PNGs only; adaptive-icon XML is still missing.

## Publisher and policy — blocking

- [ ] Developer account type and verified publisher name are final.
- [ ] Public support email and website are available.
- [ ] Privacy policy is published at a stable public HTTPS URL.
- [ ] Data Safety, App Content, financial-features, content-rating, and target-audience answers were reviewed against the exact final AAB and every included SDK.
- [ ] Ads declaration is **No** for the current ad-free build.
- [ ] No account-access or reviewer credentials are required.
- [ ] Developer Program Policies were rechecked on upload day.

Official references: [Developer Program Policies](https://play.google.com/about/developer-content-policy/), [User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311).

## Release approval

- [ ] Production upload key exists outside the repository and has encrypted backups.
- [ ] Play App Signing option was explicitly selected.
- [ ] All local/CI quality gates passed on the exact source revision.
- [ ] The final AAB is signed by the production upload key, not a debug or validation key.
- [ ] Artifact SHA-256, version, signer fingerprint, build time, and Git revision were recorded.
- [ ] Release smoke test passed on a Play-delivered/internal-sharing build or bundle-derived APKs.
- [ ] No credentials, private data, or temporary signing files appear in `git status`.

## Official-documents recheck

Policy and Play Console wording can change independently of the app. Recheck official Google/Android documentation immediately before every upload; this checklist is operational guidance, not legal advice or a guarantee of approval.

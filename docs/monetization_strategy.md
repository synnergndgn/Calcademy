# Monetization Strategy — No SDK Included

This document is planning material. The current codebase contains no AdMob, advertising identifier, billing, analytics, consent, or monetization SDK.

## Options

1. **Free and ad-free:** strongest academic experience and simplest privacy posture; requires another funding source.
2. **Ad-supported:** banner, interstitial, or rewarded formats can generate revenue but add network, consent, policy, and UX costs.
3. **Freemium:** core tools remain free while genuinely advanced workflows are premium; requires entitlement and restore-purchase design.
4. **One-time paid app:** predictable user experience and no ad tracking; reduces discovery/conversion and needs pricing support.
5. **Donation/support:** low product complexity, but revenue is uncertain and store-policy implementation must be checked.

## Recommendation for Calcademy

- Launch the first public beta or release ad-free, or run a separate tightly controlled ad experiment only after stability and retention are understood.
- Do not interrupt expression entry, solving, result inspection, graphs, or saved-work review with interstitial ads.
- If banners are evaluated, limit them to non-critical areas such as Home and verify small-screen, keyboard, 200% text-scale, and offline behavior.
- Rewarded ads do not naturally align with an academic calculator unless they unlock an optional, non-essential benefit without withholding core calculations.
- Evaluate a transparent premium tier later for advanced productivity features rather than correctness, basic accessibility, or saved-data access.

## Technical work required for a future AdMob sprint

- Add `google_mobile_ads` only in the dedicated sprint and pin/review the version.
- Add the Android AdMob App ID through environment-specific configuration; never commit a real ad-unit secret into tests or examples.
- Use Google's official test App ID/ad units for development. Never click or request live ads during automated/manual testing.
- Introduce a small ad-service abstraction and an `adsEnabled` environment flag so tests and unsupported builds remain deterministic.
- Define placement rules that prohibit ads during calculation input and result workflows unless an explicit product decision changes this.
- Prepare and host `app-ads.txt` on the verified developer domain.
- Re-audit Android permissions, merged manifests, SDK transitive dependencies, network behavior, and release size.
- Update this privacy policy, Play Data Safety, store listing, and support material before release.
- Evaluate Google User Messaging Platform and consent requirements for EEA/UK and other applicable regions; provide privacy-options access where required.
- Test child-directed/content-rating settings and age-audience declarations with legal/policy review.

## Risks

- Ads can reduce trust and retention in a focused academic workflow.
- Poor placement can cause accidental clicks or obscure critical inputs/results.
- Advertising SDKs increase binary size, network surface, review complexity, and Data Safety obligations.
- Consent state, regional rules, mediation partners, and SDK behavior can change and require ongoing maintenance.
- Monetization claims or gating must never imply that a numerical result becomes more accurate after payment.

## Proposed next sprint: AdMob Integration 1.0

1. Confirm product placement and audience decisions.
2. Add test-only AdMob configuration and ad-service abstraction.
3. Implement consent/privacy-options strategy before requesting production ads.
4. Update policy, Data Safety worksheet, `app-ads.txt` checklist, and store disclosures.
5. Add unit/widget tests with ads disabled by default.
6. Verify debug, profile, release, offline, small-screen, dark-mode, and 200% text-scale behavior.
7. Use production IDs only through protected release configuration after final approval.

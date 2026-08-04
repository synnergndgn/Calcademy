# Play Billing manual test runbook

> **1.7 backend-foundation status (2026-08-04):** Google Payments profile
> verification is still pending, so `calcademy_premium_monthly` and its base
> plan cannot yet be created and no real sandbox purchase can be run. The
> entitlement migration and authenticated validation-function stub exist in
> source, but real Google Play Developer API validation is not implemented and
> staging deployment is pending.

## A. No configuration or store unavailable

1. Run the app on Windows, web, iOS, an emulator without Play Store, or a
   sideloaded Android build with no matching Play product.
2. Open **Premium** while signed out. Verify the page renders, explains that an
   account is required, and offers sign-in/create-account actions.
3. Sign in and reopen **Premium**.
4. Verify **Billing is not available on this device or build** is shown.
5. Verify Subscribe, Restore, and Manage cannot start a transaction.
6. Verify the app remains responsive and all core tools still work without an
   account.

Expected: no crash and no Premium entitlement.

## B. Internal test with a license tester

Prerequisites:

- `calcademy_premium_monthly` and base plan `monthly` are active.
- The test account is a license tester and internal-track tester.
- The signed App Bundle is published to the internal track.
- The app is installed from Google Play on a physical Android device using the
  tester account.
- The user is signed into a Calcademy test account.

Steps:

1. Open **Premium** and verify the localized title and price load from Play.
2. Tap **Subscribe** and verify the Google Play purchase sheet opens.
3. Complete a test purchase.
4. Verify **Purchase received** followed by **Backend validation pending**.
5. Restart the app and verify Premium has not been durably unlocked by the
   client-only result.
6. Tap **Restore purchases** and verify the restored purchase returns to pending
   validation without unlocking Premium.
7. Tap **Manage subscription** and verify Google Play opens the correct
   Calcademy subscription.
8. Cancel the test subscription in Google Play and confirm the app still grants
   no backend entitlement in this sprint.

Also verify that free users still see banners only on Home and Saved, while the
explicit local mock Premium entitlement hides those banners. Gemini API calls,
camera permission, OCR, and external payment paths must remain absent.

## 2026-08-04 sandbox sprint execution record

| Check | Result |
| --- | --- |
| Source branch | PR #8 merged; `main` at `7f4b845` |
| Play subscription | **Blocked** before creation: the developer account has no Google Payments merchant account |
| Product / base plan | Planned `calcademy_premium_monthly` / `monthly`; neither exists or is active yet |
| Offer | None |
| License testing | `RESPOND_NORMALLY`; no email list is selected as a license tester list |
| Internal testers | `Calcademy Tester List` is selected for the internal track (21 accounts) |
| Internal release | Build 16 (`1.6.0`) is active and available to internal testers |
| Supabase config | Build 16's local upload artifact had no staging config; build 17 AAB was rebuilt with the staging URL and publishable key and verified in all packaged ABIs |
| Build 17 upload | Pending: Chrome must allow the ChatGPT extension access to file URLs before the browser can upload the AAB |
| Device sign-in / Premium UI | Not run; requires Play installation of build 17 and a Calcademy test account |
| Product title / price | Not available because the subscription cannot be created before merchant setup |
| Purchase sheet / completion | Not run |
| Pending validation / Premium unlock | Automated tests pass; physical Play purchase confirmation is pending |
| Restore / manage subscription | Automated controller/UI tests pass; physical Play confirmation is pending |
| Negative tests | Signed-out, unavailable-product, pending-validation, restore, and cancellation-safe paths pass automated tests; device checks remain pending |

Build 17 is `1.6.0+17`. The new backend-foundation build is `1.7.0+18`; its
quality-gate artifact paths must be recorded after this sprint's builds. The
previous release AAB is at
`build/app/outputs/bundle/release/app-release.aab`. Do not report the sandbox
purchase sprint as complete until the merchant account is created, the product
and base plan are active, a license tester list is saved, and the physical
Play-installed checks in section B pass.

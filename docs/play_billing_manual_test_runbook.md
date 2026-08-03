# Play Billing manual test runbook

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
4. Verify **Purchase received, validating entitlement** followed by the
   validation-required notice.
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

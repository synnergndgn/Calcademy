# Google Play Billing setup

Calcademy 1.6 adds an Android-only Google Play Billing foundation. It does not
add an external payment method and it does not grant durable Premium access
from a client-side purchase result.

## Product plan

| Field | Value |
| --- | --- |
| Product ID | `calcademy_premium_monthly` |
| Name | Calcademy Premium Monthly |
| Product type | Subscription |
| Base plan ID | `monthly` |
| Renewal | Auto-renewing |
| Price | Set by the product owner in Play Console |
| Future product | `calcademy_premium_yearly` (not queried in 1.6) |

Benefits shown in the app are Remove ads, Gemini-powered Assistant, Camera
Solver, and higher daily limits. Gemini and Camera Solver are still inactive in
this build.

## Play Console checklist

1. Open **Monetize > Products > Subscriptions**.
2. Create a subscription with product ID `calcademy_premium_monthly`.
3. Set the name to **Calcademy Premium Monthly**.
4. Add an auto-renewing base plan with ID `monthly`.
5. Set the price and regional availability.
6. Activate both the subscription and base plan.
7. Add the test accounts under **Settings > License testing**.
8. Upload an internal-test App Bundle containing the billing library.
9. Add testers to the internal track and publish the test release.
10. Install the app from Google Play on a physical Android device using the
    license tester account.

Product metadata and localized price come from Google Play. The app must not
hard-code a production price.

## User-facing requirements

- The Premium page states that Google Play processes and manages purchases.
- Users can cancel at any time through Google Play.
- **Manage subscription** opens the Google Play subscription-management page
  for Calcademy's package and product.
- There are no external checkout, Stripe, PayPal, bank-transfer, or payment-link
  paths.
- Signed-out users are asked to sign in or create an account; the app's basic
  tools remain usable without an account.

## Build and test constraints

Billing product discovery normally works only when the application ID, signing
identity, uploaded Play build, active product, tester account, and installation
source all match. A sideloaded debug APK may safely show billing unavailable.
iOS, web, and desktop intentionally return an unavailable state in 1.6.

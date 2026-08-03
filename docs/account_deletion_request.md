# Calcademy account deletion

**Developer:** Ali Gündoğan

**Contact:** [calcademyapp@gmail.com](mailto:calcademyapp@gmail.com)

> Publication draft for Calcademy 1.4. This page must be published at a stable
> public HTTPS URL and its end-to-end request process must be verified before
> account creation is enabled in production.

## Request deletion

When account creation is enabled, use either method:

1. In Calcademy, open **Settings → Account → Delete account**, review the
   explanation, confirm the request, and submit it.
2. If you cannot access the app, email
   [calcademyapp@gmail.com](mailto:calcademyapp@gmail.com) from the address used
   for the Calcademy account with the subject **Calcademy account deletion**.
   Support may request limited verification to prevent unauthorized deletion.

Never send a password, purchase token, API key, or identity document by email.

## Data deleted

Deletion will remove the Calcademy Auth account and associated server-side data
that exists for that user, such as profile details, premium entitlement and
usage records, synced Saved data, and user-owned uploads. Local calculations
and Saved data can be removed separately by clearing them in the app, clearing
application storage, or uninstalling Calcademy.

## What may remain

Calcademy may retain a minimized record for a limited period when required for
legal compliance, tax/accounting, security, fraud prevention, dispute handling,
or transaction integrity. Any such retention will be purpose-limited and
access-controlled. Aggregated or irreversibly anonymized information that can
no longer identify the account may also remain.

Freezing, disabling, or signing out an account is not a substitute for account
deletion. The production process must delete the Auth account and associated
user data covered by the request.

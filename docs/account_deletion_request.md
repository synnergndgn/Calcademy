---
title: Calcademy Account Deletion
permalink: /account_deletion_request
---

# Calcademy Account Deletion

**App:** Calcademy

**Developer:** Ali Gündoğan

**Contact:** [calcademyapp@gmail.com](mailto:calcademyapp@gmail.com)

**Last updated:** 2026-08-03

## Delete your account in Calcademy

1. Open **Calcademy → Settings → Account → Delete account**.
2. Sign in to the account you want to delete.
3. Read the warning and select the confirmation checkbox.
4. Select **Delete account** and wait for the success message.

The authenticated deletion request is sent to Calcademy's Supabase Edge
Function. The function derives the user ID from the verified session token; the
mobile app cannot select or delete another user's account.

## Request deletion by email

If you cannot use the in-app flow, email
[calcademyapp@gmail.com](mailto:calcademyapp@gmail.com) with the subject
**Calcademy account deletion request**. Send the request from the email address
used for your Calcademy account and include only:

- the account email address;
- a short statement that you want the Calcademy account deleted;
- whether you can still access the app.

Do not send a password, session token, API key, identity document, calculation,
or payment information. Additional verification may be requested to protect the
account from an unauthorized deletion request.

## Data deleted with the account

- the Supabase Auth account identifier and email address;
- server-side profile data, if introduced;
- subscription entitlement records, except records that must be retained for a
  legal, tax, fraud-prevention, or financial obligation;
- AI or camera usage logs, if those services are introduced later;
- future cloud-saved items and other user-owned cloud records.

Calcademy 1.5 does not yet provide cloud sync, Play Billing, Gemini, camera/OCR,
or remote AI/camera logs. This list also states the deletion contract those
future services must follow before launch.

## Local data and retention

Saved calculations and settings that exist only on the device are not reachable
by the deletion server. Remove them by clearing Calcademy app data in Android
Settings or by uninstalling the app.

Limited security, legal, fraud-prevention, or financial records may be retained
for the minimum period required by applicable obligations. Retained data is
restricted to that purpose and is not used to restore the deleted account.

## Public link checklist

This repository publishes its privacy policy from `docs/` through GitHub Pages,
so this page uses the same source and a stable permalink:

`https://synnergndgn.github.io/Calcademy/account_deletion_request`

Before Play production submission, verify that the URL is public without a
login, record the same URL in Play Console, and re-test both the in-app and email
paths.

# Play App Signing Decision Guide

Google Play App Signing separates the key used to authorize uploads from the key used to sign APKs delivered to users. Make this decision before Calcademy's first Play release. Recheck the [official Play App Signing documentation](https://support.google.com/googleplay/android-developer/answer/9842756) before upload.

## Key roles

| Key | Used by | Purpose | Recovery posture |
| --- | --- | --- | --- |
| Upload key | Publisher/build process | Signs the AAB uploaded to Play and proves upload authorization | Play App Signing supports an upload-key reset process |
| App signing key | Google Play when enrolled | Signs optimized APKs delivered to users | Long-term app identity; handle the initial choice carefully |

The two keys should be different. API providers that verify installed-app signatures normally need the Play app-signing certificate fingerprint, not only the local upload certificate.

## Option A — Google-generated app signing key

Google Play generates and protects the app-signing key; the publisher creates and keeps a separate upload key.

**Advantages**

- Recommended default for most new applications.
- App-signing key is protected in Google's key-management infrastructure.
- Reduces the risk of permanently losing the distributed-app signing identity.
- Works naturally with Android App Bundles and Play-generated optimized APKs.

**Trade-offs**

- Google controls the app-signing key used for Play distribution.
- Non-Play distribution needs an explicit signing/distribution strategy.
- External API registrations must use the certificate fingerprints shown in Play Console.

## Option B — Developer-generated app signing key

The publisher generates an app-signing key and securely transfers an encrypted copy during Play App Signing enrollment, while retaining a separate upload key.

**Advantages**

- Can support a deliberate same-signing-identity strategy across multiple stores.
- Gives the publisher control over original key creation and custody policy.

**Trade-offs**

- Higher operational and backup responsibility.
- Incorrect key generation, transfer, or loss can create permanent distribution problems.
- Requires careful use of Play's current encrypted key-transfer flow and official tools.

## Recommended direction for a first-time publisher

For a new Play-only application without cross-store signature constraints, Option A is usually the lower-risk path: allow Google to generate the app-signing key and retain a separate, well-protected upload key. This is a recommendation, not an automatic project decision.

Choose Option B only when there is a documented requirement for publisher-generated app-signing identity and the publisher can operate a mature key-custody process.

## Decision checklist — blocking

- [ ] Is Play the only planned store, or must identical signatures be used elsewhere?
- [ ] Was Option A versus Option B approved by the release owner?
- [ ] Are upload key and app-signing key intentionally different?
- [ ] Is the production upload key RSA 2048 bits or stronger, matching current Play requirements?
- [ ] Are two encrypted offline backups available?
- [ ] Are keystore passwords stored in a password manager, separately from the keystore backups?
- [ ] Has two-step verification been enabled for Play Console users?
- [ ] Are the upload and Play app-signing SHA-256 fingerprints recorded and clearly labeled?
- [ ] If API providers are added later, will the Play app-signing fingerprint be registered?
- [ ] Was the current official enrollment flow reviewed in Play Console before proceeding?

## Files to keep

- Production upload keystore, outside source control.
- Encrypted offline backup copies.
- Password-manager entries for store/key passwords and alias.
- Upload certificate fingerprint record.
- Play app-signing certificate fingerprints exported/recorded from Play Console.
- A dated decision record identifying the selected option and authorized owner.

## Never commit or disclose

- `.jks`, `.keystore`, private key, or PEPK export files.
- `android/key.properties`.
- Store password, key password, recovery material, or private-key contents.
- Secrets in issue trackers, chat, screenshots, build logs, or repository documentation.

## Play Console checkpoints

1. Confirm the application package before creating/uploading the app.
2. Open the App integrity / Play App Signing flow and read the current choices.
3. Select Option A or B according to the recorded decision.
4. Upload only an AAB signed with the production upload key.
5. Compare Play's detected upload certificate with the recorded fingerprint.
6. Record the Google-held app-signing certificate fingerprints.
7. Use an internal track or Internal App Sharing to validate Play-delivered artifacts before promotion.

This guide does not create keys or enroll the application automatically.

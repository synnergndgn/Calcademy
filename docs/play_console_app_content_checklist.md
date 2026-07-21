# Play Console App Content Checklist

These are draft answers based on Calcademy's current offline, account-free, ad-free Android build. The release owner must verify every answer against the exact final AAB, dependencies, store listing, and current Play Console wording. Recheck official Google documentation before submission.

## Privacy policy

- **Draft answer:** A public privacy policy is required.
- [ ] Replace publisher/contact/date/URL placeholders.
- [ ] Publish at a stable HTTPS URL that is accessible without login or geoblocking.
- [ ] Ensure the named developer/publisher matches the Play listing.
- [ ] Provide the link in Play Console and, if required by current User Data policy, an in-app link/text.

Reference: [Google Play User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311).

## App access

- **Draft answer:** All functionality is available without login, membership, location, or special access.
- **Reviewer instructions:** No credentials required; launch the app and choose any module from Home.
- [ ] Reconfirm no feature is hidden behind environment flags in the final AAB.

## Ads

- **Draft answer:** No, the current app contains no ads.
- [ ] Reconfirm no advertising SDK, mediation adapter, ad metadata, or ad unit exists in the final dependency/manifest review.
- [ ] If AdMob is added, change this declaration before that artifact is submitted.

## Content rating

- [ ] Complete the IARC questionnaire accurately.
- **Expected current posture:** educational/tools content; no violence, sexual content, gambling, controlled substances, or online interaction.
- [ ] Do not claim a final rating until Play/IARC assigns it.

Reference: [Content rating requirements](https://support.google.com/googleplay/android-developer/answer/9859655).

## Target audience and content

- **Product positioning:** high-school, university, engineering, and adult academic users; not specifically designed for children.
- [ ] Select only age groups the app was actually designed for.
- [ ] Do not select child age groups merely to maximize availability.
- [ ] If any child age group is selected, perform a full Families Policy review before submission.

Reference: [Manage target audience and app content](https://support.google.com/googleplay/android-developer/answer/9867159).

## Data Safety

- **Draft:** developer collection = No; sharing = No, based on on-device-only processing and no data-transmitting SDK.
- [ ] Validate with `docs/data_safety_draft.md` and the exact final SDK/permission inventory.
- [ ] Complete the form even if no data is collected; non-internal testing and published apps are generally in scope.

Reference: [Data Safety form guidance](https://support.google.com/googleplay/android-developer/answer/10787469).

## Financial features declaration

Calcademy includes educational TVM, cash-flow, loan/amortization, and break-even calculators but does not offer accounts, lending, payments, trading, brokerage, or individualized investment advice.

- [ ] Complete the declaration; Google requires a response even from apps that offer no listed financial feature.
- [ ] Review the current questionnaire wording before choosing **My app doesn't provide financial features** versus **Other**.
- [ ] Do not select banking, lender, facilitator, wallet, transfer, trading, insurance, credit-reporting, or financial-advice categories unless actual behavior changes.
- [ ] Keep the educational/non-advice disclaimer consistent across the app, privacy policy, and listing.

Reference: [Financial features declaration](https://support.google.com/googleplay/android-developer/answer/13849271).

## Other declarations

| Play Console topic | Current Calcademy draft | Required verification |
| --- | --- | --- |
| News apps | Not a news app | Confirm no news publishing/aggregation feature |
| COVID-19/contact tracing | Not applicable | Confirm no related claim or API |
| Government apps | Not a government app | Confirm publisher does not represent a government entity |
| User-generated content | No hosted/shared UGC | User-entered calculations remain local |
| Account deletion | Not applicable; no account creation | Local records can be deleted in-app or by clearing app data |
| High-risk permissions | None detected in current production manifest | Recheck merged manifest of final AAB/APK |
| Purchases | None | Update if paid features or billing are added |
| Location | None | Recheck permissions and SDKs |

## Families policy decision

- [ ] Record whether Calcademy is explicitly **not designed for children**.
- [ ] Review store copy and imagery for child-directed signals.
- [ ] If under-13 audiences are selected later, reassess privacy, SDK eligibility, ads, consent, and Families requirements before release.

## Final responsibility

Play Console forms and policy language change. These drafts are not legal advice and do not guarantee approval. The publisher is responsible for accurate, complete, current declarations.

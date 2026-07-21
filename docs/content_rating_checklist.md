# Content Rating Checklist

Google Play uses the IARC questionnaire and requires a rating for every published app. Complete the live questionnaire accurately; the expected posture below is not a preassigned rating. Recheck the [official content-rating requirements](https://support.google.com/googleplay/android-developer/answer/9859655).

## Calcademy draft answers

| Topic | Current likely answer | Verification |
| --- | --- | --- |
| Violence or violent threats | No | No related content in modules/store assets |
| Sexual content or nudity | No | No related content |
| Profanity/crude humor | No | No social or editorial content |
| Controlled substances | No | No related content |
| Gambling/simulated gambling | No | Probability/statistics tools are academic, not wagering |
| Fear/horror | No | No related content |
| User-generated content | No hosted/shared UGC | User inputs stay local and are not published to others |
| Online interaction/chat | No | No account, chat, messaging, or multiplayer feature |
| Location sharing | No | No location feature or permission |
| Purchases | No, current release | No billing/IAP SDK |
| Ads | No, current release | No AdMob/advertising SDK |
| Unrestricted web access | No | No browser/webview feature |
| Educational/tools content | Yes | Academic calculator/workspace positioning |

## Important distinctions

- Probability, financial formulas, and optimization do not by themselves mean gambling, financial transactions, or financial advice.
- Locally entered expressions/notes are not a hosted user-generated-content service.
- If ads, links, community content, accounts, or remote content are added, repeat the questionnaire.
- Ads, if ever added, must be suitable for the assigned content rating.

## Submission checklist

- [ ] Store listing and screenshots contain no content absent from this assessment.
- [ ] Ads declaration matches the rating questionnaire.
- [ ] Target-audience answers are completed before/alongside rating requirements.
- [ ] Publisher contact email for IARC correspondence is correct.
- [ ] Assigned regional ratings are reviewed for unexpected results.
- [ ] A dated copy of questionnaire answers and assigned ratings is retained.

Final answers belong to the release owner and must match the exact artifact. Official docs should be rechecked before upload.

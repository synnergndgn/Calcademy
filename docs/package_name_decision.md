# Package Name Decision

This decision must be completed before the Calcademy app is created in Play Console or the first AAB is uploaded. The current Android application ID remains `com.calcademy.calcademy`; this sprint does not change it.

## Options

| Option | Strengths | Trade-offs | Best fit |
| --- | --- | --- | --- |
| **A — `com.calcademy.calcademy`** | Already configured, technically valid, lowest migration risk, aligned with the product name | Repeats the brand and does not identify a personal publisher | A long-term Calcademy brand identity where repetition is explicitly accepted |
| **B — `com.aligundogan.calcademy`** | Natural for a personal developer account, portfolio, and verified publisher identity | Couples the app ID to one publisher; spelling and identity must remain stable | An individual publisher releasing under Ali Gündoğan’s name |
| **C — `com.calcademy.app`** | Concise and brand/domain-oriented | Should be used only after Calcademy domain/brand control and naming availability are verified | A durable product organization with a matching brand/domain strategy |

All three options become costly to replace after the first Play upload because a different application ID creates a separate Android/Play identity rather than a normal update.

## Blocking decision checklist

- [ ] The Play Console app has not been created yet.
- [ ] The long-term publisher identity is known.
- [ ] Brand/domain ownership and naming risks were reviewed.
- [ ] The repeated current name is explicitly accepted or a replacement is explicitly selected.
- [ ] The final choice is recorded and approved before the first upload.
- [ ] Store listing, signing records, support identity, and source configuration use the same identity.

Changing the application ID after publication creates a different Android and Play Store identity; it is not a normal app update. If a different option is approved, perform the Gradle, Android package, tests, documentation, and artifact verification in a separate, small migration sprint. Do not combine that migration with production signing or upload.

## Final decision record

| Field | Value |
| --- | --- |
| Final selected package name | **TBD** |
| Decision owner | **Ali Gündoğan** |
| Decision date | **TBD** |
| Applied in code | **No** |

Do not edit `applicationId`, namespace, Kotlin package paths, or Play Console setup until this record is completed and approved.

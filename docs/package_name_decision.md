# Package Name Decision

This decision must be completed before the Calcademy app is created in Play Console or the first AAB is uploaded. The current Android application ID remains `com.calcademy.calcademy`; this sprint does not change it.

## Options

| Option | Strengths | Trade-offs and checks |
| --- | --- | --- |
| `com.calcademy.calcademy` | Already configured, technically valid, and aligned with the Calcademy brand | Repeats the brand name and does not identify a personal publisher |
| `com.aligundogan.calcademy` | Natural fit for a personal developer account, portfolio, and publisher identity | Couples the app identity to the named publisher; spelling must match the long-term account identity |
| `com.calcademy.app` | Short, clean, and brand/domain-oriented | Best justified when the publisher controls the Calcademy brand/domain strategy; ownership and naming availability must be verified |

## Blocking decision checklist

- [ ] The Play Console app has not been created yet.
- [ ] The long-term publisher identity is known.
- [ ] Brand/domain ownership and naming risks were reviewed.
- [ ] The repeated current name is explicitly accepted or a replacement is explicitly selected.
- [ ] The final choice is recorded and approved before the first upload.
- [ ] Store listing, signing records, support identity, and source configuration use the same identity.

Changing the application ID after publication creates a different Android and Play Store identity; it is not a normal app update. If a different option is approved, perform the Gradle, Android package, tests, documentation, and artifact verification in a separate, small migration sprint. Do not combine that migration with production signing or upload.


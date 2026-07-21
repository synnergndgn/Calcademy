# Package Name Decision

The release owner selected `com.aligundogan.calcademy` before the first Play Console upload. The Android application ID, namespace, and Kotlin MainActivity package were migrated on 2026-07-21.

## Options

| Option | Strengths | Trade-offs | Best fit |
| --- | --- | --- | --- |
| **A — `com.calcademy.calcademy`** | Already configured, technically valid, lowest migration risk, aligned with the product name | Repeats the brand and does not identify a personal publisher | A long-term Calcademy brand identity where repetition is explicitly accepted |
| **B — `com.aligundogan.calcademy`** | Natural for a personal developer account, portfolio, and verified publisher identity | Couples the app ID to one publisher; spelling and identity must remain stable | An individual publisher releasing under Ali Gündoğan’s name |
| **C — `com.calcademy.app`** | Concise and brand/domain-oriented | Should be used only after Calcademy domain/brand control and naming availability are verified | A durable product organization with a matching brand/domain strategy |

All three options become costly to replace after the first Play upload because a different application ID creates a separate Android/Play identity rather than a normal update.

## Decision checklist

- [x] The migration decision was made before the first Play upload.
- [x] The long-term publisher identity is Ali Gündoğan.
- [x] Alternatives and naming trade-offs were reviewed.
- [x] `com.aligundogan.calcademy` was explicitly selected.
- [x] The final choice is recorded and applied in source code.
- [ ] Store listing, signing records, support identity, and source configuration use the same identity.

Changing the application ID after publication creates a different Android and Play Store identity; it is not a normal app update. Treat `com.aligundogan.calcademy` as frozen after the first upload unless a completely separate app identity is intentionally created.

## Final decision record

| Field | Value |
| --- | --- |
| Final selected package name | **`com.aligundogan.calcademy`** |
| Decision owner | **Ali Gündoğan** |
| Decision date | **2026-07-21** |
| Applied in code | **Yes** |

The previous `com.calcademy.calcademy` build and the new application ID are separate Android apps. Local preferences, history, and Saved Calculations stored under the previous ID are not automatically migrated; a fresh first-store install is unaffected.

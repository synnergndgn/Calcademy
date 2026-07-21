# Calcademy 1.0.0 (Build 1) — Release Notes Draft

Calcademy 1.0.0 is the first release-candidate baseline for the offline academic calculation workspace.

## Highlights

- Professional categorized Home dashboard with localized module search
- Scientific Calculator, Graph Plotter, Matrix and Equation Solver workspaces
- Numerical Calculus, Statistics, and Financial Calculator tools
- Linear Programming, Integer Programming, and Operations Research
- Transportation, Assignment, Weighted Goal Programming, and CPM/PERT
- Shared Saved Calculations with search, filters, favorites, copy, and local persistence
- Material 3 light/dark themes, English/Turkish UI, responsive layouts, and large-text support

## Quality summary

- 441 automated tests in the release-readiness baseline
- Flutter static analysis clean at preparation time
- Debug and release build gates include APK/AAB generation and manifest/signature review
- Release builds use R8/resource shrinking and require a private upload key

## Privacy

Calculations and supported saved data remain on the device. This version has no account, backend, cloud sync, ads, analytics, or crash-reporting SDK. System sharing occurs only after a user action.

## Known limitations

- No complex-number or full symbolic-CAS support
- Numerical results use floating-point arithmetic and module-specific tolerances
- Graphing is limited to real, single-variable Cartesian functions
- Problem sizes are constrained by safe module limits
- No cloud synchronization, universal restore, PDF/CSV export, or production store deployment

## Installation note

Only artifacts signed with the publisher's protected upload key are release candidates. Locally generated validation keys and debug-signed artifacts must not be published.

## Roadmap

Final store media and legal URLs, production signing custody, accessibility field review, controlled saved-work restore expansion, and a separately reviewed monetization decision.

Suggested Git tag for the current `pubspec.yaml` version: `v1.0.0`. If a public beta should instead be `0.1.0`, decide and update the version/build number before the first Play upload; package/version history cannot be treated casually after publication.

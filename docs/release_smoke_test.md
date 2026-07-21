# Release Smoke Test

Run this checklist on the exact signed release APK/AAB candidate, not a debug build. Record device, Android version, app version/build number, locale, theme, and artifact SHA-256.

## Installation and platform

- [ ] Clean install succeeds and the launcher label is **Calcademy**.
- [ ] App launches without a debug banner, developer text, crash, ANR, or blank frame.
- [ ] Upgrade from the previous test build preserves compatible local data.
- [ ] Back navigation and Android task switching behave naturally.
- [ ] Portrait phone, small-width layout, dark mode, and 200% text scale remain usable.
- [ ] Keyboard does not cover solve/calculate actions; bottom safe area remains accessible.
- [ ] Release manifest has no unexpected dangerous permission and no INTERNET permission.

## Home and navigation

- [ ] Home hero, categorized sections, cards, and bottom navigation render correctly.
- [ ] Search `statistics` returns Statistics and hides unrelated categories.
- [ ] A no-match query shows the empty state; Clear restores all modules.
- [ ] Every active module card opens and system Back returns to Home.

## Representative module checks

| Module | Smoke input | Expected check |
| --- | --- | --- |
| Scientific Calculator | `sin(30)+2^3` in DEG | Finite result; history entry; haptic/sound settings unchanged |
| Graph Plotter | `sin(x)`, x-range −10…10 | Visible segmented curve; zoom/reset; optional share sheet opens |
| Matrix | determinant of `[[1,2],[3,4]]` | Determinant −2; copy/save available |
| Linear Programming | Built-in product-mix example | Typed optimal result and variable values |
| Integer Programming | Built-in 0–1 knapsack example | Integer/binary solution and branch summary |
| Equation Solver | `x^2 - 5x + 6 = 0` | Roots 2 and 3; exact/analytic classification |
| Calculus | derivative of `sin(x)` at 1 | Approximate value near `cos(1)` and method displayed |
| Statistics | `1,2,3,4,5` | Mean 3 and median 3 |
| Financial Calculator | NPV: −1000, 600, 600 at 10% | Finite NPV with method/input labels; no advice claim |
| Transportation | Balanced 2×2 or built-in example | Allocation totals satisfy supply/demand; method/status clear |
| Assignment | 3×3 sample | One job per real worker and correct total |
| Goal Programming | Default feasible sample | Weighted deviation and satisfaction status shown |
| CPM/PERT | A→B→C with durations 1,2,3 | Project duration 6 and critical path A→B→C |

## Copy, save, and persistence

- [ ] Copy result places the visible summary on the clipboard and shows feedback.
- [ ] Save action cannot create duplicates from a rapid double tap while saving.
- [ ] Saved Calculations shows the new record with correct module/type.
- [ ] Search, module filter, sort, favorite, copy, open-module, delete, and clear work.
- [ ] Saved records remain after force-stop and app restart.
- [ ] Clearing history/saved data requires confirmation and affects only the intended data.

## Release-only checks

- [ ] R8/resource shrinking does not remove Flutter plugins, routes, SVG logo, graph sharing, or local persistence.
- [ ] APK signature matches the protected upload certificate, not AndroidDebugKey.
- [ ] AAB passes Play Console internal-app-sharing/pre-launch checks when upload is authorized.
- [ ] Version name/code, target API, Data Safety answers, privacy URL, content rating, and store text agree.
- [ ] Final screenshots contain no private data or misleading results.

## Exit criteria

Do not promote the candidate if any module crashes, local records are lost unexpectedly, the artifact uses a debug/test key, store declarations are incomplete, or a high-impact accessibility/overflow defect remains.

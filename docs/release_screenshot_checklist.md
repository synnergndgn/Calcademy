# Release Screenshot Capture Plan

Use this as an operator runbook, together with [Screenshot Sample Data](screenshots_sample_data.md) and the format/policy criteria in [Store Asset Checklist](store_asset_checklist.md). Recheck Google Play’s official requirements before capture and upload.

## Capture baseline

- Use the exact release candidate, preferably a signed release build or a profile build when production signing is not yet available. Never show a debug banner.
- Primary phone target: a clean 1080×1920-class portrait device at 100% font scale; verify current Play dimensions and aspect-ratio rules.
- Keep locale, theme, navigation mode, status-bar time, battery, and connectivity visually consistent.
- Capture a separate Turkish set if the Turkish listing will use localized media; do not mix languages in one set.
- Remove notifications, keyboards, cursors, focus handles, snackbars, developer overlays, and personal data.
- Verify every displayed result before capture. Use only the fictional sample data referenced below.

## Eight-shot production sequence

| # | Screen and setup | Expected visible output | EN caption | TR caption | Theme | Capture target |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | **Home Dashboard:** empty search; category sections visible | Hero, search, Mathematics and Optimization/OR cards | Academic tools in one focused workspace | Akademik araçlar tek odaklı çalışma alanında | Light | 1080×1920 phone |
| 2 | **Equation Solver:** `x^2 - 5x + 6 = 0` | Roots `2` and `3`, analytic/method label, copy/save | Solve equations with method-aware results | Denklemleri yöntem bilgili sonuçlarla çözün | Dark | Same phone |
| 3 | **Calculus:** `sin(x)`; derivative at `x=1` or integral on `0..π` | Graph plus tangent/derivative or shaded integral area; approximation label | Explore functions, derivatives and integrals | Fonksiyonları, türevleri ve integralleri inceleyin | Dark | Same phone |
| 4 | **Statistics:** `1, 2, 3, 4, 5, 8, 13` | Descriptive result including mean and median | Turn datasets into clear descriptive measures | Veri kümelerini anlaşılır ölçülere dönüştürün | Light | Same phone |
| 5 | **Financial Calculator:** fictional loan or NPV case | Inputs, educational result and method; no advice claim | Evaluate educational financial scenarios | Eğitim amaçlı finansal senaryoları değerlendirin | Light | Same phone |
| 6 | **Operations Research:** 3×3 Assignment sample | Three assignments, total `9`, Hungarian/method label | Model assignment and optimization problems | Atama ve optimizasyon problemlerini modelleyin | Dark | Same phone; table fully visible/scroll-safe |
| 7 | **CPM/PERT or Goal Programming:** four-activity CPM sample | Critical path `A → B → D`, duration `10` | Plan project networks and critical paths | Proje ağlarını ve kritik yolları planlayın | Dark | Same phone |
| 8 | **Saved Calculations:** records produced by shots 2, 4 and 6 | Search, filters, favorites and record actions | Keep useful results organized on device | Yararlı sonuçları cihazınızda düzenleyin | Light | Same phone |

## Operator steps for every shot

1. Reset to the prescribed locale/theme and 100% font scale.
2. Enter the exact data from [screenshots_sample_data.md](screenshots_sample_data.md).
3. Calculate and independently compare the visible result with the expected value.
4. Dismiss keyboard, snackbars, dialogs, and selection/focus artifacts.
5. Ensure app bar, input context, result title, important value, and copy/save actions are visible.
6. Capture a clean PNG and name it `calcademy_<nn>_<screen>_<locale>_<theme>.png`.
7. Review full size and thumbnail size; then record device, Android version, build, reviewer, and date.

## Per-shot acceptance

- [ ] No debug banner, overflow stripe, clipping, private data, or unrelated system notification.
- [ ] Text and result remain legible at store-thumbnail size.
- [ ] Approximate, optimal, initial-only, and method labels are truthful.
- [ ] Result matches the approved sample data.
- [ ] Light/dark contrast and official logo colors are intact.
- [ ] Screenshot language matches the listing and caption.
- [ ] Captions contain no superlative, guaranteed-accuracy, or financial-advice claim.

Final screenshots are not generated until a controlled capture device/profile and release candidate are available.

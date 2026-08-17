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

## Capture record — 2026-08-17

The live sets in `store_assets/play_listing/` were captured against this build:

| Item | Value |
| --- | --- |
| Build | `flutter build apk --release` (signed, R8) from `1.9.4+29`, tree at commit `c257e19` |
| Phone profile | `Medium_Phone` AVD, 1080×2400 @420dpi, Android 15 (API 35) |
| 7-inch profile | `Tunathic_Tablet7` AVD, 1200×1920 @320dpi, portrait |
| 10-inch profile | `Tunathic_Tablet10` AVD, 1600×2560 @320dpi, rotated to portrait |
| Locale / theme | English, light theme, font scale 1.0 |
| Status bar | SystemUI demo mode: 12:30, battery 100%, Wi-Fi full, notifications hidden |
| Network | Wi-Fi and mobile data disabled, so the AdMob banner never loads and no impression is served from an emulator |
| Operator | Ali |

Set contents (all values re-verified against [screenshots_sample_data.md](screenshots_sample_data.md)):

- **Phone (8):** home · equation solver `x^2-5x+6=0` → 2, 3 · graphing `sin(x)`/`cos(x)` with manual Y −1.5…1.5 · calculus function analysis `x^3-3x` on [−3, 3] · statistics `1,2,3,4,5,8,13` · financial NPV → 41.32231405 · OR assignment 3×3 → total 9 · saved calculations
- **7-inch and 10-inch (4 each):** home · matrix `A×B` → `[[4,4],[10,8]]` · graphing · OR assignment

Framed listing designs live in `store_assets/play_listing/designs/` and are regenerated with
`store_assets/tools/build_listing_designs.ps1`. That script pastes each screenshot at its native
size — no scaling, cropping or recolouring — so the uploaded design always shows exactly what the
app rendered. Upload either the raw set or the framed set, not both.

Recapture whenever the UI changes materially, then update this record.

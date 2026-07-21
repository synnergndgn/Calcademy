# Google Play Store Asset Checklist

Create assets from the exact release candidate and recheck [Google Play's official preview-asset requirements](https://support.google.com/googleplay/android-developer/answer/9866151) before upload. Requirements and merchandising recommendations can change.

## Required brand assets

- [ ] **Store icon:** 512×512 PNG, final owned Calcademy artwork, no accidental transparency/cropping.
- [ ] **Feature graphic:** 1024×500 JPEG or 24-bit PNG without alpha.
- [ ] Keep the main focal point away from feature-graphic cutoff zones.
- [ ] Do not duplicate an oversized app icon as the entire feature graphic.
- [ ] Add concise, useful alt text where Play Console supports it.

Repository note: current Android launcher assets are legacy density PNGs; adaptive foreground/background XML assets are missing. Store icon and Android launcher icon are separate deliverables and both need final review.

## Screenshot sets

- [ ] Primary English phone set: 6–8 accurate screenshots.
- [ ] Optional Turkish localized phone set if the TR listing is maintained.
- [ ] Optional dark-mode subset only when it remains visually consistent with the main story.
- [ ] 7-inch and 10-inch tablet sets if tablet distribution/quality strategy requires them.
- [ ] For large-screen merchandising, review the current minimum-count, resolution, and aspect-ratio requirements in Play Console.
- [ ] No device notification, debug banner, keyboard, personal data, cursor, or test overlay is visible.
- [ ] Screenshot language matches the localized listing.
- [ ] Any caption is factual and does not imply guaranteed correctness or financial advice.

Google currently allows up to eight screenshots per supported device type and publishes additional large-screen requirements; verify the live console before production.

## Proposed production storyboard

| # | Screen | Safe example data | Caption direction | Required visible content |
| --- | --- | --- | --- | --- |
| 1 | Home dashboard | Clean initial state | “Academic tools in one focused workspace” | Brand, search, categories, cards |
| 2 | Equation Solver | `x² - 5x + 6 = 0` | “Solve equations with method-aware results” | Input, roots 2 and 3, method, actions |
| 3 | Calculus graph | `sin(x)`, derivative near `x=1` | “Explore numerical calculus and functions” | Function, graph/analysis, approximation label |
| 4 | Statistics | `1, 2, 3, 4, 5` | “Summarize data with clear descriptive measures” | Input, mean 3, median 3, method |
| 5 | Financial Calculator | PV/NPV with small fictional values | “Evaluate educational financial scenarios” | Inputs, result, no-advice wording |
| 6 | OR Transportation/Assignment | Balanced 2×2 or 3×3 sample | “Model optimization and operations research” | Method, status, allocation/assignment, total |
| 7 | Goal Programming or CPM/PERT | A→B→C durations 1,2,3 | “Plan goals and project networks” | Critical path/goal status, duration/deviation |
| 8 | Saved Calculations | Fictional sample records | “Keep useful results organized on device” | Search, filters, favorites, actions |

## Capture procedure

- [ ] Use the signed production-like build with seed data containing no personal information.
- [ ] Record device profile, Android version, locale, theme, and font scale.
- [ ] Use consistent status-bar time and navigation mode.
- [ ] Verify every shown result independently.
- [ ] Capture clean PNG originals before adding approved captions.
- [ ] Review thumbnails at small display sizes for legibility.
- [ ] Keep archived source assets and final exports with versioned names.

## Policy/quality review

- [ ] Artwork depicts current app behavior only.
- [ ] No “best,” “guaranteed,” fake ranking, award, discount, or Play badge claim.
- [ ] No real financial/account data.
- [ ] No copyrighted third-party logo or unlicensed device frame.
- [ ] Feature graphic/icon/screenshots use a consistent brand palette.
- [ ] Alt text describes meaningful visual content in plain language.

Actual production artwork is outside this sprint; this document is the acceptance checklist.

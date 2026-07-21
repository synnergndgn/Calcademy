# Google Play Store Asset Checklist

Create every production asset from the exact release candidate and recheck [Google Play's official preview-asset requirements](https://support.google.com/googleplay/android-developer/answer/9866151) before upload. Requirements and merchandising recommendations can change.

## Current repository status

- [x] Android legacy fallback and adaptive icon XML resources exist.
- [x] Adaptive foreground, background, and Android 13 monochrome references use the owned Calcademy mark and palette.
- [ ] Review foreground safe-zone, masking, themed-icon, and light/dark launcher appearance on representative devices.
- [ ] Approve final launcher artwork at small sizes; infrastructure completion is not final visual approval.
- [ ] Export and approve a separate production store icon.
- [ ] Produce and approve a feature graphic.

Existing density PNGs are retained as fallbacks. The adaptive/vector resources are derived from `assets/branding/calcademy_logo.svg`; they are not a substitute for final store-art review.

## Store icon — 512×512

- [ ] Export a 512×512 PNG from owned, final Calcademy source artwork.
- [ ] Keep the symbol simple, recognizable, and readable at very small sizes.
- [ ] Do not bake a launcher mask or rounded-corner treatment into the artwork; verify current Play masking guidance.
- [ ] Check the current Play Console alpha/transparency rule and ensure there is no accidental transparency or cropping.
- [ ] Compare the store icon with installed adaptive and legacy launcher variants.
- [ ] Verify contrast on light and dark Play surfaces.
- [ ] Export as `calcademy_store_icon_512.png` and confirm the file is exactly 512×512 pixels.
- [ ] Compare 48 px, 32 px, and 24 px previews before approval.

**Production direction:** use the existing Calcademy curve-and-data-point mark without text. Prefer the established green background (`#63897A`) with warm white (`#FBFAF5`) and amber (`#E7B77D`) foreground details. A light-background alternative may be explored, but the installed adaptive icon and store icon must remain recognizably the same product.

## Feature graphic — 1024×500

- [ ] Export a 1024×500 JPEG or 24-bit PNG without alpha.
- [ ] Use the Calcademy name and the approved “Calculate. Visualize. Optimize. Learn.” brand direction.
- [ ] Prefer one focused academic/engineering visual or a restrained product composition; avoid a crowded screenshot collage.
- [ ] Keep important text and the focal point away from likely crop/cutoff zones.
- [ ] Do not use an oversized app icon as the entire graphic.
- [ ] Decide whether one language-neutral graphic is sufficient or localized EN/TR variants are justified.
- [ ] Add concise alt text where Play Console supports it.
- [ ] Export the approved English-first asset as `calcademy_feature_graphic_en_1024x500.png`.
- [ ] If a Turkish variant is justified, export it separately as `calcademy_feature_graphic_tr_1024x500.png`.
- [ ] Confirm each file is exactly 1024×500 pixels and matches the current alpha/file-format requirements.

**Production direction:** make “Calculate. Visualize. Optimize. Learn.” the single primary message. Use a restrained academic/engineering composition with the Calcademy mark, curve/grid motifs, and at most one legible product glimpse. Avoid dense miniature UI, unsupported claims, and any visual implication of financial advice. One English or language-neutral graphic is preferred; Turkish is an optional localized variant.

## Final export QA

- [ ] Pixel dimensions and PNG/JPEG encoding are verified with an image-inspection tool.
- [ ] Alpha behavior matches current Play requirements.
- [ ] File names contain product, asset type, locale where applicable, and exact dimensions.
- [ ] Light/dark store previews and small-size previews remain recognizable.
- [ ] Play Console preview shows no crop, mask, text, or contrast defect.
- [ ] Source file, release-candidate export, reviewer, and approval date are recorded.

## Screenshot sets

- [ ] Primary English phone set: 6–8 accurate screenshots.
- [ ] Turkish localized phone set if the TR listing is published.
- [ ] Optional dark-mode subset only when it remains visually consistent with the main story.
- [ ] 7-inch and 10-inch tablet sets if the distribution/large-screen strategy requires them.
- [ ] Verify the current count, resolution, aspect-ratio, and large-screen requirements in Play Console.
- [ ] Screenshot language matches the localized listing.
- [ ] Captions are factual and never imply guaranteed correctness or financial advice.

Google currently allows up to eight screenshots per supported device type and publishes additional large-screen requirements; verify the live console before production.

## Production storyboard

| # | Screen | Safe example data | Caption direction | Theme / locale | Required visible content |
| --- | --- | --- | --- | --- | --- |
| 1 | Home dashboard | Clean initial state | “Academic tools in one focused workspace” | Light, EN primary; TR variant | Brand, search, categories, cards |
| 2 | Equation Solver | `x² - 5x + 6 = 0` | “Solve equations with method-aware results” | Dark, EN/TR | Input, roots 2 and 3, method, actions |
| 3 | Calculus graph | `sin(x)`, derivative near `x=1` | “Explore numerical calculus and functions” | Dark, EN/TR | Function, graph/analysis, approximation label |
| 4 | Statistics | `1, 2, 3, 4, 5` | “Summarize data with clear descriptive measures” | Light, EN/TR | Input, mean 3, median 3, method |
| 5 | Financial Calculator | PV/NPV with small fictional values | “Evaluate educational financial scenarios” | Light, EN/TR | Inputs, result, no-advice wording |
| 6 | OR Transportation/Assignment | Balanced 2×2 or 3×3 sample | “Model optimization and operations research” | Dark, EN/TR | Method, status, allocation/assignment, total |
| 7 | Goal Programming or CPM/PERT | A→B→C durations 1,2,3 | “Plan goals and project networks” | Dark, EN/TR | Critical path/goal status, duration/deviation |
| 8 | Saved Calculations | Fictional sample records | “Keep useful results organized on device” | Light, EN/TR | Search, filters, favorites, actions |

Use one coherent primary theme across the main sequence; theme notes above are candidates to validate, not a requirement to alternate every image.

## Capture procedure

- [ ] Use a release or profile build; never show a debug banner.
- [ ] Use a Play-compatible 1080p-class device/profile and 100% font scale for the primary set.
- [ ] Record device profile, Android version, locale, theme, and font scale.
- [ ] Use a clean, consistent status bar: time, battery, connectivity, and navigation mode.
- [ ] Hide keyboards, cursors, notifications, test overlays, and unrelated system UI.
- [ ] Use only fictional, non-personal sample data and independently verify every shown result.
- [ ] Do not create the impression of financial advice or a real financial-account workflow.
- [ ] Capture clean PNG originals before adding approved captions.
- [ ] Review both full-size images and small thumbnails for legibility.
- [ ] Keep source assets and final exports with versioned names.

## Policy and quality review

- [ ] Artwork depicts current app behavior only.
- [ ] No “best,” “guaranteed,” fake ranking, award, discount, or Play badge claim.
- [ ] No real financial/account data.
- [ ] No copyrighted third-party logo or unlicensed device frame.
- [ ] Feature graphic, icon, and screenshots use a consistent owned brand palette.
- [ ] Alt text describes meaningful visual content in plain language.

Actual production artwork and screenshots remain outside this sprint; this document is their acceptance checklist.

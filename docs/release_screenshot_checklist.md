# Release Screenshot Checklist

## Capture standard

- Use a clean production-like build with no debug banner, overflow stripes, keyboard, dialogs, notifications, or developer overlays.
- Recommended portrait capture: 1080×1920 or 1440×2560 (16:9), within current Google Play screenshot constraints. Recheck the Play Console requirements at submission time.
- Use one consistent device frame, locale, theme, font scale, status-bar time, and sample-data style across the set.
- Prefer English for the primary listing and capture a separate Turkish set if the localized listing will use localized media.
- Do not include personal notes, device identifiers, real financial information, email addresses, or other private data.
- Keep the app bar, result heading, key values, and primary actions fully visible. Avoid clipping bottom navigation and horizontal tables.

## Proposed screenshot set

| # | Screen | Theme | Example state | Must remain visible |
| --- | --- | --- | --- | --- |
| 1 | Categorized Home dashboard | Light | Hero, search, Mathematics and first module card | Logo, category heading, search field, card title |
| 2 | Scientific Calculator or Equation Solver | Dark | `x^2 - 5x + 6 = 0` → roots 2 and 3 | Input, result classification, method, copy/save |
| 3 | Graph Plotter or Calculus graph | Dark | `sin(x)` with readable axes, or derivative at x=1 | Function, graph, axis labels, result card |
| 4 | Statistics | Light | Dataset `1, 2, 3, 4, 5` | Dataset field, mean/median and method |
| 5 | Financial Calculator | Light | NPV with small illustrative cash flows | Operation, inputs, value, disclaimer-safe labels |
| 6 | Operations Research | Dark | 3×3 Assignment or balanced Transportation result | Method, total, allocation/assignment rows |
| 7 | Goal Programming or CPM/PERT | Dark | A→B→C project network result | Duration, critical path, schedule headings |
| 8 | Saved Calculations | Light | Several non-personal sample records and filters | Search, module filter, favorite and copy actions |

## Per-shot review

- [ ] Text is legible at the final store thumbnail size.
- [ ] No result is mislabeled exact/optimal when it is approximate/initial-only.
- [ ] No snackbar obscures the primary result.
- [ ] No cursor, focus ring, selection handle, or open keyboard remains accidentally.
- [ ] Light/dark contrast is correct and the official logo colors are unchanged.
- [ ] Content fits within safe areas and no navigation element is cut off.
- [ ] Sample data matches the displayed result.
- [ ] Screenshot language matches its store listing.
- [ ] Optional captions describe real capabilities without superlatives.

## Media still needed before submission

- Final launcher/adaptive icon assets
- Play Store 512×512 high-resolution icon
- 1024×500 feature graphic
- Final phone screenshot sets and optional tablet screenshots
- Public privacy-policy and support URLs

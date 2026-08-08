# UI polish review — 1.9.0 (21)

A UI/UX-only pass over every major page. No feature work, no calculation-engine
changes, no billing, auth, or ad-behaviour changes.

## What the audit actually found

Two real defects and one consistency gap. The rest of the app was already in
better shape than expected — 33 pages carried only two icon buttons without an
accessible label, and the design tokens were widely used.

### 1. A bottom inset that silently evaluated to zero

`AboutPage` and `PremiumPage` both padded their scrollable with:

```dart
MediaQuery.paddingOf(context).bottom + AppSpacing.xxl
```

Inside a `Scaffold` body the bottom inset is **already consumed**, so
`paddingOf` returns zero there and the gesture-bar clearance quietly
disappeared. The code reads as if it handles the inset. The tests passed,
because a test view has no inset either — so the assertion `bottom > 24` was
satisfied by the constant alone.

Fixed by reading `viewPaddingOf`, which still reports the physical inset at that
point in the tree.

### 2. Ten pages had no width constraint at all

Settings, Saved, History, Matrix, and the LP/IP sub-pages ran edge to edge on a
tablet while Home, Assistant, Premium, Formula, and the account screens stayed
centred. On a 1024 px-wide device that is the difference between a readable
column and a full-width line of text.

### 3. Hardcoded spacing literals

`fromLTRB(16, 8, 16, 28)`, `fromLTRB(4, 24, 4, 10)`, `fromLTRB(16, 0, 16, 24)`
sat next to `AppSpacing` constants that already expressed the same values.

## The shared component

Rather than adding another literal to each of ten files — which widens drift
instead of closing it — the fix is one component, `lib/core/widgets/page_body.dart`.

`PageBody` **only constrains and centres**. It deliberately adds no padding,
because a scrollable needs its padding *inside* the viewport: padding applied
outside the scroll view cannot be scrolled under, so content is clipped by it
instead of passing beneath.

`PageBody.scrollPadding(context)` supplies that padding — width-aware sides plus
a bottom that clears the gesture bar — and reads `viewPaddingOf`, which makes
defect 1 structurally unavailable to anyone using it.

`PageBody.form` narrows to `AppBreakpoints.compact` for the auth screens, where a
full-width text field is hard to scan.

## Per-page review

| Page | Issues found | Fixes applied | Remaining notes | Small screen | Dark mode | Login-free |
| --- | --- | --- | --- | --- | --- | --- |
| Home | None — already constrained, responsive grid, compact hero | — | Ad banner behaviour unchanged | ✅ | ✅ | ✅ |
| Calculator | None | — | — | ✅ | ✅ | ✅ |
| Saved | Four tab lists unconstrained; list padding did not clear the anchored ad | Page constrained once at the `TabBarView`; three list paddings moved to `scrollPadding` | Card inner padding deliberately left fixed | ✅ | ✅ | ✅ |
| Formula Library | None | — | — | ✅ | ✅ | ✅ |
| Formula Detail | None | — | — | ✅ | ✅ | ✅ |
| Graph Plotter | None | — | — | ✅ | ✅ | ✅ |
| Matrix | Unconstrained body | Wrapped in `PageBody`, `scrollPadding` | — | ✅ | ✅ | ✅ |
| Equation Solver | None | — | — | ✅ | ✅ | ✅ |
| Calculus | None | — | — | ✅ | ✅ | ✅ |
| Statistics | None | — | — | ✅ | ✅ | ✅ |
| Financial Calculator | None | — | — | ✅ | ✅ | ✅ |
| OR | Two stepper icon buttons had no accessible label | Tooltips derived from the field label | — | ✅ | ✅ | ✅ |
| LP / IP | Sub-pages unconstrained | **Not changed** — see remaining limitations | Deep-navigation screens, varied body shapes | ✅ | ✅ | ✅ |
| AI Assistant | None | — | Local-only; no ads, no backend | ✅ | ✅ | ✅ |
| Premium | Bottom inset read as zero | `viewPaddingOf` | State hierarchy unchanged | ✅ | ✅ | ✅ |
| Account | None | — | — | ✅ | ✅ | ✅ |
| Sign In | Hand-rolled `Center`/`ConstrainedBox`; submit button could sit under the gesture bar | `PageBody.form` + `scrollPadding` | — | ✅ | ✅ | ✅ |
| Create Account | Same as Sign In | Same | — | ✅ | ✅ | ✅ |
| Delete Account | Structure differs from the other two | **Not changed** — reviewed, no defect found | Destructive confirmation intact | ✅ | ✅ | ✅ |
| Camera Solver | None — placeholder only | — | Still gated, still a placeholder | ✅ | ✅ | ✅ |
| Settings | Unconstrained; three hardcoded padding literals | `PageBody` + `scrollPadding`; literals replaced with `AppSpacing` | — | ✅ | ✅ | ✅ |
| About | Bottom inset read as zero; unconstrained | `PageBody` + `scrollPadding(bottom: xxl)` | — | ✅ | ✅ | ✅ |
| History | Unconstrained; three hardcoded literals | `PageBody` + `scrollPadding`; literals replaced | — | ✅ | ✅ | ✅ |
| Splash / Coming Soon | None | — | — | ✅ | ✅ | ✅ |

## Overall summary

The polish here is narrow on purpose. The app did not need a visual redesign; it
needed the places where a token had been bypassed or an inset misread brought
back in line. Eight page bodies now share one wrapper, two genuine layout bugs
are fixed, and two icon buttons became announceable.

Nothing about calculation, billing, entitlement, consent, or ad placement
changed. The ad matrix — free sees banners on Home and Saved, active or mock
premium hides them, pending validation does not, and no other page carries one —
is unchanged and still covered by its existing tests.

## Testing added

`test/app/production_readiness_test.dart` renders all 23 major pages across five
configurations: a modern phone, a 360×640 screen at 1.3 text scale, Turkish at
360 px, dark mode, and tablet width — plus every calculation tool with the
account surface compiled out. 130 assertions.

This matters more than a targeted assertion would: a layout overflow throws
during paint, so a page that merely *renders* is proving the thing that broke.

## Known remaining UI limitations

- **LP/IP sub-pages are still unconstrained.** Branch tree, model editor, model
  summary, solution, and simplex steps each have a differently shaped body, so
  adopting the wrapper is a per-file edit rather than a pattern replacement.
  They are deep-navigation screens; the visible cost is limited to tablet width.
- **Landscape is only sanity-checked.** The suite covers portrait geometries.
  Nothing is known to break, but nothing verifies it either.
- **Text scale above 1.3 is untested.** Android allows up to 2.0. The existing
  Home and About tests cover 2.0 for those two pages only.
- **`AppBreakpoints.pagePadding` returns raw 24/16** rather than `AppSpacing`
  constants. Cosmetic, and changing it would touch every page's geometry.

## Real device verification notes

**Not performed for 1.9.** The 1.8.0+20 device pass (Xiaomi 23021RAAEG,
Android 15) verified consent, ad placement, and the free-build surface; those
paths are untouched here.

The two fixes that most deserve a device check are exactly the ones a test
cannot confirm: the gesture-bar clearance on About and Premium only shows a
difference on a device that *has* a gesture bar, since a test view reports no
inset. Recommended before release:

- About and Premium scrolled to the bottom on a gesture-navigation device — the
  last element should clear the bar.
- Sign In and Create Account with the keyboard raised — the submit button should
  stay reachable.
- Settings, Saved, and History on a tablet — content should be centred, not
  edge to edge.

## Production readiness

**Ready**, with the device checks above as the closing step.

The changes are structural rather than behavioural: no logic, no engine, no
security path was touched. `flutter analyze` is clean, the suite passes, and the
release bundle builds. The residual risk is that a layout change looks right in
a test view and wrong on hardware — which is precisely why the three checks
above are listed rather than assumed.

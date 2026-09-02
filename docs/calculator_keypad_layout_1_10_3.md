# Scientific calculator keypad layout — 1.10.3 (35)

Why 1.10.2 (34) did not fix the reported defect, what actually causes it, and
what 1.10.3 changes. All measurements below are logical pixels (dp) produced by
`flutter test` against `CalculatorPage`, not estimates.

## The report

A user on a current install of 1.10.2 (34), reinstalled from Google Play, still
sees the scientific calculator ending at the `1 2 3 − %` row. The rows holding
`Ans 0 . AC ⌫` and `+ =` are not on screen. The expression and result areas
take roughly half the height. Reinstalling changes nothing.

Reinstalling was never going to change anything: the layout is computed from
the viewport on every build and holds no cached state.

## What 1.10.2 actually fixed

`2e0fa7b` pinned the expression display and the result panel and gave the
keypad the height left over, instead of letting one scrolling column push them
off the top. That was the right direction and it is in the released tree —
`2e0fa7b` is an ancestor of `a1cfca5` ("Release 1.10.2+34"), and `pubspec.yaml`
on that commit reads `1.10.2+34`.

It was validated at exactly one viewport: 360x800 dp with a 30 dp status bar
and a 48 dp three-button navigation bar. The keypad needs
`9 rows x 40 dp + 8 gaps x 7 dp = 416 dp` there and gets 419 dp. Three dp of
slack, and the test asserted only the idle state.

## Three ways that slack disappears

Measured on `CalculatorPage`, keypad viewport height vs. the 416 dp needed:

| Viewport | Keypad gets | Result |
|---|---|---|
| 360x800, 3-button nav (the validated target) | 419 dp | fits — until a result lands |
| 360x800, 130% text | 357 dp | `=` and `+` not built, 5 keys clipped |
| 360x740 (1080x2220 panel) | 361 dp | `=` and `+` not built |
| 328x729 (1080x2400, display size one step up) | 352 dp | 7 rows visible — matches the screenshot |
| 320x711 (display size at maximum) | 332 dp | 7 rows visible |

1. **Display size.** Android's display-size setting changes density, so the
   same 1080x2400 panel is 360x800 dp at the default and about 328x729 dp one
   step up. 71 dp of viewport height simply stops existing. The reporter's
   screenshot measures to roughly this, which is the most likely explanation
   for it, though the device model, density and font scale are not recoverable
   from an image and this stays a hypothesis.
2. **Font size.** The expression display reserved two lines of `headlineSmall`,
   which is 64 dp at 100% and 126 dp at 130%. The keypad pays for all of it.
3. **Pressing equals.** This one hits every device including the validated
   target. `ResultPanel` put its copy/save/use buttons on a row of their own,
   which appears only once there is a result: the panel goes from 116 dp to
   149 dp, the keypad drops from 419 dp to 386 dp, and `=` and `+` — the key
   just pressed — leave the viewport.

In every case the keypad fell back to scrolling inside itself, with
`NeverScrollableScrollPhysics` swapped for `ClampingScrollPhysics` and no
scrollbar, no partial row and no other affordance. `GridView.builder` does not
build rows past the viewport, so the last row does not exist in the tree at
all: nothing on screen suggests there is anything below `1 2 3 − %`.

## Root cause

The height every part of the page needs is a function of the viewport, the
display density and the text scale, and 1.10.2 hard-coded it instead:

- `ResultPanel` had a fixed 116 dp floor and grew by an action row it never
  budgeted for.
- `ExpressionDisplay` reserved two lines that scale with the text scale, and
  could grow to four as the expression wrapped.
- The keypad's only adaptation was a 40 dp minimum key height on a fixed
  5-column, 9-row grid.
- The page chose between the pinned and the scrolling layout on a fixed
  560 dp viewport-height threshold, which knows nothing about text scale.

## What 1.10.3 changes

Nothing about calculation, key behaviour, key set or key ordering.

- `ResultPanel` takes a `minHeight` and an `actionsInHeader` flag. The
  calculator puts its actions on the label row, in 36 dp buttons, with that
  row's height reserved whether a result is present or not — so the panel is
  the same height before and after a calculation.
- `ResultPanel.heightFor` and `ExpressionDisplay.heightFor` report what each
  will occupy at the ambient text scale, so callers can budget before layout
  instead of discovering the overflow after it.
- `ExpressionDisplay` takes a line count. Pinned, it cannot grow past what it
  reserved; a long expression scrolls inside the field.
- `_CalculatorWorkspace` measures. If the comfortable header would leave the
  keypad less than it needs, the header goes dense — one display line, no
  116 dp floor, tighter gaps — before the keypad loses anything.
- `CalculatorKeypad.resolveLayout` picks the arrangement: 6 columns x 7 rows
  first, 5 columns x 9 rows when 6 would put keys under 44 dp wide, and
  scrolling — now with a visible scrollbar — only when neither fits.
- `CalculatorPage` decides between pinned and scrolling by measuring whether
  the tightest header plus the keypad's minimum fit, replacing the 560 dp
  threshold. Landscape and text scales past ~200% scroll the whole page, which
  is what they should do.

The 6-column arrangement also settles a question the report raised. The digits
spreading raggedly across rows (`9 ÷ ( ) 4`) was not a design decision; it is
42 keys reflowing into 5 columns. At 6 columns the list divides evenly:
functions, inverse functions, constants, then three digit rows and the edit
row.

## Verification

`flutter test`, 970 tests, all passing. The keypad matrix asserts, for each
viewport below, that the keypad sits inside the safe area, that its
`maxScrollExtent` is zero, and that every one of the 42 keys renders fully
inside the keypad — checked both before and after evaluating `1+2`, with the
result panel asserted to be the same rectangle in both:

360x800 3-button · 360x800 gesture · 328x729 · 320x711 · 360x740 ·
360x800 @130% · 360x800 @200% · 412x915

Resolved arrangements: 6x7 everywhere except 320x800 and 300x640, which take
5x9 because 6 columns would put keys under 44 dp wide.

`0`, `.`, `=`, `AC` and `⌫` are exercised by tapping them where they land in
each viewport, not merely located.

Two more tests cover the fallbacks: a keypad given less height than it needs
scrolls, shows a `Scrollbar` and still delivers every key tap, and 300% text
falls back to the scrolling page without a `RenderFlex` overflow.

### Not verified here

- **No device or emulator run.** No Android device is attached and no AVD or
  system image is installed on this machine.
- **No release build.** `flutter build apk --release` stops at
  `android/key.properties`, which is deliberately outside Git. The AOT profile
  build was run instead to confirm the tree compiles.
- **No Play Console access**, so nothing here confirms which artifact the
  reporter's device is running. To establish that, compare Play Console's
  latest production release against Settings > Apps > Calcademy on the device:
  it should read `1.10.2 (34)` before the update and `1.10.3 (35)` after.
- **The reporter's device model, logical resolution, density and font scale**
  are not recoverable from the screenshot. The 328x729 hypothesis fits its
  measured proportions; it is not confirmed.

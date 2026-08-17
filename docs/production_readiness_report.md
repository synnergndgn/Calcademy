# Calcademy Production Readiness Report

## Date

2026-08-10 (Europe/Istanbul)

## Environment

- Host: Microsoft Windows NT 10.0.26200.0, PowerShell
- Flutter: 3.44.0 stable (`559ffa3f75`)
- Dart: 3.12.0 stable
- App: Calcademy 1.9.3+26, `com.aligundogan.calcademy`
- State/routing: Riverpod 3.3.2 with `NotifierProvider`; GoRouter 17.3.0 with a shell route for Home, History, Saved, and Settings
- Persistence: SharedPreferences for settings, history, legacy saves, graph, matrix, LP, and IP; a versioned saved-calculations repository for cross-module result archives
- Localization: custom synchronous TR/EN map plus Flutter localization delegates
- UI: Material light/dark/system themes, shared academic design system, responsive breakpoints, graph-paper surfaces
- Test inventory after this review: 102 Dart test files, 704 static test declarations, 849 executed test cases in the final full run

The repository is feature-oriented under `lib/features`, with shared app, theme, routing, premium/auth/ads, localization, and core widget/service layers. In addition to Splash, Home, Calculator, Graph, History, Saved, Settings, and About, the shipped code contains Matrix, Linear/Integer Programming, Equation Solver, Calculus, Statistics, Financial Calculator, Operations Research, Formula Library, account/premium, ads, and assistant surfaces.

Main packages: `flutter_riverpod`, `go_router`, `shared_preferences`, `intl`, `flutter_svg`, `fl_chart`, `share_plus`, `url_launcher`, `google_mobile_ads`, `supabase_flutter`, and `in_app_purchase`.

## Commands Run

| Command | Result | Notes |
|---|---|---|
| `flutter --version` | PASS | Flutter 3.44.0, Dart 3.12.0 |
| `flutter clean` | PASS | Removed build and generated Flutter state |
| `flutter pub get` | PASS | Dependencies resolved; 30 newer versions are outside current constraints |
| `dart format --set-exit-if-changed .` | FAIL, then PASS | Initial run formatted 3 files; final run checked 412 files and changed 0 |
| `flutter analyze` | PASS | Final result: no issues found |
| `flutter test` (baseline) | FAIL | 835 passed, 2 timing-sensitive graph tests failed under full-suite load |
| Targeted graph tests | PASS | Both baseline failures passed in isolation; waits were made completion-based rather than fixed 30/50 ms margins |
| Targeted new tests | PASS | Calculator, settings, history, graph, matrix, LP, and IP persistence tests all passed |
| `flutter test --reporter compact` (final) | PASS | 849/849 tests passed in 180.5 seconds |
| `flutter build apk --release` | PASS | Signed/minified APK built; 66.95 MiB |
| `flutter build appbundle --release` | PASS | Signed/minified AAB built; 66.19 MiB |
| `git diff --check` | PASS | No whitespace errors |
| Privacy URL HTTP check | PASS | `https://gundev.dev/gizlilik/calcademy` returned HTTP 200 |

Release artifacts:

- `build/app/outputs/flutter-apk/app-release.apk` — SHA-256 `74AF67A14BFEADC54A1E0F292D6C697F2DA55CAE8DD35E14595C4857A972EB2C`
- `build/app/outputs/bundle/release/app-release.aab` — SHA-256 `7D5A9BDC0395FD529F3BAB82BE1F4975F85681181B98A79E767F4D30CF180C8D`

## Module-by-Module Results

### Splash
Status: PASS

Findings: Uses a bounded 560 ms animation, mounted guard before navigation, SafeArea, centered scrollable content, and theme-derived colors. The production readiness matrix renders major pages across phone/tablet, dark mode, Turkish, and enlarged text.

Fixes: None required.

### Home
Status: PASS

Findings: Navigation targets, empty recent-history state, free-build surface, theme quick toggle, TR/EN rendering, dark mode, phone/tablet layouts, and large-text layouts are covered by routing, home, branding, theme, and production-readiness tests.

Fixes: None added in this review; pre-existing UI-polish changes were preserved.

### Calculator
Status: PASS

Findings: Engine tests cover arithmetic, precedence, parentheses, negative and decimal values, implicit multiplication, powers, roots, trigonometry in degree/radian modes, logarithms, constants, Ans, factorial, percentage, modulo, malformed input, domain failures, undefined tangent, and division by zero. Results reject NaN and Infinity. The UI has keypad semantics, history/save integration, tablet notebook layout, and result auto-scroll tests.

Fixes: Added a 512-character engine guard so hostile or accidentally huge expressions are rejected before lexer/parser work can consume excessive CPU or recursion depth.

### Graph / Function Plotting
Status: PASS

Findings: The compiler caps source at 256 characters. Sampling is bounded by initial segment, recursion-depth, point, evaluation, drawable-magnitude, and segment limits; native sampling runs in an isolate, uses debounce/generation cancellation, and caches bounded results. Tests cover `(1/30)^x+e^(x/4)`, `e^(x/4)`, `(1/30)^x`, `sin(x)*e^x`, `1/(x-1)`, `sqrt(x)`, `ln(x)`, `tan(x)`, invalid ranges, manual Y bounds, discontinuities, five-function stress, cancellation, themes, and responsive controls.

Fixes: Replaced two fixed post-debounce test delays with an explicit bounded wait for sampling completion. This removed full-suite load flakiness without weakening assertions.

### History
Status: PASS

Findings: Add, reuse, save, delete, empty state, 200-record cap, Today/Yesterday/This Week/Older grouping, restart persistence, and confirmed bulk clear are implemented or tested. Records are newest-first.

Fixes: Corrupt envelopes and wrong-type preference values now fall back safely. Invalid individual records are skipped while valid records remain available instead of crashing provider construction.

### Saved
Status: PASS

Findings: Empty states, graph/matrix/optimization/integer/archived/legacy calculation types, reopen/reuse, editing, deletion, filtering, favorites, and restart persistence have repository or widget coverage. The versioned cross-module repository reports corrupt schema/payload/storage failures and skips invalid individual items.

Fixes: Graph, matrix, LP, IP, history, and legacy calculator-save repositories now preserve valid records when a neighboring record is corrupt.

### Settings
Status: PASS

Findings: Light/dark/system, TR/EN, angle mode, haptics, sound, precision, scientific notation, restart persistence, and confirmed destructive History/Saved actions are present. Responsive production tests cover the screen at small width, large text, dark mode, Turkish, and tablet size.

Fixes: Unsupported stored languages and themes now fall back safely; precision is clamped to the Slider's supported 4–15 range; public setters also normalize invalid language and precision input.

### About
Status: PASS

Findings: Version/build metadata matches `pubspec.yaml`; legal/responsible-use content and localized copy behavior are tested; small-screen/200% text and dark mode render tests pass. The production privacy URL returned HTTP 200.

Fixes: None required.

### Navigation
Status: WARNING

Findings: Shell navigation, Calculator/History/Saved flows, formula routes, saved restoration routes, account, assistant, and premium routes have smoke/integration coverage. Android back behavior relies on standard GoRouter/Navigator behavior. No custom unknown-route page or Android deep-link intent filter is configured; these are not current advertised features.

Fixes: None required for the current route contract.

### Localization
Status: PASS

Findings: TR/EN supported locales, multiple module key-parity tests, full-page Turkish render coverage, and long-label responsive cases pass. Flutter's Material/Widget/Cupertino delegates are installed. Some product names and formula notation are intentionally language-neutral.

Fixes: Invalid persisted locale values now resolve to a supported locale.

### Theme / UI
Status: PASS

Findings: Shared academic surfaces, graph-paper background, notebook/dock/calculator styling, light/dark theme matrices, and responsive page wrappers are covered. Major pages render without exceptions on 390×844, 360×640 at 1.3 text scale, Turkish, dark mode, and 1024×1366.

Fixes: The requested formatter corrected three pre-existing formatting deviations; no visual identity changes were made by this review.

### Persistence
Status: WARNING

Findings: Corrupt JSON, wrong envelopes, invalid records, schema mismatches, independent preference keys, restart round-trips, and versioned saved-calculation failures are covered. Reads now fail closed without crashing and preserve valid neighboring records.

Fixes: Hardened history, legacy saved, graph, matrix, LP, IP, and settings reads against corruption and legacy types.

Remaining warning: Legacy SharedPreferences controllers update in-memory state before awaiting disk writes, and most legacy repositories do not surface a `false` write result to the UI. A storage-full/platform write failure could therefore leave the current session ahead of disk until restart. This was not observed in tests and is not a release blocker, but a transactional repository abstraction is recommended.

### Performance
Status: WARNING

Findings: Calculator work is bounded by expression length. Graph work is isolated and bounded, with debounce, cancellation generation, cache capacity, safe magnitude/range guards, and hard sample/evaluation limits. Collection limits exist for history and saved archives. Performance-focused matrix, simplex, MIP, graph, and responsive tests pass.

Fixes: Added the calculator length guard and deterministic asynchronous graph completion tests.

Remaining warning: No physical low-end Android profile run, startup trace, frame-timing capture, or long-session memory profiling was performed in this Windows test environment.

### Accessibility
Status: WARNING

Findings: Calculator keys expose semantic labels; primary icon actions generally expose tooltips; shared controls use Material touch targets; major layouts pass enlarged-text tests including targeted 200% cases.

Remaining warning: No TalkBack screen-reader traversal, contrast-instrument audit, switch-access run, or complete physical-keyboard workflow was performed. The calculator expression field is intentionally read-only and physical keyboard entry is limited to existing shortcuts.

## Tests Added

1. Calculator rejects an excessively long expression before parsing.
2. Settings recover from invalid theme/language/angle/precision values and clamp setter input.
3. History and legacy saved calculations round-trip across repository reconstruction.
4. History/legacy saved malformed and wrong-shaped payloads fall back safely.
5. History/legacy saved mixed payloads preserve valid records.
6. Graph repository preserves valid workspaces beside corrupt records and handles invalid envelopes.
7. Matrix repository preserves valid operations beside a corrupt record.
8. Linear Programming repository preserves valid models beside a corrupt record.
9. Integer Programming repository preserves valid models beside a corrupt record.
10. Two existing asynchronous graph controller tests were hardened to wait for actual completion with a 10-second failure bound.

## Bugs Fixed

- Prevented crashes during History/Saved provider construction from valid JSON with the wrong shape or invalid records.
- Prevented one corrupt graph, matrix, LP, or IP record from hiding every valid saved item in the same payload.
- Prevented corrupt settings precision from violating the Settings Slider range and unsupported language values from entering app state.
- Prevented unbounded calculator expressions from reaching the recursive parser.
- Removed load-dependent false failures from graph cancellation/stress tests.
- Corrected formatter drift in three pre-existing Dart files.

## Remaining Warnings

- 30 dependencies have newer releases outside current constraints; no blind upgrade was attempted during release stabilization.
- Android build reports deprecated API usage in transitive/native inputs; it does not fail compilation or R8.
- Physical-device profiling, TalkBack, process-death/restart, real AdMob/UMP consent, Play Billing, Supabase auth, and Play Internal Testing flows still require device/account-backed manual verification.
- No custom unknown-route UI or advertised deep-link contract exists.
- Legacy SharedPreferences writes are not transactional and do not consistently expose write failure to users.
- APK/AAB size is about 67/66 MiB; Play delivery will split the AAB, but size should be monitored.

## Blockers

None found in the code, automated test, static analysis, signing, APK, or AAB gates.

## Final Verdict

Production Ready: YES

The code and release artifacts satisfy the stated automated production gate: clean analysis, clean formatting, 849/849 tests, no critical calculator failure, hardened corrupt-data reads, bounded heavy graph work, and successful signed release APK/AAB builds. Rollout should still use Play Internal Testing before broad production because device-only ads, billing, accessibility, frame timing, and process-death scenarios remain warnings rather than proven passes.

Category verdicts:

| Category | Verdict |
|---|---|
| Stability | PASS |
| Calculator correctness | PASS |
| Data safety | WARNING |
| Performance | WARNING |
| UI/UX consistency | PASS |
| Responsiveness | PASS |
| Accessibility | WARNING |
| Localization | PASS |
| Release build readiness | PASS |
| Play Store readiness | WARNING |

## Next Recommended Actions

1. Upload the generated AAB to Play Internal Testing and complete the existing device smoke runbook on at least one low-end phone, one current phone, and one tablet.
2. Exercise UMP consent, live test ads, Play Billing purchase/restore, Supabase auth, app background/kill/restart, and storage-full behavior on device.
3. Run a Flutter profile build with startup/frame timing and a 20–30 minute graph/navigation/memory soak.
4. Complete TalkBack, 200% font, contrast, and switch/keyboard accessibility checks.
5. Introduce a small transactional storage abstraction for legacy SharedPreferences repositories and surface write failures before a future release.
6. Review constrained dependency upgrades in a separate change set, then rerun this full gate.

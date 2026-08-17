# Dormant feature tests

These tests cover product experiments that are **not part of the shipped
application**: Supabase auth, Google Play Billing, Premium entitlement, the
remote AI assistant and the camera solver. Their sources are still in `lib/`
for reference but are excluded from the analyzer and are not linked into the
release build (see `analysis_options.yaml` and
`docs/release_privacy_remediation_1.9.4_28.md`).

They live outside `test/` because `flutter test` collects everything under
`test/` and does not read the analyzer's exclude list. Each file here imports
`supabase_flutter` or `in_app_purchase`, which were dropped from `pubspec.yaml`
in 1.9.4+28, so they fail to *load* — a compile error, not an assertion
failure. Left in place they turn the whole suite red and hide real
regressions.

Dormant tests that still load and pass were deliberately left under `test/`.
They cost nothing and confirm the retained sources still behave, so the rule is
narrow: a test moves here only when its dependency no longer exists.

## Running them

They cannot run as-is. Restoring `supabase_flutter` and `in_app_purchase` to
`pubspec.yaml` and moving the files back under `test/` is the whole procedure —
but doing that also puts those SDKs back in the shipped dependency graph, which
the published privacy policy says are absent. Re-enabling any of this means
updating the policy and the Play Data Safety form first.

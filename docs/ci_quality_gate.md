# CI and Quality Gate

Calcademy's production signing material should not be added to CI merely to automate an early release. Start with secret-free pull-request checks; add signed release automation only after a separate security decision.

## Required local gate

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test --concurrency=1
flutter build apk --debug
git diff --check
```

When the authorized production upload key is configured locally:

```bash
flutter build appbundle --release
flutter build apk --release
```

- Record Flutter/Dart/Java versions for release reproducibility.
- Run the gate on the exact release revision.
- Do not treat a documentation-only check as proof that a signed artifact works.

## Suggested GitHub Actions PR gate

Without adding a workflow in this sprint, the recommended first CI scope is:

1. Checkout with minimal required permissions.
2. Install/pin the project's approved Flutter stable version.
3. Cache Flutter/pub artifacts using trusted actions and reviewed versions.
4. Run `flutter pub get`.
5. Run format check, analyze, and all tests.
6. Build the debug APK as a compile/package regression check.
7. Upload test logs/debug artifact only when repository retention policy permits.

Use read-only repository permissions where possible. Pin third-party actions to reviewed versions or commit SHAs according to the organization's supply-chain policy.

## Release signing strategy

Preferred initial approach:

- Keep production release signing manual and local.
- Use the documented final release checklist.
- Upload through Play Console only after human review.

If signed CI releases are approved later:

- Store the keystore and passwords only in protected CI secret storage.
- Restrict the workflow to protected tags/environments and authorized approvers.
- Materialize signing files only in the ephemeral runner workspace.
- Prevent secret echoing and archive no keystore-bearing workspace.
- Delete temporary signing material even after a failed job.
- Verify the signer fingerprint and artifact hash before upload.
- Separate build authorization from Play promotion authorization.

## Failure policy

- Format, analyze, test, or debug-build failure blocks merge.
- Release signing/build failure blocks release but does not justify using a debug/test key.
- Flaky tests must be diagnosed; rerunning until green is not an acceptance policy.
- Dependency or Flutter-version changes require explicit review.

## Future workflow approval checklist

- [ ] User/repository owner explicitly approves adding `.github/workflows/...`.
- [ ] Flutter version and action versions are pinned.
- [ ] Branch protection requires the quality checks.
- [ ] Workflow permissions are least-privilege.
- [ ] Forked pull requests cannot access signing secrets.
- [ ] Signed release workflow has protected-environment approval.
- [ ] Secret rotation and incident response are documented.

No GitHub Actions workflow or CI signing secret is added by this sprint.

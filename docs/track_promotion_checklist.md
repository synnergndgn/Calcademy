# Track promotion checklist

Calcademy runs more than one line of work at once: an offline build is on
closed testing, and a Supabase-connected build with the Gemini assistant is on
internal testing. Those two must never be confused for each other.

This checklist exists because the dangerous mistake is not a bug — it is
promoting a build that works perfectly in internal testing and happens to be
wired to the staging database.

## The rule that matters most

**A build compiled with staging `--dart-define` values must never leave the
internal test track.**

There is nothing in the artifact that announces which project it points at.
A staging-connected AAB installs, runs, signs in, and passes a smoke test
exactly like a production one. The only difference is that its users land in a
database that contains hand-written entitlements, throwaway accounts, and test
quota rows.

Promotion is not a rebuild-free operation. Promoting the internal artifact is
always wrong; the production release is a **new build** with production config.

## Before promoting past internal testing

Work top to bottom. Each item blocks the ones under it.

### 1. Backend

- [ ] A **production** Supabase project exists, separate from
      `Calcademy Staging`.
- [ ] Migrations applied to it: `npx supabase@2.111.0 db push` against the
      production ref.
- [ ] Edge Functions deployed to it: `delete-account`,
      `validate-play-purchase`, and `ai-assist` if the release includes the
      assistant.
- [ ] `GEMINI_API_KEY` set on the **production** project, on a paid tier — the
      free tier permits Google to use submitted content for product
      improvement, which contradicts what the privacy policy tells users.
- [ ] Anonymous access verified denied on every table and function, the same
      probes recorded in `supabase_entitlement_schema.md`.
- [ ] Authenticated RLS verified with two production-project accounts using the
      role-impersonation snippet in the same document.

### 2. Build

- [ ] Built from the intended branch, not from whatever is checked out.
- [ ] `--dart-define=SUPABASE_URL=` points at the **production** ref. Read it
      back from the actual command you ran, not from memory.
- [ ] `--dart-define=SUPABASE_ANON_KEY=` is the production publishable key.
- [ ] Version code is higher than every track's current release.
- [ ] The artifact was installed on a real device and signed in, and the
      account created appears in the **production** project's Auth users — this
      is the only positive proof the build points where you think it does.

### 3. Declarations

- [ ] Data Safety updated **before** the release goes live, not after. If the
      release transmits anything the current declaration does not cover, the
      declaration is wrong the moment the release is live.
- [ ] For any release including the Gemini assistant: the "Other
      user-generated content" row is declared, marked optional and
      user-initiated. Draft in `data_safety_draft.md`.
- [ ] Privacy policy republished if its text changed. It publishes from `main`
      + `/docs`, so the policy goes live only when that lands on `main` — a
      policy change on a feature branch is not published.
- [ ] Ads declaration and content rating still match the build.

### 4. After

- [ ] Confirm the intended track received the intended version code.
- [ ] Confirm the earlier track was not silently upgraded past what you meant
      to ship.

## Release strategy note

The current plan is to publish the offline app first, let it earn, and hold the
account-and-assistant line back. That makes the separation above more important
rather than less, because the two lines will sit side by side for months.

Two consequences worth stating plainly:

- **A production build without Supabase config is a supported configuration.**
  Every account, billing, entitlement, and remote-assistant path fails closed
  and the app stays fully usable offline. That is by design and is covered by
  tests. Shipping the offline line from the same codebase is safe.
- **`main` moving ahead does not release anything.** Merging the assistant to
  `main` does not put it in front of users; only a build and a track promotion
  does. Merge decisions and release decisions are separate.

## Rollback

Play does not un-publish a release. If a wrongly configured build reaches a
track, the fix is to publish a corrected higher version code immediately and to
treat any data written to the wrong project as real: the accounts in it belong
to real people, whatever track they came from.

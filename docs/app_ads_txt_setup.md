# app-ads.txt Setup (Google AdMob)

> **Branch-scoped draft (`feature/admob-retry`, 1.0.0+8).** The stable `main`
> branch is 1.0.0+7 and ads-free. See `docs/monetization_strategy.md`.

`app-ads.txt` lets Google verify that Calcademy's ad inventory is authorized to
be sold through the publisher account. It is **not** shipped inside the app — it
is a plain-text file hosted at the root of the developer website declared in the
Play Console listing. Until it is published and crawled, AdMob may limit or
disable demand for the app.

## Prerequisites

- A **developer website domain** entered in the Play Console store listing. AdMob
  reads that exact domain to look for `app-ads.txt`.
- The **authorization line** shown in the AdMob console under
  *Apps → Calcademy → app-ads.txt*. Only Google can generate the correct
  publisher id and relationship for the account.

## Steps

1. In the AdMob console, open the app's **app-ads.txt** instructions and copy the
   exact line(s) Google provides. It looks like:

   ```
   google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0
   ```

   The `pub-XXXXXXXXXXXXXXXX` value is the AdMob **publisher id** (note: this is
   the `pub-...` form of the app id prefix `ca-app-pub-5164539069315402`, i.e.
   `pub-5164539069315402` — but always copy the console's exact line rather than
   hand-constructing it).

2. Confirm the developer website domain in Play Console matches the domain you
   will host the file on.

3. Publish the file so it is reachable at:

   ```
   https://<developer-domain>/app-ads.txt
   ```

   It must be at the **root**, served over HTTPS, and returned as
   `text/plain` with HTTP 200.

### Where it goes

The developer domain is **`gundev.dev`**, so the file must resolve at:

```
https://gundev.dev/app-ads.txt
```

with exactly this content:

```
google.com, pub-5164539069315402, DIRECT, f08c47fec0942fa0
```

The same string is in `AdConfig.appAdsTxtLine`, and a test asserts the publisher
id is the same account as the app id this build ships. That check exists because
a well-formed id from the *wrong* account is the failure that looks correct: the
file publishes, the crawler accepts it, and it authorises someone else's
inventory while this app stays unauthorised.

The Play Console **developer website** field must be `https://gundev.dev` — the
crawler derives the file location from it, so a mismatch means the file is never
found. Note that a project subpath (for example
`https://<user>.github.io/Calcademy/`) can never host a root `app-ads.txt`,
which is why the custom domain matters here.

4. In AdMob, click **Check for updates** and wait for Google to crawl and verify
   (can take up to ~24 hours, sometimes longer).

### Verification cannot happen before the app is public

AdMob finds the file by reading the **developer website** field from the app's
public Play Store listing and crawling that domain. An app that exists only on
a closed test track has no public listing, so there is nothing for the crawler
to start from — and no amount of re-clicking **Check for updates** will change
that.

Confirmed 2026-08-06 while Calcademy was on closed testing. This is expected,
not a misconfiguration, and it blocks nothing: the file is live and correct and
simply waits. Verification becomes possible the day the app is published to
production.

The consequence of being unverified is lower eCPM, because some buyers will not
bid on unauthorised inventory — which only matters once there is real traffic,
so the timing works out.

## Publisher id in code

`AdConfig.appAdsTxtPublisherId` is intentionally `null` — the real publisher line
must come from the AdMob console and is **not** fabricated in source. Fill it in
(and/or commit the hosted `app-ads.txt`) only after copying the exact value from
the console.

> ⚠️ Do not invent or guess the `pub-…` value or the full authorization line.
> Publishing a wrong or fabricated line can misauthorize inventory. This setup is
> **not final** until the real line from the AdMob console is published at the
> developer domain root and verified as found by AdMob.

## Status checklist

- [ ] Developer website domain set in Play Console.
- [ ] Exact `app-ads.txt` line copied from the AdMob console.
- [ ] File published at `https://<developer-domain>/app-ads.txt` (root, HTTPS, `text/plain`).
- [ ] AdMob reports the file as **found/verified**.
- [ ] (Optional) `AdConfig.appAdsTxtPublisherId` recorded once known.

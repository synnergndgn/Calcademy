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

### Hosting on GitHub Pages

If the developer site is served from GitHub Pages (as the privacy policy is, at
`https://synnergndgn.github.io/Calcademy/…`), note that `app-ads.txt` must sit at
the **domain root**, not under a project subpath:

- A **user/organization Pages site** (`https://<user>.github.io/`) serves the
  repository `<user>.github.io` at the root — place `app-ads.txt` in that
  repository's root so it resolves at `https://<user>.github.io/app-ads.txt`.
- A **project Pages site** (`https://<user>.github.io/Calcademy/`) is a subpath
  and cannot host a root `app-ads.txt`; the developer-website domain in Play must
  be the root domain that actually serves the file.
- If a custom domain is used, add the file to whatever hosts that domain's root.

4. In AdMob, click **Check for updates** and wait for Google to crawl and verify
   (can take up to ~24 hours, sometimes longer).

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

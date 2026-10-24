---
name: update-website
description: >-
  Add or update a +Prayer list on the Framer website CMS (the Lists and List
  Socials collections) from publishing/lists.json, merge it to main, and publish
  the site. Runs automatically at the end of publish-list and after
  harvest-comments confirms a TikTok post. Use when the user says "update the
  website for list N", "add list N to the site", "sync list N to Framer", or
  "run update-website N".
---

# Update the website for a list

Writes list **N** into the Framer CMS so it appears on the site's `/lists` pages:
one **Lists** entry (number, souls, count, date, wax colour) and one **List
Socials** entry per platform with that post's link. Reads everything from
`publishing/lists.json` — no Zernio calls.

**Update, merge and publish in one go — no review stop.** Eric asked for the
whole thing to run unattended (2026-10-19). The site's list pages
sort by the Date field, so creation order doesn't matter.

## Inputs
- **N** — one or more list numbers.

## Steps
1. **Links must already be in `lists.json`.** Each platform's link is
   `lists["N"].published.platforms[<platform>].platform_post_url`. `publish-list`'s
   wake cycle records them; a platform without one is simply left off the site
   for now. A TikTok gets its link only once confirmed (see `publish-list`, "A
   TikTok `success` is not proof of publication") — so on publish day TikTok is
   normally missing, and `harvest-comments` fills it in the next day.
2. **Connect to Framer** (the CLI needs network access, so run it unsandboxed):
   ```
   npx @framer/agent@latest session new "https://framer.com/projects/Prayer--n77pREAxtAWSyaVQ3vqv-7J2u6"
   ```
   It prints a session id; reuse it for every call in this conversation. If the
   `framer` skill hasn't been set up on this machine, run
   `npx @framer/agent@latest setup` once first. A first-time connect opens a
   browser for authorisation.
3. **Build the payload:**
   ```
   python3 scripts/publishing/framer_payload.py N --out <scratchpad>/framer_payload.json
   ```
   It prints one line per list, including any platform with no link yet.
4. **Write to Framer:**
   ```
   { echo "const PAYLOAD = '<scratchpad>/framer_payload.json';"; cat scripts/publishing/framer_upsert_lists.js; } \
     | npx @framer/agent@latest exec -s <session>
   ```
   It is idempotent — matches the list by number and each link by platform,
   creates what's missing, updates what changed, deletes nothing. Re-running is
   always safe.
5. **Merge.** Framer puts the first edit of a session on a new branch and prints
   `[FRAMER_BRANCH_CHANGE] title=… id=… url=…`. Merge it straight into main:
   ```
   npx @framer/agent@latest exec -s <session> -e 'await framer.agent.mergeBranch("main"); console.log(JSON.stringify(await framer.agent.getActiveBranch()))'
   ```
   The active branch must read `main` afterwards. If the step changed nothing (no
   branch was created), there is nothing to merge — skip to publishing anyway only if
   main has unpublished changes, otherwise stop here.
6. **Publish** from main, in two calls:
   `framer.agent.publish({action:"preview"})` → check it reports no blocking errors
   and take its `confirmationHash` → `framer.agent.publish({action:"confirm_publish",
   confirmationHash})`. If preview reports blocking errors, do NOT publish: report
   them and leave the change merged on main for Eric. If the site has staging
   enabled and the confirm lands on staging only, deploy that version with
   `{action:"deploy_to_production", version:<id>}`.
7. **Report** in one line: what was created or changed, any platform with no link
   yet, and that the site is published (or why it isn't).

## How the fields are filled
| CMS field | source |
|-----------|--------|
| Slug | N |
| Souls count | `soul_count` |
| Intentions count | `intention_count`, only when > 0 |
| Count | souls + intentions |
| Date | the list's `date`, midnight UTC |
| Wax Color | weekday of `date`, per the rotation in `ritual/CLAUDE.md` (Friday's Antique Brass is "Orange" in the CMS) |
| List Socials → Deep Link | `platform_post_url`; YouTube is rewritten to `/shorts/<id>` and Facebook to `/reel/<id>`, matching the existing entries |

## Gotchas
- **The wax colour is derived, not recorded.** A list published after midnight UTC
  but on the previous US evening can get the wrong date: List 24 went out 05:02Z on
  2026-07-27 and was recorded as 7/27 (Monday's Blue) until it was corrected to
  2026-07-26 (Sunday's Gold) on 2026-10-19. Since then `publish-list` records the
  US Mountain date, which prevents this. If a list's date is ever off, fix `date`
  in `lists.json` and re-run — the step updates the existing entry.
- The collection and platform ids are hard-coded at the top of
  `framer_upsert_lists.js`. If the CMS is restructured in Framer, re-read the
  collections (`framer.agent.getNodesOfTypes({types:["CollectionNode"]})`) and
  update them there.

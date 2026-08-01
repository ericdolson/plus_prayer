---
name: finalize-comments
description: >-
  After a +Prayer list is live, close out the previous list's posts and add the
  mechanic comment to the new list's posts via the Zernio MCP, logging comment
  ids to lists.json. Use when the user says "finalize comments for list N",
  "finalize list N comments", "close out and comment list N", "do the comments
  for list N", or "run finalize-comments N".
---

# Finalize comments for a list

Runs as soon as **any** of list N's posts is live — usually invoked automatically by
`publish-list`'s wake cycle. In one idempotent pass, for each platform that is live:

- **Half A — closes out list N‑1**: deletes the logged mechanic comment on
  YouTube/Facebook/Instagram and posts the "List N‑1 is retired…" notice.
- **Half B — seeds list N**: posts the mechanic comment on
  YouTube/Facebook/Instagram and logs each comment id.

Threads and TikTok can't take these via the API — the skill prints their exact
copy as a manual checklist instead (see Gotchas).

Zernio **cannot pin** — so every comment this skill posts is left for the user to
pin (or re-pin) by hand. That's expected, not a failure.

## Read these for exact copy (do not paraphrase)
- `publishing/CLAUDE.md` — brand voice, the close-out copy per platform, and the
  platform gotchas.
- This file's **Comment copy (locked)** section below.

## Inputs
- **N** — the list number that was just published (required). The previous list
  is **N‑1**.

## Per-platform gate — finalize each platform as IT goes live
Do NOT wait for all three. For each of youtube/facebook/instagram, call `posts_get`
on `lists["N"].published.platforms[platform].post_id`:

- `status: published` → do **both halves for that platform** in this pass.
- anything else (usually `publishing` — Instagram is the usual laggard) → skip that
  platform silently and leave it for a later pass.

Each platform is gated on its **own** list-N post, never on another's. The retired
copy says "find the newest list on our channel / Page / profile", so posting it on
YouTube while list N isn't live on YouTube yet points people at nothing.

A partial pass is normal, not a failure. The idempotency rules in Gotchas mean a
later pass picks up exactly what was skipped, and re-running is always safe.
(List N‑1 is already long-live, so Half A never waits on anything of its own.)

## Account IDs
| platform  | accountId |
|-----------|-----------|
| youtube   | 69da4e587dea335c2bd8690b |
| facebook  | 69e67da07dea335c2b16d9ed |
| instagram | 69da50cb7dea335c2bd874ab |
| threads   | 69e67b8f7dea335c2b16ce33 |
| tiktok    | 69da47b17dea335c2bd846cf |

## Steps

### Half A — close out list N‑1
Read `lists["N-1"]`. For each of **youtube, facebook, instagram that passed the
per-platform gate above**:
1. Look at `lists["N-1"].published.comments[platform]`. If `closeout` is already
   `"done"`, skip this platform (idempotent re-run).
2. If a `mechanic_id` is logged, **delete** it:
   `comments_delete_inbox_comment` with `post_id` =
   `lists["N-1"].published.platforms[platform].post_id`, `account_id` (table
   above), `comment_id` = that `mechanic_id`. If no `mechanic_id` is logged
   (a legacy list from before this skill), skip the delete and note it — do NOT
   go hunting for the comment.
3. **Post** the retired notice with `comments_reply_to_inbox_post` (`post_id` =
   that platform's `post_id`, `account_id`, `message` = the platform's retired
   copy below). Capture the returned `commentId`.
4. Write back into `lists["N-1"].published.comments[platform]`: `retired_id` =
   the returned id, `closeout` = `"done"`.

Threads and TikTok: do **not** call the API (both fail — see Gotchas). Add them to
the manual checklist output.

### Half B — seed list N
Read `lists["N"]`. For each of **youtube, facebook, instagram that passed the
per-platform gate above**:
1. If `lists["N"].published.comments[platform].mechanic_id` is already present,
   skip (idempotent).
2. **Post** the mechanic comment with `comments_reply_to_inbox_post` (`post_id` =
   `lists["N"].published.platforms[platform].post_id`, `account_id`, `message` =
   the mechanic copy below). Capture the returned `commentId`.
3. Write `lists["N"].published.comments[platform]` = `{ "mechanic_id": <id>,
   "mechanic_at": <now UTC ISO>, "closeout": "pending", "retired_id": null }`.

Threads and TikTok: nothing (Threads' CTA is in the caption; TikTok directs to
YT/IG in its caption).

### Finish
Commit `lists.json`, then output:

1. One line naming what this pass did, e.g.
   `Finalized: youtube, facebook · Still publishing: instagram` — so the caller
   knows whether another pass is needed.
2. The manual checklist (below), unchanged and in full. It is short, every item on
   it is still owed, and a later pass reprinting it is harmless.

## Comment copy (locked)

**Mechanic (YouTube / Facebook / Instagram — Half B):**
> Comment 🙏 to pray for this list. Your name goes on the next.

**Retired notice (Half A + the manual platforms), fill in {N-1}:**
- YouTube:   `List {N-1} is retired — but a 🙏 here still counts. Find the newest list on our channel.`
- Facebook:  `List {N-1} is retired — but a 🙏 here still counts. Find the newest list on our Page.`
- Instagram: `List {N-1} is retired — but a 🙏 here still counts. Find the newest list on our profile.`
- Threads:   `List {N-1} is retired — but a 🙏 here still counts. Find the newest list on our profile.`
- **TikTok (different — a 🙏 on TikTok does NOT count; redirect only):**
  `This list is retired. Head to our YouTube or Instagram for the current one — leave a 🙏 there to join the next.`

## `lists.json` data model
Each published list gains a `comments` block inside `published`, one entry per
automatable platform:
```json
"published": {
  "...": "...",
  "platforms": { "youtube": { "post_id": "...", "status": "..." }, "...": "..." },
  "comments": {
    "youtube":   { "mechanic_id": "Ugx…", "mechanic_at": "2026-07-21T14:26:00Z", "closeout": "done", "retired_id": "Ugy…" },
    "facebook":  { "mechanic_id": "…_…",  "mechanic_at": "…",                    "closeout": "pending", "retired_id": null },
    "instagram": { "mechanic_id": "18…",  "mechanic_at": "…",                    "closeout": "pending", "retired_id": null }
  }
}
```
- `mechanic_id` — the platform comment id returned when Half B posts the CTA on
  THIS list. Half A of the NEXT run reads it to delete exactly that comment
  (never touching other comments left on the post).
- `closeout` — `pending` until this list is retired, then `done`.
- Only youtube/facebook/instagram appear here; Threads/TikTok are manual.

## Manual checklist (output every run)
Fill in [N], [N-1]. Every comment is complete copy, ready to paste.

```
Finalize comments — List [N] live, List [N-1] retired

── Pin the new mechanic comments (List [N] posts) ──
- [ ] YouTube   — pin the posted comment (watch page → ⋮ → Pin)
- [ ] Facebook  — pin the posted comment (⋯ → Pin, or in app)
- [ ] Instagram — pin the posted comment (app: long-press → pin)

── Re-pin the retired notices (List [N-1] posts) ──
- [ ] YouTube   — pin the new retired comment (old mechanic was deleted)
- [ ] Facebook  — pin the new retired comment
- [ ] Instagram — pin the new retired comment

── Manual close-out (API can't post these) ──
- [ ] Threads   — REPLY to the List [N-1] post, then pin (⋮ → Pin reply):
      List [N-1] is retired — but a 🙏 here still counts. Find the newest list on our profile.
- [ ] TikTok    — comment on the List [N-1] post (pin optional, app-only):
      This list is retired. Head to our YouTube or Instagram for the current one — leave a 🙏 there to join the next.
```

## Gotchas
- **Idempotent by design.** Half B skips any platform whose `mechanic_id` is
  already logged; Half A skips any platform already `closeout: done`. So a partial
  run (Instagram still publishing, a transient error) is safe to just re-run.
- **YouTube can't hide or edit via Zernio** (`canHide: false`; `comments_edit…`
  is Reddit-only) — that's why close-out DELETES the old mechanic (our own
  boilerplate, whose text is a fixed constant) rather than editing it.
- **Threads: no top-level comments via the API.** `comments_reply_to_inbox_post`
  on a Threads post (no `comment_id`) returns `[400] Platform error: 24`. There's
  also no mechanic comment on Threads to delete (its CTA lives in the caption). So
  Threads close-out is manual, every time.
- **TikTok: no comment posting via the API.** Returns
  `[400] TikTok API does not support posting comments (PLATFORM_LIMITATION)`. TikTok
  close-out is manual, and uses the redirect wording (no "🙏 here still counts",
  because TikTok 🙏s aren't aggregated).
- **Pinning is never automated** — Zernio can't pin on any platform. Everything
  this skill posts must be pinned/re-pinned by hand (checklist above).
- **Deleting our own comment is safe** — `canDelete: true` on brand-owned
  comments; the deleted text is a known constant and can be re-posted verbatim if
  ever needed.

## Related
- Runs after `publish-list` (which schedules the posts and writes
  `published.platforms`). `publish-list` now invokes this skill automatically from
  its wake cycle at ~+5 min, re-running as later platforms go live — "publish and
  walk away." Invoking it by hand still works and is the recovery path if the
  session ended before the cycle finished.

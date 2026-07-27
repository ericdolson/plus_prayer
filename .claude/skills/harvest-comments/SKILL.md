---
name: harvest-comments
description: >-
  Collect 🙏 prayer comments from the +Prayer social posts (YouTube, Instagram,
  Facebook, Threads) via the Zernio MCP and assign the commenters to the next
  daily list, updating the watermark. Use when the user says "collect comments
  for list N", "harvest comments for list N", "harvest 🙏 for list N", or "gather
  names for list N".
---

# Harvest 🙏 comments for a list

Collects genuine 🙏 participants since the last watermark and records them under
list **N** in `publishing/participants.json`.

## Read this for the full rules
- `publishing/CLAUDE.md` — "Comment aggregation pipeline" section.

## Steps
1. Read `publishing/participants.json`: `last_aggregated_at` (watermark),
   `brand_accounts`, `pending`, and `post_counts` (a map of
   `"<platform>:<postId>"` → the commentCount last seen for that post; absent or
   empty on the first run after this optimization landed).
2. `comments_list_inbox_comments` (min_comments >= 1), **paginating through every
   page**, to enumerate all commented posts across YouTube / Instagram / Facebook /
   Threads (TikTok is not queryable) with each post's **current `commentCount`**.
   Always do this enumeration in full — it's the cheap part (50 posts/page, a couple
   of calls) and it's how we detect which posts changed. Do NOT deep-fetch yet.
3. Decide which posts to deep-fetch with `comments_get_inbox_post_comments`
   (`post_id` + `account_id`). Deep-fetch a post if **any** of these is true:
   - it belongs to one of the **two most-recently-published lists** — the current
     live list (`N-1`) and the just-retired list (`N-2`), identified by the
     `List <number>` token in the post `content`. This is the always-check floor:
     real 🙏s land within a day or two, on the current or just-retired post, and the
     brand's "List N-1 is retired — but a 🙏 here still counts" comment lands there
     too (it's brand `isOwner:true`, so the step-4 filter drops it — but only if the
     post was actually fetched); OR
   - it is **new** — no entry for `"<platform>:<postId>"` in `post_counts`; OR
   - its current `commentCount` **differs** (higher OR lower) from the stored
     `post_counts` value.

   **Skip** every other post: an unchanged count that isn't in the floor means no
   new comment arrived (a real 🙏 would have bumped the count). This is what keeps
   the harvest from growing with the number of lists.
4. Among the comments on the deep-fetched posts, keep one only if ALL of these hold:
   - the message contains 🙏 (U+1F64F), allowing a trailing skin-tone modifier
     (🙏🏻 🙏🏼 🙏🏽 🙏🏾 🙏🏿);
   - `createdTime` > watermark (filter by COMMENT time, not post time — a 🙏 on an
     old post today still counts);
   - it is NOT from a brand account: `isOwner` is false AND `from.id` is not in
     `brand_accounts`. (The pinned CTA, the close-out copy, and any 🙏 from an owner
     account are all brand — exclude them.)
   - dedupe by `from.id`, per platform (IDs aren't comparable across platforms).
5. Append survivors to `pending["N"]` (create the key if absent), each as
   `{platform, handle, id, at, comment_url}`.
6. Update state and commit `participants.json`:
   - Set `post_counts["<platform>:<postId>"]` = the current `commentCount` for
     **every post the enumeration returned in step 2** — not just the ones you
     deep-fetched — so the next run's delta compares against the latest counts.
     (Skipping this on unfetched posts would make brand-only count changes re-trigger
     a fetch forever.)
   - Advance `last_aggregated_at` to the harvest time (now, UTC).
   - Write and commit.
7. Report the count of new participants (often 0 so far) and who they are, plus how
   many posts were deep-fetched vs skipped (so the speedup is visible).

## Notes
- Current `brand_accounts`: youtube [`UCwVcRTUGUg_C3eQbA93wk3g`,
  `UCD_ExEbqKc3cM7xEy3-6uDA`], instagram [`17841441277607712`], facebook
  [`1033072079891934`]. Add any new brand/secondary account you catch posting the CTA.
- When list N is actually assembled/printed, clear `pending["N"]`.
- TikTok comments aren't queryable. Threads comment retrieval does work (confirmed
  2026-07-11) — some Threads comment `from` objects omit `id` entirely, so lean on
  `isOwner` for the brand-comment filter there rather than assuming `from.id` is
  always present.

## The count-delta optimization (why the deep-fetch is bounded)
Deep-fetching every post every harvest grew with the list count and always returned
brand-only comments (every observed real 🙏 has landed within ~1–2 days on the
current or just-retired post). So the harvest now enumerates all posts cheaply for
their `commentCount`, but only deep-fetches posts that (a) are the two most-recent
lists, (b) are new, or (c) changed count since last run. `post_counts` in
`participants.json` is the per-post `commentCount` history that makes (c) possible.

- **`post_counts` shape:** `{ "<platform>:<postId>": <int commentCount>, ... }` keyed
  by the platform-native post id from the enumeration (e.g. `"youtube:9AnJJhSlnCE"`,
  `"facebook:1033072079891934_122126039684983291"`), NOT the Zernio `_id`.
- **First run after this landed:** `post_counts` is empty, so every post counts as
  "new" and is deep-fetched once — this seeds the map. Steady state after that is a
  couple of enumeration calls plus a deep-fetch only for the recent lists and
  anything that actually changed.
- **Accepted blind spot:** a new participant 🙏 on an *old* post (outside the
  two-list floor) arriving in the same interval as a comment deletion on that same
  post can net to no count change and be missed. Vanishingly rare at this volume and
  with a curated list; the floor always covers the posts where activity actually
  happens. If the mechanic ever moves to current-list-only (the app's model), this
  whole per-post sweep collapses to just the floor.
- Counts can legitimately move from brand activity (finalize-comments deletes the old
  mechanic and posts the retirement notice on the just-retired post, and seeds a new
  mechanic on the current post). Those posts are in the floor, so they're fetched and
  filtered regardless — no participant is missed by that churn.

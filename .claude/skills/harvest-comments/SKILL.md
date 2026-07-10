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
   `brand_accounts`, `pending`.
2. `comments_list_inbox_comments` (min_comments >= 1) → commented posts across
   YouTube / Instagram / Facebook / Threads (TikTok is not queryable).
3. For each post that could have comments after the watermark (its count grew, or
   it's a recent post), call `comments_get_inbox_post_comments` (post_id + account_id).
4. Keep a comment only if ALL of these hold:
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
6. Advance `last_aggregated_at` to the harvest time (now, UTC). Write and commit
   `participants.json`.
7. Report the count of new participants (often 0 so far) and who they are.

## Notes
- Current `brand_accounts`: youtube [`UCwVcRTUGUg_C3eQbA93wk3g`,
  `UCD_ExEbqKc3cM7xEy3-6uDA`], instagram [`17841441277607712`], facebook
  [`1033072079891934`]. Add any new brand/secondary account you catch posting the CTA.
- When list N is actually assembled/printed, clear `pending["N"]`.
- Threads/TikTok comment retrieval is unreliable/blocked; effective sources are
  YouTube, Instagram, Facebook.

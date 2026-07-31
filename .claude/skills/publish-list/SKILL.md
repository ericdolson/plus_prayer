---
name: publish-list
description: >-
  Publish or schedule a +Prayer daily prayer list across all five social
  platforms (YouTube, Facebook, Instagram, Threads, TikTok) via the Zernio MCP,
  then record results and output the post-publish checklist. Use when the user
  says "publish list N", "post list N", "schedule list N", "publish list N at
  9am", "publish list N in 5 minutes", or "publish list N now".
---

# Publish a +Prayer list

Publishes list **N** to all five platforms with the Zernio MCP, records the result
in `publishing/lists.json`, and outputs the canonical post-publish checklist.

## Read these for exact copy (do not paraphrase)
- `publishing/CLAUDE.md` — brand voice, count-line rules, the canonical post-publish
  checklist, and all the platform gotchas.
- `publishing/captions/list-caption-template.md` — the locked caption structure.

## Inputs
- **N** — list number (required).
- **Timing** — default is **schedule ~2 minutes out** (any future instant avoids the
  Threads 409; 2 min also keeps YouTube from firing well ahead of the others — see
  the YouTube gotcha):
  - no time given / "in a couple minutes" → `scheduled_for` = now + 2 min.
  - "at [time] [tz]" → convert to the exact UTC instant, DST-aware (9am Mountain in
    July = 15:00Z; in January = 16:00Z).
  - "now" / "immediately" → `publish_now: true` (see Threads gotcha).

  **The 2-minute lead has no slack — protect it:**
  - Compute the target **in step 4, right before the first create call** — NOT at the
    top of the run. Building captions burns 30–60s of a 5-min budget and all of a
    2-min one.
  - Re-check the clock before each create. If the target is less than ~60s away (a
    retry, an `accounts_list` re-resolution, a permission prompt), push it out one
    minute and use the new target for the remaining platforms. A `scheduled_for` in
    the past falls back to immediate publishing — the exact Threads-409 path the
    default exists to avoid.

## Steps
1. Read `publishing/lists.json`; get `lists["N"]`. If `published` is present and
   non-empty, STOP and report it's already published.
2. Count line: `List N — {soul_count} souls[ & {intention_count} intentions]` —
   include each part only when > 0 (almost always souls-only).
3. Build captions from the template:
   - Intro paragraph (identical every list); source note from `notes` if present
     (append to the count line for non-YouTube; standalone line in YouTube's
     description); ritual + CTA per platform.
   - **YouTube:** count line is the video TITLE (`List N — {count} souls`, no
     "— +Prayer") and is left OUT of the description.
   - **Everyone else:** count line is the FIRST line of the description.
   - Give Threads a slightly reworded caption (avoids a dedup 409 vs the IG text).
4. Create each post with **`posts_create_post`** (one call per platform), using
   `scheduled_for` = target UTC ISO (or `publish_now: true`), and
   `media_items: [{"type":"video","url": <video_url>, "thumbnail": <thumbnail_url>}]`.
   Account IDs (re-resolve with `accounts_list` if a call errors on the account):

   | platform  | accountId |
   |-----------|-----------|
   | youtube   | 69da4e587dea335c2bd8690b |
   | facebook  | 69e67da07dea335c2b16d9ed |
   | instagram | 69da50cb7dea335c2bd874ab |
   | threads   | 69e67b8f7dea335c2b16ce33 |
   | tiktok    | 69da47b17dea335c2bd846cf |

   Per-platform `platforms` entry:
   - youtube: `platformSpecificData:{title:"List N — {count} souls", visibility:"public"}` (cover rides on the media item's `thumbnail`).
   - instagram: `platformSpecificData:{contentType:"reels", instagramThumbnail:<thumbnail_url>}`.
   - tiktok: **no cover** — do NOT pass `tiktok_settings.video_cover_image_url`.
   - facebook / threads: `{platform, accountId}` only.
5. Verify each create response: `scheduledFor` equals the target and `status` is
   `scheduled` (or `published` for immediate).
6. Write `lists["N"].published`: `scheduled_for` (or `published_at`), `date`
   (scheduled/publish day YYYY-MM-DD), and `platforms` with each Zernio `_id` as
   `post_id` + status. Commit `lists.json`.
7. Output the canonical 5-section post-publish checklist from `publishing/CLAUDE.md`,
   filled in for N and N-1, with complete copy-paste comment text per platform.

## Gotchas (verified over Lists 1–7)
- **Scheduling:** always `posts_create_post` + `scheduled_for` (stored verbatim, and
  honored at fire time by FB/IG/Threads/TikTok — but NOT by YouTube, see below).
  NEVER `posts_create` + `schedule_minutes` — it has a timezone bug that fires posts
  ~hours early (shipped List 1 ~3h early).
- **YouTube ignores `scheduled_for`** (measured across Lists 21–29): it publishes
  ~1–2 min after the CREATE call regardless of the target, so the whole lead time
  becomes "early." List 28 was created ~15:47 for a 15:55 target and went live at
  15:47:42 (7.3 min early); List 29 was created 22:22:26 for 22:28 and went live at
  22:24:08. The other four fire *after* the instant: FB ≈ +1 min, TikTok ≈ +1 min,
  IG ≈ +2 min, Threads ≈ +3–5 min. A short lead is what keeps all five within about a
  minute of each other; don't schedule far out expecting YouTube to wait.
- **Threads 409:** on an immediate publish Threads usually returns `[409]` but posts
  anyway a few minutes later (async). Do NOT retry — that made a duplicate on List 4.
  Wait, then check `logs_list_logs platform=threads` for a `post.published` success
  (its `response_body` has the real `{id,url}`). **Any future-dated `scheduled_for`
  avoids the 409 entirely** — it routes through the scheduler instead of the immediate
  path. The queue polls at sub-minute granularity (FB lands +0.8–1.4 min every list),
  so 2 min clears it comfortably; the lead exists for create-call slack, not for the
  scheduler.
- **TikTok cover:** never set via Zernio (ffmpeg stitch times out and burns TikTok's
  daily API quota). **YouTube thumbnail:** the video posts as a Short, so Zernio can't
  set it — list it as a manual Studio step in the checklist. **Instagram cover:**
  works via `instagramThumbnail`.
- **Site URLs:** after go-live, `posts_get_post` returns each `platformPostUrl` and the
  raw `platformPostId` if the user wants links for the website.

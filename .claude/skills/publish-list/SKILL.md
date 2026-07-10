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
- **Timing** — default is **schedule ~5 minutes out** (this avoids the Threads 409):
  - no time given / "in 5 minutes" → `scheduled_for` = now + 5 min.
  - "at [time] [tz]" → convert to the exact UTC instant, DST-aware (9am Mountain in
    July = 15:00Z; in January = 16:00Z).
  - "now" / "immediately" → `publish_now: true` (see Threads gotcha).

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
- **Scheduling:** always `posts_create_post` + `scheduled_for` (honored verbatim).
  NEVER `posts_create` + `schedule_minutes` — it has a timezone bug that fires posts
  ~hours early (shipped List 1 ~3h early).
- **Threads 409:** on an immediate publish Threads usually returns `[409]` but posts
  anyway a few minutes later (async). Do NOT retry — that made a duplicate on List 4.
  Wait, then check `logs_list_logs platform=threads` for a `post.published` success
  (its `response_body` has the real `{id,url}`). **Scheduling ~5 min out avoids the
  409 entirely — hence the default.**
- **TikTok cover:** never set via Zernio (ffmpeg stitch times out and burns TikTok's
  daily API quota). **YouTube thumbnail:** the video posts as a Short, so Zernio can't
  set it — list it as a manual Studio step in the checklist. **Instagram cover:**
  works via `instagramThumbnail`.
- **Site URLs:** after go-live, `posts_get_post` returns each `platformPostUrl` and the
  raw `platformPostId` if the user wants links for the website.

---
name: publish-list
description: >-
  Publish or schedule a +Prayer daily prayer list across all five social
  platforms (YouTube, Facebook, Instagram, Threads, TikTok) via the Zernio MCP,
  record the result, then auto-run finalize-comments on a timer once the posts
  go live. Use when the user says "publish list N", "post list N", "schedule
  list N", "publish list N at 9am", "publish list N in 5 minutes", or "publish
  list N now".
---

# Publish a +Prayer list

Publishes list **N** to all five platforms with the Zernio MCP, records the result
in `publishing/lists.json`, and then finalizes the comments by itself — a background
timer wakes Claude a few minutes later to run `finalize-comments` for list N.

## Read these for exact copy (do not paraphrase)
- `publishing/CLAUDE.md` — brand voice, count-line rules, and all the platform
  gotchas.
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
7. Arm the auto-finalize timer, then STOP:
   - Launch `sleep 300` with Bash `run_in_background: true`. It is a bare timer —
     do NOT try to check post status from the shell (Zernio is MCP-only, there is no
     API key in the environment).
   - Tell Eric in one line: all five scheduled for <time>, finalize-comments will
     run itself at ~+5 min, and the YouTube Short thumbnail still needs a manual
     Studio upload (the only manual step publishing owes).
   - End the turn. Do NOT print a post-publish checklist — `finalize-comments`
     produces the only list of things left to do by hand.

## Auto-finalize wake cycle

The background timer's exit re-invokes you. On each wake, for list N:

1. **Sweep all five** — `posts_get` every `post_id` in `lists["N"].published.platforms`,
   not just the three that take comments. Threads and TikTok get no comment work, but
   they fail like anything else and nothing else in the pipeline looks at them.
   Classify each: `published` · in-flight (`scheduled`/`pending`/`publishing`) ·
   `failed`. **TikTok reading `published` is provisional** — it is only confirmed once
   a numeric `platformPostId` shows up in analytics (see "A TikTok `success` is not
   proof of publication"). Treat an unconfirmed TikTok as in-flight, not done.
2. **Resolve every `failed` before moving on** (see "Handling a failed platform"
   below) — pull the error, write it into `lists.json`, and carry it into the report.
3. Invoke the `finalize-comments` skill with N. It finalizes every platform that is
   `published` and silently skips the rest — partial passes are safe and expected.
4. Stop when the three comment platforms are finalized **and** every platform is
   either `published` or a failure whose one retry has been spent. A failure with a
   retry still pending is NOT a stopping state — the retry timer runs on its own and
   re-invokes you; report the interim status, then finish the retry when it wakes.
   Otherwise arm the next timer from the schedule and repeat. Report what landed on
   all five — never report "all five scheduled" as if it were "all five live."

| wake | timer to arm | lands at    |
|------|--------------|-------------|
| 1    | `sleep 300`  | ~+5 min     |
| 2    | `sleep 180`  | ~+8 min     |
| 3    | `sleep 240`  | ~+12 min    |
| 4    | `sleep 480`  | ~+20 min    |

Normally wake 1 finds all three live and the cycle ends in one pass: against a
~2-minute publish lead, YouTube is live ~1.5 min after the create call, Facebook
~3 min, Instagram ~4–5 min. The later wakes exist for a slow Instagram transcode.

**After wake 4, stop.** Report any platform still not `published` with its post id
and current status. Do not arm a fifth timer — at +20 min it is a real failure, not
a lag.

If the session ends mid-cycle the pending timer dies with it. Nothing is corrupted;
`/finalize-comments N` by hand completes whatever the cycle did not.

### Handling a failed platform

A `failed` platform is auto-retried **once**, then reported either way. Surface it in
the same breath as the good news — never let it sit unmentioned behind a "published"
summary of the other four.

1. Get the reason: `logs_list_logs type=publishing platform=<platform> days=1`. The
   newest entry for that `post_id` carries `error_message`, and a successful publish
   shows as `status: success` with a `platform_post_id`. **On TikTok, read that
   `platform_post_id` before believing the `success` — see "A TikTok `success` is not
   proof of publication" below.**
2. Record it in `lists["N"].published.platforms[<platform>]`: `status: "failed"` plus
   an `error` string with the message and its UTC timestamp. Commit.
3. **Wait, then retry once** — launch the wait with Bash `run_in_background: true`
   and do the retry on the wake. **Pick the wait from the error message:**

   | `error_message` contains | wait | why |
   |--------------------------|------|-----|
   | `Daily active user quota reached.` | `sleep 900` (15 min) | measured recoveries are 13–16 min; 3 min is reliably too early |
   | anything else | `sleep 180` (3 min) | default |

   One retry per platform per list, ever. Before firing it, re-read `logs_list_logs`
   for that `post_id`: **if a `status: success` entry has appeared, do NOT retry** —
   the platform published asynchronously and a retry would duplicate it (this is
   exactly how List 4 got a duplicate on Threads). Only retry when the newest log
   entry for that post is still the failure.
4. Confirm the retry from `logs_list_logs`, never from the fact that it was queued
   (`posts_retry` returns "queued for retry" regardless of outcome). On success,
   write `status: "published"`, drop the `error`, and record `platform_post_id` plus a
   `note` naming the original failure and the retry time. Commit.
   **On TikTok, a `success` row is not enough** — resolve the real video id first
   (next section) and only then write `published`.
5. If the retry also fails, **stop** — do not retry a second time. Report the
   platform, the verbatim error, that the retry was already spent, and hand Eric the
   caption ready to paste for a manual post.

**TikTok `Daily active user quota reached.`** — the reason that error gets the 15-min
wait in step 3. Seen on List 34 (failed 15:34:02Z, retry succeeded 15:49:32Z — 15.5
min) and List 40 (failed 16:04:06Z, retry succeeded 16:17:42Z — 13.6 min). It is a
short-window ceiling on the shared app, not our own volume: List 40 hit it on a clean
first attempt with no earlier publish that day. The 15-min wait means the whole
recovery lands ~17 min after the original target — later than a normal list, but
unattended. If a third occurrence recovers well outside 13–16 min, re-measure and move
the number rather than adding a second retry.

**`posts_get` can throw on a healthy TikTok post.** After TikTok publishes, the MCP
client rejects the response with `platformPostUrl … Input should be a valid URL,
input is empty` because TikTok returns no share URL. That is client strictness, not a
publish failure — fall back to `logs_list_logs` for that platform's real status.

### A TikTok `success` is not proof of publication (List 41, 2026-08-26)

**This is the one place where `logs_list_logs` lies.** TikTok publishing is async:
Zernio hands TikTok the video and gets back a **publish handle**, then logs
`status: success` / `status_code: 200`. The handle means *TikTok accepted the upload
request* — NOT that a video exists. TikTok can still fail during its own processing,
and nothing is logged when it does.

Tell them apart by the shape of `platform_post_id`:

| value | meaning |
|-------|---------|
| `v_pub_url~v2-1.7678353046983985165` | **publish handle** — UNCONFIRMED, may never become a post |
| `7678335543020719373` (numeric) | **real video id** — genuinely live |

**So on TikTok, never write `status: "published"` off a log row whose
`platform_post_id` starts with `v_pub_url~`.** Resolve it:

```
analytics_get_analytics account_id=<tiktok accountId> platform=tiktok from_date=<today>
```

That reads TikTok's own `video.list`. Find the row whose `latePostId` is the Zernio
post id, and take its `platforms[0].platformPostId` (numeric) and `platformPostUrl`.
`overview.totalPosts` is the account's whole published count and is a fast sanity check.

**An absent row does NOT mean failure — the sync lag is ~a day, not minutes**
(measured on Lists 41/42, 2026-08-27→28). List 42 published 15:28:39Z and was still
missing from analytics at 15:35Z that day, with `lastSync` frozen at 15:29:38Z across
repeated reads and `analytics_get_post_timeline` returning an empty timeline; it
appeared by 16:33Z the **next** day with id `7678733724082654478` and 54 views. List
41's *manual* upload — known live, its URL working — was invisible in exactly the same
window. So:

- **Within a publish run, TikTok can only ever be `unconfirmed`.** Do not wait for
  analytics during the wake cycle, and do not arm extra wakes for it: the data will
  not arrive inside +20 min. Record `status: "unconfirmed"` with the handle, say so in
  the report, and stop.
- **Confirm on the next day's run** (the harvest is the natural place): re-read
  analytics, and flip to `published` with the numeric id or to `failed` if it is still
  absent a day later.
- Only conclude `failed` from an absent row once **more than a day** has passed, or
  from Eric looking at the profile — which is instant and beats the API every time.

**What this cost on List 41:** the 14:46:52Z chunked-upload 503 was retried, the retry
logged `success` at 15:01:52Z with handle `v_pub_url~v2-1.7678353046983985165`, and the
run reported all five platforms live. The video was never on TikTok — caught only when
Eric noticed it missing a day later. **A retry that sits in `publishing` far longer
than a normal publish (9 min vs ~46 s) is a warning sign, not just slowness.**

Record both when you do confirm a TikTok publish: `platform_post_id` (numeric),
`platform_publish_handle` (the `v_pub_url~…`), and `platform_post_url`.

**Recovery is a fresh `posts_create_post`, not `posts_retry`** — the Zernio post is
already marked `published`, so `posts_retry` refuses it ("Only works on posts with
'failed' status").

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
  set it — name it in the one-line report (step 7) as the one manual step publishing
  still owes; nothing else surfaces it now that the checklist is gone.
  **Instagram cover:** works via `instagramThumbnail`.
- **Site URLs:** after go-live, `posts_get_post` returns each `platformPostUrl` and the
  raw `platformPostId` if the user wants links for the website.

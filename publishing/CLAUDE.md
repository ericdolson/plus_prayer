# publishing/ — Zernio Publishing Pipeline

Inherits all brand-wide truths from the root CLAUDE.md. The brand voice applies
in full to every caption, description, and pinned comment.

## Workflow

Claude + Zernio MCP via Claude Desktop. Publishing is driven by `lists.json`
(the master manifest) and a single natural-language instruction from Eric.

Zernio = formerly Late API (cosmetic rebrand, same endpoints, same keys, same MCP).

### The one-line publish command

> "publish list 7 to go live at 8am MST"

That's all Eric needs to say. Claude reads `lists.json`, finds the entry for
list 7, generates platform-specific captions, schedules via Zernio MCP, then
writes the result back into that entry's `published` field.

### Before publish day — Eric's prep checklist

**1. Export and upload the video**

Export `list_N.mp4` from Premiere. Upload to Firebase Storage via the Firebase
Console or CLI. The Console shows the download URL immediately after upload —
copy it.

**2. Add the entry to `lists.json`**

Copy the top-level `template` object and paste it into `"lists"` under the next
list number as a string key (e.g. `"3"`), keeping the newest near the top. Fill in:
- `video_url` — paste the URL copied from Firebase Console (the full URL
  including `?alt=media&token=...`); this is also the URL passed to Zernio
- `thumbnail_url` (optional) — public URL of the day's cover still (1080×1920
  wax-color frame). Passed to Zernio to auto-set the **Instagram** cover; the TikTok
  cover via Zernio is unreliable (set manually in-app), YouTube (Short) is set
  manually in Studio, and Facebook/Threads ignore it.
- `soul_count` — number of names on the printed list
- `notes` (optional) — context Claude needs for captions

Don't add `published` or `date` — Claude writes both on publish (`date` is derived
from the scheduled day). That's it — Eric's prep is done.

**3. Commit `lists.json`**

The manifest is the durable record. Commit the new entry before publish day.

### What Claude does on publish

When told "publish list N at [time] [timezone]":

1. Read `lists.json`, get the entry at `lists["N"]`.
2. Check `published` — if present/non-null, stop and report it's already published.
3. Read brand voice from root CLAUDE.md.
4. Generate platform-specific captions + pinned first comment for each platform
   in the capability matrix (see below). Use `soul_count`, `date`, and `notes`
   as the factual inputs. Only mention `intention_count` if it is greater than
   zero — omit it entirely when zero.

**Caption conventions (locked):**
- **Description shape lives in `captions/list-caption-template.md`** — follow it for
  every list. Structure: the **count line** placement differs by platform (see next
  bullet), plus the "+Prayer … the world plus prayer" intro and the ritual + CTA
  (CTA last). Voice = spare + subtle human warmth (root CLAUDE.md).
- **Count line:** `List N — X souls[ & Y intentions]` — show souls/intentions only
  when > 0 (join with " & "); never "& 0 intentions". On **YouTube** it's the video
  TITLE (no "— +Prayer" suffix) and is left OUT of the description. On **every other
  platform** it's the FIRST line of the description (source note appended if any).
- Use **souls**, not "names" — it's the brand word and carries more weight.
- YouTube title format: `List N — X souls[ & Y intentions]`
- Description CTA phrasing: `Pray for those on it, and leave a 🙏 when you have — you'll be on the next.`
- Pinned comment standard phrasing (YouTube, Facebook; adapt minimally for others):
  > Comment 🙏 to pray for this list. Your name goes on the next.
- Instagram first comment directs to bio link (no tappable links in comments).
- TikTok caption directs to YouTube/Instagram. It MAY carry a 🙏 for the eye-draw,
  but anchored to those platforms ("head to YouTube or Instagram to leave a 🙏") —
  never implying a 🙏 left on TikTok counts (comment aggregation is blocked there).
- Do not use "retired" for the ritual — lists are kept, not destroyed; the current
  one rests on the table until the next replaces it.
5. Schedule the post on all platforms using the **scheduling procedure below**
   (`posts_create_post`), passing `video_url` as the media source and
   `thumbnail_url` as the cover where supported.
6. Write the result back into the `published` field of the list entry:
```json
"published": {
  "scheduled_for": "2026-07-10T15:00:00Z",
  "platforms": {
    "youtube":   { "post_id": "...", "status": "scheduled" },
    "instagram": { "post_id": "...", "status": "scheduled" },
    "facebook":  { "post_id": "...", "status": "scheduled" },
    "threads":   { "post_id": "...", "status": "scheduled" },
    "tiktok":    { "post_id": "...", "status": "scheduled" }
  }
}
```
7. Commit the updated `lists.json`.
8. Output a post-publish todo list (see below).

### Scheduling procedure — use `posts_create_post` (STANDARD)

Use **`posts_create_post`**, one call per platform. It takes `scheduled_for` (ISO
UTC) directly and stores it **verbatim** (verified 2026-07-05, List 3), so it
schedules at the exact instant AND sets covers in the same call — no park-and-update.

**Default lead time: ~2 minutes out** (changed 2026-07-31 from ~5 min). Any
future-dated instant routes through the scheduler and so avoids the Threads 409 —
the lead is not there to satisfy the queue (which polls sub-minute), it's slack for
the five create calls. Compute the target immediately before the first create, not
at the start of the run, and if it drifts within ~60s of now, push it out a minute.
A past `scheduled_for` falls back to immediate publishing.

**Finding the tool (as of 2026-07-12):** `posts_create_post` is no longer a
top-level MCP tool — only the simplified `posts_create` (single platform,
relative `schedule_minutes`, no `media_items`/`platformSpecificData`) and
`posts_cross_post` are directly listed, and neither supports what this
procedure needs. The full tool still exists in Zernio's larger auto-generated
catalog: call `mcp__zernio__search_tools` (query e.g. "create post
scheduled_for platforms media_items") to get its schema, then invoke it via
`mcp__zernio__call_tool` with `name: "posts_create_post"` and the arguments
below as `arguments`. Confirmed working 2026-07-12, List 10 — all five
platforms scheduled correctly this way.

1. Convert the requested wall-clock time + timezone to the exact **UTC instant**,
   DST-aware (e.g. 9am Mountain in July = 9am MDT = 15:00Z; January = 16:00Z).
2. For each platform, call `posts_create_post` with `content` = that platform's
   caption, `scheduled_for` = the target UTC ISO, media via `media_items`, plus:
   - **YouTube** — `platforms:[{platform:"youtube", accountId, platformSpecificData:{title, visibility:"public"}}]`; cover goes on the media item (`media_items:[{type:"video", url, thumbnail}]`). Shorts ignore custom thumbnails, so also set it manually in Studio.
   - **Instagram** — `platforms:[{platform:"instagram", accountId, platformSpecificData:{contentType:"reels", instagramThumbnail:<thumbnail_url>}}]`.
   - **TikTok** — do NOT pass a cover. `tiktok_settings.video_cover_image_url` broke
     List 3 (Zernio's ffmpeg cover-stitch timed out, and that attempt burned TikTok's
     daily API quota, blocking retries). Post TikTok with **no cover** (reliable, like
     Lists 1–2); set the TikTok cover manually in-app if wanted.
   - **Facebook / Threads** — `platforms:[{platform, accountId}]` (no cover via API).
3. **Verify:** the create response returns the persisted post with `scheduledFor`
   and `status` — confirm `scheduledFor` equals the intended UTC and status is
   `scheduled` (spot-check with `posts_get` if unsure).

**When each platform actually fires (measured across Lists 21–29, `logs_list_logs`
`post.published` timestamps vs. `scheduled_for`):**

| platform  | actual publish time vs. target |
|-----------|--------------------------------|
| YouTube   | **ignores the target** — ~1–2 min after the CREATE call |
| Facebook  | +0.8 to +1.4 min |
| TikTok    | +0.9 to +3.9 min |
| Instagram | +2.0 to +3.2 min |
| Threads   | +2.6 to +5.0 min |

**YouTube does not wait for `scheduledFor`.** It publishes shortly after creation
every time — List 28 was created ~15:47 for a 15:55 target and went live 15:47:42
(7.3 min early); List 29 was created 22:22:26 for 22:28 and went live 22:24:08. The
lead time is exactly how early YouTube lands, which is the other reason the default
lead is short: at ~2 min all five land within about a minute of each other, so the
first-comment and pinning work isn't strung out. Never schedule a list hours ahead
expecting YouTube to hold it — it won't.

The +1 to +5 min lags on the other four are queue pickup plus per-platform video
processing, not lead-time-dependent. They're normal; a post sitting in `publishing`
status a few minutes after the target is on track, not stuck.

**Do NOT use `posts_create` + `schedule_minutes`.** That path has a timezone bug:
it computes the fire time from a naive *local* now + minutes and stores it tagged
as UTC, so a morning target fires ~(UTC offset) hours early — effectively
immediately (it shipped List 1 ~3h early on 2026-07-03). `posts_create_post` with
an explicit `scheduled_for` avoids this entirely.

**Caption dedup:** Zernio rejects identical content posted to the same workspace
within 24h (409). Give each platform a distinct caption (a minor wording change
is enough) — don't reuse the exact same text across platforms.

**Immediate Threads publishing returns a 409 but usually posts anyway — DELAYED.**
Publishing NOW, Threads almost always returns `[409] ...already scheduled,
publishing, or posted within 24h`, yet it typically **publishes anyway, a few
minutes later** (async). Lists 4 and 5 both 409'd and then posted (~2–4 min after).
So on a Threads 409: **do NOT retry** (retrying made a duplicate on List 4). **Wait
a few minutes, THEN check** `logs_list_logs platform=threads` for a `post.published`
success (its `response_body` has the real `{id, url}`; the Zernio `post_id` is on
the log) — or just look at the Threads profile. A too-early log check shows nothing
even though it's about to post (this happened on List 5). Only post manually if it's
genuinely still absent after waiting. **Best fix: schedule the list a couple of minutes
out instead of publishing immediately** — scheduled Threads posts go through cleanly,
no 409. The 409 is strictly an artifact of the immediate path, so *any* future-dated
`scheduled_for` clears it; ~2 min is enough (see the default lead time above).

### Post-publish todo list (CANONICAL — output every time)

**After EVERY publish, output this exact checklist to Eric — same five sections,
same order, all five platforms listed in each, every time.** Fill in [N], [N-1],
[count][ & Y intentions], and the time. In "Publish status," mark each platform
✅ posted or ⚠️ FAILED with its manual fix (e.g. Threads/TikTok manual post). Never
drop a section or a platform; if a platform needs nothing in a section, write
"nothing." Omit only the "Close out List [N-1]" section for List 1. **Every comment
must be the COMPLETE text for that platform, ready to copy-paste — never abbreviate
with "…" or "same as above."**

```
List [N] — [count] souls[ & [Y] intentions] — [published now | scheduled for [time] [tz] ([HH:MM]Z)]

── 1. Publish status (confirm all five) ──
- YouTube   — [✅ posted | ⚠️ FAILED: <reason> → <fix>]
- Facebook  — [✅ posted | ⚠️ ...]
- Instagram — [✅ posted (cover set) | ⚠️ ...]
- Threads   — [✅ posted | ⚠️ FAILED → post manually (caption provided)]
- TikTok    — [✅ posted | ⚠️ FAILED → post manually in-app (caption provided)]

── 2. First comment + pin (once live) ──
- [ ] YouTube   — WATCH PAGE (not Studio), as the channel: comment
      "Comment 🙏 to pray for this list. Your name goes on the next." → ⋮ → Pin
- [ ] Facebook  — as the Page: same comment → ⋯ → Pin comment (or pin in app)
- [ ] Instagram — same comment → pin IN THE APP (long-press → pin)
- [ ] Threads   — nothing (the 🙏 CTA is already in the caption)
- [ ] TikTok    — nothing

── 3. Covers / thumbnail ──
- [ ] YouTube   — upload list_[N]_thumbnail in Studio → Content → the Short → Thumbnail
      (Zernio can't thumbnail a Short)
- Instagram — cover auto-set ✅ (⚠️ set manually if the post was manual)
- TikTok    — no cover (do NOT set via Zernio); set manually in-app if wanted
- Facebook / Threads — default frame (nothing)

── 4. Close out List [N-1] (skip for List 1) ──
- [ ] YouTube   — edit pinned comment (⋮ → Edit) to:
      List [N-1] is retired — but a 🙏 here still counts. Find the newest list on our channel.
- [ ] Facebook  — edit pinned comment (⋯ → Edit) to:
      List [N-1] is retired — but a 🙏 here still counts. Find the newest list on our Page.
- [ ] Instagram — can't edit: DELETE old pinned comment, post this new one, re-pin (app):
      List [N-1] is retired — but a 🙏 here still counts. Find the newest list on our profile.
- [ ] Threads   — REPLY to the List [N-1] post with this, then pin the reply (⋮ → Pin reply):
      List [N-1] is retired — but a 🙏 here still counts. Find the newest list on our profile.
- [ ] TikTok    — leave unchanged

── 5. Next list ──
- [ ] Ask Claude to harvest 🙏 since the watermark into participants.json pending[[N+1]]
- [ ] Run `npm run participants-pdf` in `scripts/` for the printable list
```

### First comment & pinning per platform (new video)

Zernio can't reliably post or pin these, so do them by hand once the video is
live. Browser handles YouTube's pin (watch page). Facebook comments post in the
browser but pinning is often app-only; Instagram pinning is app-only.

- **YouTube** (browser **watch page, NOT Studio**) — comment `Comment 🙏 to pray for this list. Your name goes on the next.` then pin it from the public watch page while signed in as the channel (hover comment → ⋮ → Pin). The Pin option does NOT appear in YouTube Studio's Comments tab. Requires channel **Advanced Features** enabled (new channels: youtube.com/verify; can take ~24h) — if pin is missing everywhere, this gate is why. One pin max; Zernio may auto-pin, so verify rather than double-post.
- **Facebook** (comment in browser as the Page; PIN often app-only) — comment the same as the Page, then pin it. The desktop Pin option only appears when acting AS the Page (or in Meta Business Suite → the post → comments), and it's inconsistent on the new Pages experience / by region — if it's not there, pin in the app. (Editing this comment later, for close-out, does work in the browser.)
- **Instagram** (comment on web or app; PIN is APP ONLY) — comment the same, then pin it in the app (long-press or swipe the comment → pin icon; up to 3).
- **Threads** — no first comment needed; the 🙏 CTA is already in the post body. (Optional: pin a reply as a highlighted note — ⋮ → Pin reply; browser OK.)
- **TikTok** — no 🙏 mechanic (comment aggregation blocked). Optional redirect comment; pinning is app-only. Nothing required.

### Thumbnails / covers per platform

Covers CAN be set through the MCP — use **`posts_create_post`** (not the simplified
`posts_create`) for video posts, passing a public thumbnail URL (host the still on
Firebase Storage like the videos). Fields:
- **TikTok** — `tiktok_settings.video_cover_image_url` exists but is **UNRELIABLE**:
  on List 3 (2026-07-05) Zernio's ffmpeg cover-stitch timed out, and the failed
  attempt consumed TikTok's low daily API quota, blocking retries. **Do not set the
  TikTok cover via Zernio** — post without a cover (reliable) and set it manually
  in-app if wanted.
- **Instagram** — platform entry `platformSpecificData: { instagramThumbnail: <url> }`. Works (verified List 3).
- **YouTube** — `media_items: [{ type:'video', url:<video>, thumbnail:<url> }]`, or
  `posts_update_post_metadata` `thumbnail_url` after publish. CAVEAT: Zernio custom
  thumbnails are **regular videos only, NOT Shorts** — vertical short-form posts as
  a Short, so set YouTube's thumbnail natively in Studio instead (see below).
- **Facebook / Threads** — no reliable cover via API.

So only the **Instagram** cover can be safely automated at schedule time; the
TikTok cover via Zernio is unreliable (set it manually in-app); YouTube stays a
manual Studio step; Facebook/Threads use a default frame. Changing a cover never
affects views or comments.

**Selecting a cover frame is metadata only** — it does NOT insert the frame into
the video or change playback, so there is no loop flash. This is completely
different from splicing a still into the timeline (which DOES flash on looping
platforms — never do that). Since the ritual's opening shot is the same every
day, use the **day's wax-color pour/stamp** as the distinctive cover frame; the
7-day color rotation makes each day's thumbnail visually distinct automatically.

- **YouTube (Short)** — browser: Studio → Content → the Short → pencil → Thumbnail → upload a still OR pick a different frame (2026 desktop feature). Mobile: pencil → frame scrubber. Custom upload 1080×1920, JPG/PNG. Requires phone verification / Advanced Features — same gate as pinning.
- **Instagram** (app) — the Reel → Edit → Edit Cover → drag the slider to the wax frame, or upload a still (1080×1920). Silent.
- **TikTok** (app, within ~7 days) — the video → ⋯ → Edit post → Edit cover → slider to the wax frame or upload → Save. If unavailable, the only fix is delete + repost.
- **Facebook** — a frame/thumbnail can be picked at POST time in Meta Business Suite, but Zernio cross-posts fall back to a default frame and post-hoc editing is usually unavailable. Assume FB won't carry the wax frame.
- **Threads** — no cover picker; uses the opening frame. Can't set the wax frame.

**Best practice:** export the day's wax-color still (1080×1920) once from Premiere
and host it publicly. Pass its URL via `posts_create_post` to auto-set the TikTok
and Instagram covers at schedule time; upload the same still to YouTube manually in
Studio. Facebook and Threads will use a default/opening frame — keep the opening
shot presentable so those still look fine.

**Scheduling note:** the **Instagram** cover is set at schedule time by the
standard `posts_create_post` flow (see the scheduling procedure above). Do NOT set
the TikTok cover via Zernio — it broke List 3 (ffmpeg stitch timeout + burned the
daily API quota); set it manually in-app. YouTube (Short) also needs a manual
Studio upload.

### Firebase Storage — how the video URL works

Zernio accepts a **video URL**, not a local file path. The Firebase Console
shows the download URL immediately after upload — it already includes
`?alt=media&token=...` and returns video bytes directly. That's `video_url`.

### `lists.json` shape

Top-level object with a `template` (only the fields Eric supplies for a new list)
and `lists` keyed by list number as a string. Keep the newest list near the top;
Claude accesses `lists["N"]` directly. The list number is the key — there is no
`list_number` field. `date` and `published` are both written by Claude on publish
(`date` derived from the scheduled day), so a freshly-pasted entry has neither.

```json
{
  "template": {
    "soul_count": 0,
    "intention_count": 0,
    "notes": null,
    "video_url": "",
    "thumbnail_url": null
  },
  "lists": {
    "3": {
      "soul_count": 4660,
      "intention_count": 0,
      "notes": null,
      "video_url": "https://firebasestorage.googleapis.com/v0/b/plusprayer.firebasestorage.app/o/publishing_videos%2Flist_3.mp4?alt=media&token=<token>",
      "thumbnail_url": "https://firebasestorage.googleapis.com/v0/b/plusprayer.firebasestorage.app/o/publishing_thumbnails%2Flist_3.jpg?alt=media&token=<token>"
    }
  }
}
```

On publish Claude adds `date` and the `published` block to the entry.

`intention_count` is always present in the manifest for completeness, but only
referenced in captions when greater than zero.

## Daily transition timing (UPDATED — important)
The daily list transition is kicked off **manually by Eric, ~8am his time**, NOT
on a schedule. (Supersedes the earlier 9:30pm/scheduled assumption.) Manual keeps
it flexible — life happens.

When a new list goes live, edit the previous list's pinned comment to point to
the new current list. Use Zernio MCP to update it. Use **"retired"** — the list is
set aside and kept (not destroyed), which fits the ceremony and reads naturally
before "but a 🙏 here still counts." Do NOT say "sealed" (collides with the ritual
description, where sealing is what happens to the fresh current list) or "closed"
(contradicts the 🙏-still-counts mechanic). Keep "retired" for this close-out
status only — never in the ritual description. Standard copy per platform:

Point people to the newest list generically (their newest post is the current
list), using the right term per platform — no dated links to maintain.
**Browser works for YouTube, Facebook, and Threads. Instagram must be done in the app.**

**YouTube** (browser **watch page, NOT Studio** — hover the pinned comment → ⋮ → Edit → Save):
> List [N-1] is retired — but a 🙏 here still counts. Find the newest list on our channel.

**Facebook** (browser — edit the pinned comment: ⋯ → Edit; editing keeps it pinned, no re-pin needed):
> List [N-1] is retired — but a 🙏 here still counts. Find the newest list on our Page.

**Instagram** (APP ONLY — comments can't be edited on web, and only within 15 min in-app, so by the next day you must DELETE the old pinned comment, post this as a NEW comment, then re-pin it: long-press → pin):
> List [N-1] is retired — but a 🙏 here still counts. Find the newest list on our profile.

**Threads** (browser — the post itself can't be edited after 15 min, so REPLY to the original post, then pin that reply: ⋮ → Pin reply):
> List [N-1] is retired — but a 🙏 here still counts. Find the newest list on our profile.

**TikTok** — leave unchanged. The caption already directs people to YouTube/Instagram to participate; no mechanic to close.

## The 🙏 mechanic (social phase)
- Comment 🙏 to be added to the next day's list. By participating you also pray
  for everyone on the current list. This is the reciprocal loop and the
  zero-friction entry point that mirrors the app's core value.
- **Social is SOULS-ONLY.** No free-text intentions on social. (Decided:
  consistency with the app's "self is free, carrying others is paid" model;
  better social mechanics — one emoji is lowest-friction; lower moderation risk;
  and intentions want the app's structured UI anyway. "Add intentions and the
  people you love" becomes the app's opening value prop.)
- Names pulled from social are LOWER TRUST (source = "social") and get strict
  name moderation before they're printed. The list is curated, not a live feed.

## Platform capability matrix (agent reference)
| Platform  | Publish | First Comment | Auto-Pin       | Comment Aggregation | Sub status on comment |
|-----------|---------|---------------|----------------|---------------------|-----------------------|
| YouTube   | yes     | yes           | yes (verify)   | yes                 | yes (native)          |
| Instagram | yes     | yes           | unreliable     | yes                 | no                    |
| Facebook  | yes     | yes           | no             | yes                 | no                    |
| Threads   | yes     | no            | no             | yes                 | no                    |
| TikTok    | yes     | no            | no             | no (API blocked)    | no                    |

- **TikTok:** reach/discovery only — direct viewers to YouTube/Instagram for the
  🙏 mechanic. Scraping TikTok comments violates ToS — do not.
- **Instagram closed-state copy** directs to bio link (no tappable links in
  comments). YouTube/Facebook/Threads use direct URLs.

## Comment aggregation pipeline

Harvest 🙏 comments and carry those commenters onto the next list. A 🙏 on any
past list still counts, so old posts stay eligible — but the harvest no longer
deep-fetches every post every run (that grew with the list count and always
returned brand-only comments). Instead it enumerates all posts cheaply for their
`commentCount` and only deep-fetches the two most-recent lists plus any post whose
count changed since last run (see "Count-delta" below). State lives in
`publishing/participants.json` (`last_aggregated_at`, `brand_accounts`, `pending`
by target list number, and `post_counts` = per-post `commentCount` history).

**Verified against Zernio (2026-07-04 dry run):** there is no unified cross-post
comment feed — use `comments_list_inbox_comments` (min_comments≥1) to find
commented posts, then `comments_get_inbox_post_comments` (post_id + account_id)
per post. Sources that actually return comments: **YouTube, Instagram, Facebook,
Threads** (Threads confirmed working 2026-07-11; some Threads `from` objects omit
`id` entirely, so use `isOwner` for the brand filter there rather than relying on
`from.id`). TikTok isn't queryable.

Harvest steps:
1. Enumerate all commented posts (`comments_list_inbox_comments`, every page) with
   their current `commentCount`. Deep-fetch (`comments_get_inbox_post_comments`) a
   post only if it's one of the **two most-recent lists** (the current live list and
   the just-retired one — the always-check floor), is **new** to `post_counts`, or
   its count **changed** since last run. Skip the rest: an unchanged count off the
   floor means no new comment (a real 🙏 bumps the count). The floor guarantees the
   brand's same-day "List N-1 is retired — but a 🙏 here still counts" comment gets
   fetched and filtered by step 3. Keep comments with `createdTime` after
   `last_aggregated_at`.
2. Keep comments whose message contains 🙏 (U+1F64F), allowing a trailing skin-tone
   modifier (e.g. `🙏🏻`, U+1F3FB–U+1F3FF).
3. **Drop the brand's own comments** — this is the critical filter, because the
   pinned CTA ("Comment 🙏…") and the close-out copy both contain 🙏. `isOwner:true`
   catches channel-owned comments, but NOT secondary/wrong-login brand accounts
   (e.g. `@PlusPrayer-m9v`, `UCD_ExEbqKc3cM7xEy3-6uDA`), so also exclude any
   `from.id` in `participants.json` → `brand_accounts`.
4. Deduplicate by `from.id`, per platform (YouTube/IG/FB IDs aren't cross-comparable).
5. Append survivors to `pending[<next list number>]`.
6. Update `post_counts["<platform>:<postId>"]` to the current count for **every**
   enumerated post (not just fetched ones), then advance `last_aggregated_at` to the
   harvest time.

**Count-delta:** `post_counts` (`{ "<platform>:<postId>": <int>, ... }`, keyed by the
platform-native id, not the Zernio `_id`) is the per-post `commentCount` history that
lets step 1 skip unchanged old posts. First run after this landed has an empty map, so
everything is fetched once to seed it. Residual blind spot: a participant 🙏 on an old
post (off the floor) coinciding with a deletion on that same post can net to no count
change and be missed — negligible at this volume. The full-detail version of this
lives in the `harvest-comments` skill.

When a list is assembled, its `pending[N]` entries are the social-sourced names
(strict name moderation applies — see root Core Principles), then clear `pending[N]`.

Filter by **comment** time, not post time — that's what makes a same-day 🙏 on an
old post count toward the next list.

## Tools
- Publishing/comments: Zernio (cheapest paid tier suffices at one post/day)
- Email: Kit
- Stickers (planned): Ecwid + Printful, net-zero vinyl SKU

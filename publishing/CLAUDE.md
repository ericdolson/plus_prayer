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
  wax-color frame). Passed to Zernio to auto-set the TikTok and Instagram covers;
  YouTube (Short) is set manually in Studio; Facebook/Threads ignore it.
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
- **Description shape lives in `captions/list-caption-template.md`** — the locked
  three-paragraph structure (define +Prayer + "the world plus prayer" pun → list
  line + optional source note → ritual + CTA last). Voice = spare + subtle human
  warmth (root CLAUDE.md). Follow the template for every list.
- Use **souls**, not "names" — it's the brand word and carries more weight.
- YouTube title format: `List N — [count] souls — +Prayer`
- Description CTA phrasing: `Pray for those on it, and leave a 🙏 when you have — you'll be on the next.`
- Pinned comment standard phrasing (YouTube, Facebook; adapt minimally for others):
  > Comment 🙏 to pray for this list. Your name goes on the next.
- Instagram first comment directs to bio link (no tappable links in comments).
- TikTok caption directs to YouTube/Instagram. It MAY carry a 🙏 for the eye-draw,
  but anchored to those platforms ("head to YouTube or Instagram to leave a 🙏") —
  never implying a 🙏 left on TikTok counts (comment aggregation is blocked there).
- Do not use "retired" for the ritual — lists are kept, not destroyed; the current
  one rests on the table until the next replaces it.
5. Schedule the post on all platforms using the **reliable scheduling procedure
   below**, passing `video_url` as the media source.
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

### Reliable scheduling procedure (Zernio timezone bug — IMPORTANT)

Zernio's `posts_create` `schedule_minutes` is **broken**: it computes the fire
time from a naive *local* "now" (account tz = US Mountain) + minutes, then stores
it tagged as UTC. Net effect: posts fire ~(local UTC offset) hours early — for a
morning target this means they publish **immediately**. This shipped List 1 ~3h
early across all 5 platforms on 2026-07-03. Do NOT trust the "Scheduled: HH:MM"
confirmation from `posts_create`.

`posts_update` with an explicit ISO `scheduled_for` is honored **verbatim** as
true UTC (verified). So schedule every post this way:

1. First convert the requested wall-clock time + timezone to the exact **UTC
   instant**, accounting for DST (e.g. 9am Mountain in July = 9am MDT = 15:00Z;
   in January = 9am MST = 16:00Z).
2. `posts_create` (as **scheduled**, not draft — drafts can't be promoted) with
   `schedule_minutes` >= 1440 to park the post safely in the future so the bug
   can't fire it early. Scheduled posts require media (`video_url`).
3. `posts_update` each post with `scheduled_for` = the exact target UTC ISO string.
4. `posts_get` each post and **verify** `scheduled_for` equals the intended UTC
   instant and status = `scheduled`. Only then is it correctly scheduled.

**Caption dedup:** Zernio rejects identical content posted to the same workspace
within 24h (409). Give each platform a distinct caption (a minor wording change
is enough) — don't reuse the exact same text across platforms.

### Post-publish todo list

After every publish, output this checklist with the specific list number filled in:

```
✅ List [N] scheduled for [time] [tz]

Manual actions needed:
- [ ] Instagram: pin the first comment manually (auto-pin unreliable)
- [ ] Facebook: pin the first comment manually (no auto-pin)
- [ ] YouTube: verify the first comment auto-pinned correctly

When the previous list's posts go live (if applicable):
- [ ] Update List [N-1] to point to the new list — YouTube, Instagram, Facebook: edit the pinned comment
- [ ] Threads: the post can't be edited and has no pinned comment — REPLY to the original List [N-1] post with the update copy

Day of / after going live:
- [ ] Run `npm run collect-participants` in scripts/ to gather 🙏 comments for the next list
```

Omit the "previous list" block on List 1 (no prior list to close).

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
- **TikTok** — `tiktok_settings: { video_cover_image_url: <url> }`. Fully supported.
- **Instagram** — platform entry `platformSpecificData: { instagramThumbnail: <url> }`. Fully supported.
- **YouTube** — `media_items: [{ type:'video', url:<video>, thumbnail:<url> }]`, or
  `posts_update_post_metadata` `thumbnail_url` after publish. CAVEAT: Zernio custom
  thumbnails are **regular videos only, NOT Shorts** — vertical short-form posts as
  a Short, so set YouTube's thumbnail natively in Studio instead (see below).
- **Facebook / Threads** — no reliable cover via API.

So TikTok + Instagram covers can be automated at schedule time; YouTube stays a
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

**Scheduling note:** `posts_create_post` also takes `scheduled_for` (ISO UTC) +
`timezone` directly. Verify with a parked test whether it schedules at the correct
time in one call — if so, it replaces the park-then-`posts_update` workaround AND
sets covers in the same call.

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
the new current list. Use Zernio MCP to update it. Do NOT say "sealed" or
"closed" — "sealed" collides with the description (where sealing is what happens
to the fresh, current list), and "closed" contradicts the mechanic that a 🙏 here
still counts. Name the actual state: a newer list is up. Standard copy per platform:

Point people to the newest list generically (their newest post is the current
list), using the right term per platform — no dated links to maintain.
**Browser works for YouTube, Facebook, and Threads. Instagram must be done in the app.**

**YouTube** (browser **watch page, NOT Studio** — hover the pinned comment → ⋮ → Edit → Save):
> A newer list is up now — but a 🙏 here still counts. Find the newest list on our channel.

**Facebook** (browser — edit the pinned comment: ⋯ → Edit; editing keeps it pinned, no re-pin needed):
> A newer list is up now — but a 🙏 here still counts. Find the newest list on our Page.

**Instagram** (APP ONLY — comments can't be edited on web, and only within 15 min in-app, so by the next day you must DELETE the old pinned comment, post this as a NEW comment, then re-pin it: long-press → pin):
> A newer list is up now — but a 🙏 here still counts. Find the newest list on our profile.

**Threads** (browser — the post itself can't be edited after 15 min, so REPLY to the original post, then pin that reply: ⋮ → Pin reply):
> A newer list is up now — but a 🙏 here still counts. Find the newest list on our profile.

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
Google Cloud Functions call the Zernio REST API nightly, aggregate 🙏 comments
from Instagram/Facebook/YouTube, filter for the participation emoji, and output a
markdown list. Claude's role is the summary/review layer on pre-processed data.

**Scan all past posts, not just the most recent.** The algorithm surfaces old
posts to new viewers; a 🙏 on any past list still counts toward the next list.
This is intentional — generous to late arrivals and consistent with the promise.
The closed-state copy on old posts confirms this explicitly.

The intended implementation is timestamp-based, not post-by-post:
1. Fetch all comments across all posts since `last_aggregated_at`
2. Filter for 🙏
3. Deduplicate by commenter identity (someone may 🙏 multiple old posts)
4. Output the participant list
5. Advance `last_aggregated_at`

**OPEN:** Verify that Zernio exposes a unified cross-post comment feed with
timestamp filtering before implementing the Cloud Function. If only per-post
endpoints exist, the function will need to iterate posts and paginate comments
— more work but the same result.

## Tools
- Publishing/comments: Zernio (cheapest paid tier suffices at one post/day)
- Email: Kit
- Stickers (planned): Ecwid + Printful, net-zero vinyl SKU

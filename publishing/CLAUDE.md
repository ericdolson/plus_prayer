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

Add a new entry to `publishing/lists.json` under `"lists"`. The only fields
to fill in:
- `video_url` — paste the URL copied from Firebase Console (the full URL
  including `?alt=media&token=...`); this is also the URL passed to Zernio
- `date` — the date the list was assembled/sealed (YYYY-MM-DD)
- `soul_count` — number of names on the printed list
- `notes` (optional) — context Claude needs for captions

Leave `published` as `null`. That's it — Eric's prep is done.

**3. Commit `lists.json`**

The manifest is the durable record. Commit the new entry before publish day.

### What Claude does on publish

When told "publish list N at [time] [timezone]":

1. Read `lists.json`, find the entry for list N.
2. Check `published` — if non-null, stop and report it's already published.
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
- [ ] Close pinned comment on List [N-1] across YouTube, Instagram, Facebook, Threads

Day of / after going live:
- [ ] Run `npm run collect-participants` in scripts/ to gather 🙏 comments for the next list
```

Omit the "previous list" block on List 1 (no prior list to close).

### Firebase Storage — how the video URL works

Zernio accepts a **video URL**, not a local file path. The Firebase Console
shows the download URL immediately after upload — it already includes
`?alt=media&token=...` and returns video bytes directly. That's `video_url`.

### `lists.json` full entry shape

```json
{
  "list_number": 1,
  "date": "2026-07-03",
  "soul_count": 4604,
  "intention_count": 0,
  "notes": "Seed list — missing children from NamUs database",
  "video_url": "https://firebasestorage.googleapis.com/v0/b/plusprayer.firebasestorage.app/o/publishing_videos%2Flist_1.mp4?alt=media&token=<token>",
  "published": null
}
```

`intention_count` is always present in the manifest for completeness, but only
referenced in captions when greater than zero.

## Daily transition timing (UPDATED — important)
The daily list transition is kicked off **manually by Eric, ~8am his time**, NOT
on a schedule. (Supersedes the earlier 9:30pm/scheduled assumption.) Manual keeps
it flexible — life happens.

When a new list goes live, edit the previous list's pinned comment to a closed
state. Use Zernio MCP to update it. Standard closed-state copy per platform:

**YouTube / Facebook** (links supported in comments):
> List [N] is sealed. 🙏 here still counts — or find the current list at [channel link].

**Instagram** (no tappable links in comments):
> List [N] is sealed. 🙏 here still counts — or find the current list at the link in bio.

**Threads** (no comment — edit post description if Zernio supports it; otherwise leave as-is):
> List [N] is sealed. 🙏 here still counts — find the current list at +Prayer.

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

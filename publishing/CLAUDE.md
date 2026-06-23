# publishing/ — Zernio Publishing Pipeline

Inherits all brand-wide truths from the root CLAUDE.md. The brand voice applies
in full to every caption, description, and pinned comment.

## Workflow
Claude + Zernio MCP via Claude Desktop. Eric drops a video file and a voice memo
into a dated folder; Claude transcribes the memo and constructs platform-specific
captions and a pinned first comment, then publishes via Zernio.

Zernio = formerly Late API (cosmetic rebrand, same endpoints, same keys, same MCP).

### Folder-as-brief (input — gitignored, NOT in repo)
```
/shorts/YYYY-MM-DD-title/
  video.mp4          ← media: NOT in git; lives in Cloud Storage
  voice.m4a          ← natural voice memo; the brief. No structured format needed.
  published.json     ← written by Claude AFTER successful publish
```
- The voice memo is the brief — it covers what the video is about, tone per
  platform, hashtags/intentions to reference, anything for the pinned comment.
- **Double-post prevention:** check for `published.json` before publishing; skip
  the folder if present.
- Only text outputs (captions, transcripts, published.json, list markdown) are
  committed — under `captions/`. Video bytes never enter git.

### published.json (written post-publish)
Records per-platform post_id + status and the list_number, plus the Cloud
Storage reference to the video. The repo records THAT a video published and
WHERE it lives, not the bytes.

## Daily transition timing (UPDATED — important)
The daily list transition is kicked off **manually by Eric, ~8am his time**, NOT
on a schedule. (Supersedes the earlier 9:30pm/scheduled assumption.) Manual keeps
it flexible — life happens. When a new day's post goes live, the previous day's
pinned comment is edited once to a closed/redirect state (one extra API call).

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

## Tools
- Publishing/comments: Zernio (cheapest paid tier suffices at one post/day)
- Email: Kit
- Stickers (planned): Ecwid + Printful, net-zero vinyl SKU

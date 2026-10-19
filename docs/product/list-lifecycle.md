# List Lifecycle

_Last updated: 2026-10-17_

## DECIDED
- **One global list per day**, sequential `listNumber`. Physically printed,
  stitched, wax-sealed, filmed, and ceremonially retired. (Root CLAUDE.md)
- **Option C — current flips at the cutoff** (2026-06-24). Prayers close for list N
  and N+1 is assembled ~6am MT; N+1 becomes current at that moment. Pray before
  the flip → on N+1. Pray after → you are praying for N+1 → on N+2. No gap.
- **Video follows the flip** (~8am MT). A list can be current before its video is
  up; the app shows "the list is being filmed, available shortly" until
  `PrayerList.videoPublishedAt` is set.
- **Transition is manual**, kicked off by Eric. Not scheduled. Moderation review
  fits into that same manual step. (Supersedes the old 9:30pm/cron idea and the
  "transition at ~8am" wording still in some docs.)
- **Assembly = server-side join-and-write** (set-based INSERT … SELECT inside
  Postgres). Rows never ship to a client.
- **Assembly rule per participating user** (prayed with the list included):
  self name (always) + their `isCarried`, ACTIVE, unresolved names/intentions
  up to the entitlement (an intention only if its name is carried), plus all
  social participants and the active base set.
- **Settle-on-close:** the transition freezes the closing list's final live RTDB
  count into `PrayerList.prayerCount`.
- **Frozen names:** `PrayerListEntry.publicName` is a snapshot; later edits don't
  change a printed list.
- **The list is curated, not a live feed.** `PrayerList.status` draft → published;
  entries carry `source` (app|social) and `moderationStatus`
  (approved|held|excluded) + `heldReason`. Social names get strict filtering.
  Held entries are recoverable.
- **Privacy:** names are never shown publicly. The roster is ADMIN-only.
  Scale (counts, list number) is the public proxy.
- **Base set** (2026-09-13): lists are seeded from the NamUs missing-children
  database as a standing base set. `soul_count` is not a function of the social
  harvest. Source note in captions only when a list is filled entirely from it.
- **Social intake** (2026-07-03): a 🙏 on ANY past post counts and carries the
  commenter onto the next list. Social is souls-only (no free-text intentions).
- **Live counts on RTDB**, mirrored server-side (see presence-live.md).

- **Intentions are printed as text on the physical list** (2026-10-17), alongside
  souls' names. Names and intentions are **character-capped**; font size shrinks
  as lists grow. (Caps TBD — see OPEN.)
- **Social carries the commenter only** (long-standing): a 🙏 adds the commenter
  themselves; any other text in the comment is ignored. This was deliberate so
  that carrying others and intentions is the app's added value.
- **An app user's 🙏 on social carries only them** (2026-10-17), never their app
  subjects. Only an in-app prayer that includes the list carries app subjects.

- **Names print with their intentions** (2026-10-17), grouped as the user
  composed them. The app shows a **"your portion of the list"** preview of
  exactly how their part will look printed, and printing honors it.
- **Single physical copy, never shared.** Needs a clear privacy/terms statement
  (what is printed, who sees it, filmed at a distance/illegible?, retention and
  retirement of the paper) for trust and liability. See open-questions Q22.

- **Names from outside the app** (2026-10-17): new `ExternalPerson` table —
  `source` (SOCIAL | BASE_SET), platform + handle/ID or NamUs case ID,
  display name, firstSeen, activeFrom/activeUntil (base set). A
  `PrayerListEntry` references EITHER a `PrayerSubject` OR an `ExternalPerson`
  (DB check: exactly one). Entry gets a surrogate id; unique index per kind.
  Social: store only public display name + platform ID. Enables de-dupe across
  lists and future handle→account linking (Q18).
- **Resolved NamUs cases** leave the base set quietly — no recognition, not
  counted as answered.
- **Continuous numbering:** backfill lists 1..N (numbers, dates, counts, post
  links) and participants from `publishing/lists.json` and
  `publishing/participants.json` so app List N = social List N.
- **Cutover before launch:** harvest/publish skills write to the database
  (instead of JSON) before the app launches, so it's proven in daily use.

- **In-app video is self-hosted** (2026-10-18): Firebase Storage (public-read
  `videos/` path, cache headers, compressed vertical renditions) to start;
  optimize later (e.g. Cloudflare R2/Stream, Mux, HLS) if egress grows.
  Ad-free, own player, cacheable offline.
- **Placement:** full-bleed on the list's detail page, sound off until tapped.
- **List row avatar = the day's wax seal** (2026-10-18), not a video thumbnail.
  7 custom wax-stamp vectors in the real wax colors. Before the ritual the row
  shows an unsealed state ("being filmed"); once published it is sealed with
  that day's stamp. Video poster frame is used on the detail page.
- **`PrayerList.sealVariant` (0–6) is stored**, set by the publish step. Colors
  are currently fixed by weekday, so publish fills it from the weekday mapping;
  storing it means a future change to the rotation needs no fallback logic.

- **Morning admin flow** (2026-10-18), all via admin-only Cloud Functions
  (admin custom claim) called by Eric's existing Claude skills — no web console
  at MVP:
  1. ~6:00 **Assemble** (one command): settle list N's count, harvest 🙏
     commenters, flip N+1 to current, draft N+1 entries (app users who prayed N
     + social + base set). N+1 can be current while still draft (app shows
     counts only).
  2. **Review** only auto-flagged entries: approve / exclude.
  3. **Print:** the Claude skill keeps generating the PDF, now from DB data.
     Later, move PDF generation server-side so others can help (off Eric's
     computer).
  4. ~8:00 **Publish:** existing skill also sets videoPublishedAt, post links,
     sealVariant, and uploads the video.
- **Auto-flag rules** (apply to app names/intentions and social names):
  (superseded for the beta — see "Moderation for MVP / beta": contact info is
  blocked at input; word blocklist off until Stage 2.)
- **Users are told only about exclusions** (revised 2026-10-18, see "Moderation
  for MVP / beta"): never a pending state; an EXCLUDED item shows "Not printed
  on List N · {category}" after assembly.
- **List gate** (2026-10-18; replaces the seed's 48h window proposal): at
  assembly, a user (and their carried items) is included if they prayed with the
  list included **since the last flip, OR within the last ~30 hours**. The first
  half covers late/skipped manual flips; the second covers people who pray near
  the flip time. Praying every other day is not enough. User-facing rule: "Pray
  for the list each day, and you're carried." Same for every tier. Window length
  is a server-side config value (tunable after beta).
- **Flip warning + exact cutoff** (2026-10-18): Eric's skill sets
  `PrayerList.closesAt = now + 5 min` shortly before the morning routine. A prayer
  counts for the closing list if it **started before `closesAt`** and was committed
  before assembly runs; later arrivals fall to the 30h rule. The next list's
  `currentFrom = closesAt`. In-app only: a quiet "List 52 closes in 5 minutes"
  banner (tap to pray) for anyone who hasn't prayed with the list; no push.
  `closesAt` is mirrored to RTDB `/lists/current` so open apps react live.
  Setting `closesAt` also **creates the N+1 list row** (draft, `currentFrom =
  closesAt`); prayers started after the cutoff count toward N+1.
- Social display names are truncated to 40 graphemes on ingest. Blocklist is
  seeded from an open multilingual list (editable config) + contact/link patterns.
- **Gate qualification (precise, revised 2026-10-18):** only prayers that
  **started before `closesAt`** count for the closing list's assembly: (a)
  `communityList` = the closing list, OR (b) a list prayer that ended within the
  30h before `closesAt`. Prayers after the cutoff belong to N+1 only — one prayer
  can never earn two lists. No extra step for Eric: setting `closesAt` (which
  also creates the N+1 row) and running assembly are the existing routine.
- **Enums:** `source` APP | SOCIAL | BASE_SET; `moderationStatus` APPROVED | HELD |
  EXCLUDED; `reasonCategory` LANGUAGE | CONTACT_OR_LINK | NAME_CHANGES | OTHER →
  shown as "Not printed · Language / Contact info or links / Frequent name
  changes / Didn't meet list guidelines".
- **Base-set rows** use `platform = "namus"` (platform never null).
- **Streak and carry align** (2026-10-18, revised same day): the streak counts
  local days prayed with the list, which always satisfies the gate — so keeping
  the streak keeps you carried.

## Moderation for MVP / beta (2026-10-18)
- **Contact info and links are blocked at input**, unconditionally: names,
  and intentions can't be saved if they contain a phone number (7+
  digits, allowing separators), an email address, or a URL/domain. Checked in
  the app (instant inline message: "Names and intentions can't include phone
  numbers, emails, or links.") and enforced in the server functions. Avoid false
  positives: verse references ("John 3:16", "Psalm 23"), room numbers, dates,
  and abbreviations like "St." must pass. Social names (which can't be blocked
  at input) are excluded at ingest if they match.
- **Aliases are never moderated** (2026-10-18): they're owner-only, never printed,
  never shared (group members see the real name), and are excluded from the
  morning AI first pass. A colorful but sentimental nickname is the user's own.
- **Pending review is invisible to users.** Nothing is ever shown as "in review".
  Rows and the list line read normally ("Daniel will be on List 53").
- **Exception-based review:** the morning skill takes a first pass over names and
  intentions that are new or changed since the last list and gives Eric a short
  list of anything that looks off. **Anything Eric doesn't exclude prints.**
  `HELD` is internal only ("flagged for Eric").
- **Exclusion is shown gently, after assembly:** on that item, next app open —
  "Not printed on List 53 · {category}. Edit to include it next time." (tap →
  edit). Never shown while pending.
- **Deferred to Stage 2 (public launch):** the word blocklist (built, switched
  off by config), its tuning across languages/names, and any broader automated
  flagging. Eric's daily review of the diff keeps the "curated" principle true
  until then.
- Privacy: the morning first pass sends names/intentions to an AI provider
  (Anthropic) for moderation — disclose in the privacy policy.

## OPEN
- **Character caps:** DECIDED 40 for names, 80 for intentions (2026-10-17).
- **What the app shows of a list** beyond counts and the video (list number,
  date, soul/intention counts, "you are on this list" badge).
- **Does the flip time ever get published to users?** It's manual (~6am MT). The
  app likely needs a "prayers for List N close around X local time" line.

## DEFERRED
- Server-side reconciliation of the community-prayer rule (accepted interim gap).
- Scheduled (cron) transition.
- Print-ready PDF rendered server-side into Cloud Storage.

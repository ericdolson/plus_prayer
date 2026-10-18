# Stats & History

_Last updated: 2026-10-17_

## DECIDED
- **Derive on read, don't store** (except the user streak and denormalized list
  counts). A computed value is always correct; a stored one can drift.
- **Three per-subject counts:**
  - Tier 1 "I prayed for Mom" — raw (count of PrayerSubjectLink rows) AND
    cycle (distinct `listContextNumber`). Both supported.
  - Tier 2 "my group prayed for Mom" — later, with groups.
  - Tier 3 "the world prayed for Mom" = SUM(`PrayerList.prayerCount`) over lists
    the subject was on.
- **Never sum tier 3 across subjects** into a headline (multiply-counts).
  "Prayers the world offered" = `PrayerList.prayerCount`, worded separately.
- **Live tier 3 = static + live, stitched client-side.** Query returns sum over
  CLOSED lists + "on current list" boolean; client adds the live RTDB count if true.
- **Intention/subject drill-in view** (memory, 2026-Q3) shows:
  - how many lists it has been on,
  - total prayers it benefited from (tier 3),
  - its history of lists,
  - the user's personal prayer history for it (tier 1, timeline),
  - **gaps labeled in days** ("paused for 3 days"), not in list numbers.
- **Account-wide prayer history** (`getMyPrayerHistory`), paginated, with
  optional "where I prayed" location.
- **Ops:** getSubjectDetail, getSubjectWorldCount, getSubjectLists,
  getSubjectPrayerHistory, getMyPrayerHistory, getMyArchivedSubjects.

## Detail-page history — the bead strand (2026-10-18)
SUPERSEDES the seed's v3 thick/thin/dashed line (seeds/2026-10-11 §4.4–4.7) and
its per-assembly outcome recording (§5). Applies to names, intentions, and "Me".
- **Header:** "Held by you · N prayers" (always) and "Carried by the world · N
  prayers · N lists" (only once ever carried; never "0 lists").
- **Period rows**, newest first: This week, Last week, Earlier in {month}, then
  months, then years; last row "Begun · {date}". Each row: "♡ You prayed N
  times" (counts only, never ratios) + "On N lists" (+ "· current").
- **Beads:** one bead per list the item was on, **colored by that list's wax
  (`sealVariant`)**. Prayer beads are cross-faith (rosary, mala, misbaha,
  prayer rope) and tie the app to the physical seals.
- **Gaps:** one quiet, neutral line — "Off the list · N days" — with no reason
  given (didn't pray, removed, no room are not distinguished). N = missed lists,
  labeled in days.
- **Your prayers are never drawn as days**, so the page never becomes a ledger of
  absences.
- **Hints on period rows:** a small note glyph with count ("✎ 3") when prayers in
  that period have notes, and an "Answered" mark on the period where it was
  answered. Tapping a period expands to individual prayers (with notes), list
  numbers, and the answered moment.
- **Data:** beads = existing `PrayerListEntry` + `PrayerList.sealVariant`; gaps =
  distance between beads; prayers/notes = `PrayerSubjectLink` → `Prayer`;
  answered = subject `resolvedAt`. **No outcome table, nothing extra recorded at
  assembly.** One operation returns the subject + its entries (list number, date,
  sealVariant, prayerCount) + its prayers (prayedAt, localDate, note); the client
  buckets into periods. Paginate by period if histories get very long.
- Lifetime "carried on N lists" lives on Today's list page; never show a
  list-number sequence beside the streak.

## Prayer time (2026-10-18)
- Each prayer in History shows time + duration ("7:42 am · 12 min"; auto-saved
  shown as "~38 min").
- History header: "Time in prayer" — this week and all time.
- Optional: month time in the streak sheet.
- NOT on name/intention detail pages (a prayer holds many items; splitting time
  would be invented math).
- Never ranked or celebrated — longer is not better.

## OPEN
- Whether gaps labeled in days need a per-prayer local date (see
  streaks-reminders.md — same field would serve both).
- Wording of each stat (brand voice: numbers carry weight on their own).
- Is "where I prayed" map in MVP or later?

## DEFERRED
- Tier 2 (groups).
- Coarse/fuzzed global prayer map.

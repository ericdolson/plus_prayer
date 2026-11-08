# History — one screen, any scope

_Last updated: 2026-11-08 (new: replaces the detail page's History calendar)_

One History screen for the whole app. Opened from Home's footer it shows
**everyone combined**; a filter narrows it to one person (or, from an
intention's page, one intention). A person's history is this screen
filtered, never a second design. Data and counts: `stats-history.md`. Where
an older file describes per-page history or the account-wide History
differently, this file wins.

## DECIDED (2026-11-08)

### Scope and filter
- **From the footer:** everyone combined.
- **Filter:** a toolbar button, the same control as Home's filter, opens a
  **searchable list of people** (the add sheet's "Who is this for?" pattern;
  the list can be long). Choosing someone turns the control into a **chip
  "{alias} ×"**, as on Home. People only; a person's scope includes their
  intentions.
- **From a person's page** (tiles, the preview row, "See all"): opens with
  the chip already set. × widens to everyone without leaving the screen.
- **From an intention's page:** the chip shows the intention's text
  (truncated); scope = that intention.
- **Self ("Me")** is filterable like anyone.

### Tabs
A native segmented control: **All · Held · Lists · Journal · Answered**
(2026-11-08). **All** is the default. **Each tab is the full list behind
one mark in the strand**, so the tabs teach the marks:

| Mark in the strand | Tab | Lists |
|---|---|---|
| everything | **All** | the strand itself (the overview) |
| gold ring | **Held** | your prayers |
| bloom | **Lists** | the lists they were on |
| corner dot | **Journal** | your entries, in full |
| gold ✦ | **Answered** | answered intentions |

- **Five is the cap** for a native segmented control: no sixth tab. Places
  (a map of where you prayed, with consent-gated location) would be a
  toolbar button opening a map, not a tab.
- **Large accessibility text sizes:** the control becomes a native menu
  button showing the current tab ("All ⌄").

### All — the strand
**Newest first.** One strand that wraps like a sentence: it starts at today,
top left, and reads left to right, then down, back in time.
```
 Today
  ▾
 (◉)  ◉   ●   ◉   ··  ◉  [Nov]  ◉   ●   ◉   ●
  ◉   ◉   ●   ◉   ●   ●   ◉  [Oct]  ··  ◉   ●

 September              2 prayers · 6 lists
 Begun · Sep 24
```
- **Node = a full neutral disc** (~30 pt, inside a 44 pt tap area made with
  the spacing). Neutral, not the avatar's color: photo avatars would leave a
  colored disc meaning nothing. The meaning comes from Home's two marks:
  - **bloom pressed into the disc** (the carried-mark glyph, ~19 pt at
    ~55% opacity, like initials on an avatar) = **on that day's printed
    list**;
  - **gold ring** (the held ring) = **you prayed for them** that day;
  - both, or either. No hollow states.
  - **A small neutral dot on the corner** = a journal entry that day.
  - **A small gold ✦ in the opposite (lower) corner** = an intention was
    answered that day (rare, so it earns a mark).
- **Only days where something happened get a node.** A run of empty days
  collapses to one small **`··`**, the same whatever its length: it shows
  that time passed without counting it (no "N days" — that's a ledger of
  absence, retired 2026-11-03).
- **Month tab:** a tiny calendar-page shape with the short month ("Nov")
  inline where the month turns, like a chat date separator. No dates on
  nodes.
- **Today is marked:** a small **"Today ▾"** caption above the first node,
  always. Today's node exists even before anything happened (a plain disc;
  it gains the bloom when covered and the ring when you pray, so Amen
  visibly fills it).
- **How far back:** the strand covers this month and last. Older months are
  **two-column rows** (month left; "N prayers · N lists · ✎ N" right in
  `inkMuted`, tabular figures), then older years, then **"Begun · {date}"**
  (scoped: the subject's creation; everyone: your first prayer).
- **Everyone scope** (unfiltered): a node is *your* day: bloom = you were on that list,
  gold = you prayed. The streak line and "Time in prayer" sit above the
  strand (about you; hidden when filtered).
- **Tapping a node** opens a native **half-height sheet** for that day: the
  date, "On List 46 · 3,475 prayers" (if on a list), **"Answered · {intention}"**
  (gold, if one was answered that day), then each prayer you prayed that day
  (time · length, who it held when unfiltered, its journal entry in full). A
  prayer row opens Prayer detail. **A day with no prayer shows only what
  happened** (the list line); never "No prayer this day". A sheet can't sit
  below the fold, unlike an inline panel.
- **Accessibility:** each node is a button labeled with its day and what
  happened ("Thursday, November 5. On List 49. You prayed. Journal
  entry."); `··` reads "No activity"; the month tab is a heading.

### Held (2026-11-08)
- Your prayers, **newest first, grouped by day** ("Today", "Yesterday",
  "Thursday, Nov 5"). Row: time · length ("7:42 am · 12 min"; auto-saved
  "~38 min"); unfiltered, a small avatar cluster of who it held; ✎ when it
  has a journal entry. A row opens Prayer detail.
- Filtered to a person: the prayers that held them.

### Journal
- Your journal entries, **newest first, in full**, set for reading, with day
  headings ("Today", "Yesterday", "Thursday, Nov 5"). Filtered to a person:
  every entry from a prayer that held them. Everyone: each entry shows a
  small avatar cluster of who that prayer held.
- Tapping an entry opens Prayer detail (where it can be edited).

### Lists
- One row per list: wax seal (small) · "List 52" (Roca) · "Sat, Nov 7" ·
  "3,475 prayers". Filtered: the lists that person was on. Everyone: the
  lists you were on. A row opens that past list's page. Wax belongs to a
  list, so this is where history wears wax.

### Answered (2026-11-08)
- Answered intentions, **newest first**. Row: the intention's text (sans) →
  the person's name (small, `inkMuted`) → **"Answered Nov 3"** in
  `heldGoldText` → "You prayed 12 times · On 30 lists" (`inkMuted`). A row
  opens the intention's page. When the thanks entry on Answered exists (v2),
  it shows in full under its row, as in Journal.
- Filtered to a person: their answered intentions. Everyone: all of yours.
- **Released intentions never appear** (release implies no gratitude).
- **No celebration**: no animation, emoji or exclamation. "Answered", the
  date and the counts.

## Words: "journal" (2026-11-08)
- The collection is the **Journal** (tab; tile "3 in your journal").
- After Amen the action is **"Add to journal"**; on an existing one,
  **Edit**.
- "Entry" only where a noun is unavoidable (VoiceOver "3 journal entries").
- The ✎ mark stays an icon. Schema keeps `note`; this is user-facing only.

## OPEN
- **Standalone journal entries** (IDEA, post-MVP): open-questions Q33.

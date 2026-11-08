# Detail Page — names and intentions

_Last updated: 2026-11-08 (History calendar; status moves into the carry card; sans titles; ＋ on Intentions)_

One shared layout for a name (soul) and an intention. Builds on
`stats-history.md` (history data and counts), `screens.md` (screen map),
`subjects.md` (selection rules, lifecycle) and `design-direction.md` (tokens,
type, color roles, motion). Where this file and an older file disagree about
the detail page, this file wins.

## DECIDED (2026-11-03)

### Layout (browsing) — name page
```
‹                                         ⋯
            ( D )        ← ~96 pt avatar; gold ring if held today (3 pt / 3 pt)
             Dad         ← Roca ~28 (the alias, else the name)
         Gary Olson      ← the name, smaller inkMuted, only if there's an alias

  Held by you · 47 prayers
  Carried by the world · 61,204 prayers · 19 lists

  ┌──────────────────────────────────────┐
  │ Carry onto the list ✱          [ON]  │   ← the carry card (cardSurface)
  │ 3 places left                        │
  │ Prints with  Healing after his su… › │   ← person's chosen intention (Q32)
  │ ──────────────────────────────────── │
  │ Pray with today's list to carry      │   ← status line (rules below)
  │ Dad onto List 53                     │
  └──────────────────────────────────────┘

  Intentions                          ＋    ← sans section title; ＋ adds
   Healing after his surgery          ✿ •   ← same intention row as Home
   Rest for his heart

  History
  November                            ✎ 2
   S   M   T   W   T   F   S
                           ·   ✿
   ·  (✿) (✿)  ✿   ·  (·)  ✿
   ✿  (✿)
  You prayed 6 times · On 9 lists
  October                             ✎ 1
   … (grid)
  You prayed 16 times · On 21 lists
  September
  You prayed 4 times · On 16 lists
  Begun · Sep 12

                               ( 🙏 Pray for Dad )   ← blue capsule, pray-button slot
```
```
- **Order:** top section (avatar + name) → counts → carry card → Intentions → History.
- **Avatar ~96 pt** (2026-11-07), the same size as the add sheet's Name tab,
  so adding someone and landing on their page shows one continuous person.
- **Name under the alias** (2026-11-07): when the person has an alias, the
  title is the alias and the **name** (what's printed) sits under it in
  smaller `inkMuted` text (body), for reference. No alias → the name is the
  title and nothing repeats. Self page: title "Me", your name under it.
- **Counts:** "Held by you · N prayers" always; "Carried by the world · N
  prayers · N lists" only once ever carried (never "0 lists").
- **Intentions section** reuses Home's intention row: gold "held today"
  dot, trailing carried mark (§5), gold "Answered · {date}", **but no
  thread** (2026-11-07): on Home the thread ties intentions to the name row
  above; here the page itself is the name, so a thread would hang from the
  section title. Without the thread there's **no Home indent**: rows sit
  flush with the section title (dot, then text).
  Same order as Home (Answered stay in place under the name; Released aren't
  shown). Tapping an intention pushes its own detail page.
- **Adding (2026-11-08):** a plain action-blue **＋** (SF Symbol `plus`, no
  glass: it lives in the content) on the trailing edge of the Intentions
  section title, 44 pt hit target, label "Add intention for {alias}" (self:
  "Add intention"). Replaces the "＋ Add intention for {alias}" link under
  the rows. **No intentions yet** (2026-11-07): no header ＋; the section
  shows a prominent **"＋ Add a first intention for {alias}"** (blue
  tinted-glass button; on the self page "＋ Add your first intention"), so
  there's never two add buttons. (No possessive built from the alias:
  "James's", "Mom & Dad's" and other languages break.) Both open the
  add-intention form for this person (screens.md).
- **Carry card (2026-11-07; Q32 2026-11-08)** — names and intentions; the
  self page's card holds only the status (Me is always carried; Me's
  chosen intention is set from its own page). A flat `cardSurface`
  container with the in-content radius (design-direction §4 "Glass vs.
  surface"), the only box on the page:
  1. Native **Toggle "Carry onto the list ✱"**. Subtitle = the meter (one
     place = one person; intentions cost nothing):
     - Carried: "3 places left"; with none free or over the pool: "All 10
       places in use" (never negative).
     - Not carried: "3 places left"; "This uses your last place"; full:
       "All 10 places in use", toggle disabled, **"Make room for {alias}"**
       under it (inert until Membership / Your portion exist).
     - Free tier: "Free carries you and your intention", disabled, "Make
       room for {alias}".
  2. **"Prints with  {chosen intention} ›"** (only while carried and the
     person has open intentions; "Name only" when none is chosen). Pushes a
     native list titled "Prints with": **Name only**, then the person's open
     intentions (Answered/Released not listed), with a checkmark. At the
     cap (1) tapping another moves the check; a higher tier cap later allows
     that many checks, same screen. Turning the person off hides the row
     and keeps the choice; turning them on prints them as they were.
  3. Hairline, then the **status line** as the footer (rules below).
  - **Turning off asks nothing** (nothing is lost; it's one tap back).
  - **Feedback, never silent:** the toggle flips at once and is disabled
    while saving; if saving fails it flips back with a footer line under
    the row: pool filled from another device → "All {pool} places filled
    up."; other failure → "Couldn't change this. Try again." Offline: the
    toggle is disabled with "Needs a connection." under it. The failure
    line stays until the next tap or leaving the page (ink, like other
    errors). **Turning carrying off always succeeds when online**, even
    over the pool (it frees a place; it's how a lapsed trial trims).
  This page and Your portion are the places a person's carrying is managed.

### Intention page
- **No avatar.** Above the title: the parent name in small `inkMuted` text,
  tappable → pushes the parent's page. Title = intention text in the
  **system sans, Title 2 semibold** (wraps; not Roca, 2026-11-08: Roca is
  for proper names). A **gold dot (~6 pt)** before the title when held today
  (same mark as Home's intention end-dot).
- No Intentions section. Answered/Release live in ⋯.
- **Carry card** (Q32): native **Toggle "Print with {alias} ✱"** (on Me's
  intentions: "Print with your name ✱"). Subtitle when another intention is
  chosen: "Instead of “{chosen}”" (on = swap). Person not carried: on also
  carries them, subtitle "Also carries {alias} · 3 places left"; disabled
  with "Make room for {alias}" when full. Footer = the status line; on with
  the person off: "Private while {alias} isn't carried".

### Status line (in the carry card, 2026-11-08)
Moved from under the title into the carry card's footer, and reworded: what
carries someone is **praying with the list** (the invitation at Amen), not
praying for them, and the old "Pray to carry Dad onto List 53" sat right
above "Pray for Dad".
- **Name:** covered → "{alias} will be on List 53"; prayed with the list but
  the next list isn't covered yet → "Your next prayer with the list carries
  {alias} onto List 54"; not prayed → "Pray with today's list to carry
  {alias} onto List 53".
- **Self ("Me"):** "You'll be on List 53" / "Your next prayer with the list
  puts you on List 54" / "Pray with today's list to be on List 53".
- **Intention (carried):** "It'll be on List 53" / "Your next prayer with the
  list carries it onto List 54" / "Pray with today's list to carry it onto
  List 53".
- **Not carried** (2026-11-08): footer **"Private · in your prayers only"**
  (`inkMuted`): it states what is, not what's missing, and teaches the list
  by contrast with the carried line. An intention switched on whose name
  isn't carried: **"Private while {alias} isn't carried"** (teaches that an
  intention prints only with its name). Replaces "Not on the list"; Home
  rows still never mark absence.
- **Answered intention:** gold "Answered · {date}" under the title, no carry
  card.
- **Closing notice replaces the footer** (only while carried and if you
  haven't prayed with the list today): "List 52 closes in 5 min · pray with
  the list to carry {alias}" / "· pray with the list to be on List 53"
  (self) / "· pray with the list to carry this".
- Weight follows state, as on the community card: not covered → `ink`;
  covered → `inkMuted`.

### Pray button label
- Name: "Pray for {alias}". **Self page and intention pages: "Pray".**

### History (calendar, 2026-11-08)
**Month calendars for the current and previous month; every older period is
text.** Replaces the wax bead strand (2026-11-03): the wax colors read as
decoration with no meaning, and the text rows didn't say anything at a
glance. The grid reuses Home's vocabulary, so it needs no legend:
**gold ring = you held them, bloom = on the printed list.**
- **Layout:** month label (sans, Headline; ✎ count and the "Answered" hint
  right-aligned on that line) → weekday initials (caption, `inkMuted`; week
  start follows the device locale) → the grid → "You prayed N times · On N
  lists" in `inkMuted`. Seven columns across the content width, ~32 pt
  rows, each glyph centered in its cell.
- **Day cells:**
  - nothing that day → a **~4 pt dot in `thread`**: the calendar's shape,
    not a mark of absence (it sits at the thread's level and recedes);
  - on a printed list → the **bloom** (the carried-mark glyph, ~14 pt) in
    `inkMuted` (stronger than the row mark's `carriedMark`: here it's the
    content); ink, not wax, as each name is printed in ink on the paper;
  - you held them (prayed, crediting this item) → a **gold ring** (~24 pt,
    1.5 pt, the held-ring token for that size) around the cell;
  - both → the bloom inside the gold ring.
  - Future days and days before "Begun" are **blank** (that alone shows
    where today is; no today marker).
- **Which day:** list blooms go on the **list's date**; held rings on the
  **local date you prayed**. They can sit a day apart around the flip;
  that's fine. A covered upcoming list shows its bloom on its date as soon
  as its entry exists. No hollow "being filmed" state.
- **Months shown as grids:** the current month and the previous one, only
  from "Begun" on (begun this month → one grid).
- **Older periods are text rows**, newest first: each earlier month of the
  current year, then each earlier year; last row "Begun · {date}".
  Period label (✎ / "Answered" hints right-aligned) → "You prayed N times ·
  On N lists". "This week", "Last week", "Earlier in {month}" and "· current"
  are retired.
- **Empty halves are left out:** a period with lists but no prayers shows only
  "On N lists"; prayers but no lists shows only "You prayed N times"; an
  older period with neither is left out (the two grid months always show).
- **"Answered" hint** on the period where it was answered, **on the
  intention's own page only** (the name page's Intentions section already
  shows "Answered · {date}"). Not tappable.
- **Wording:** "You prayed once", then "You prayed N times" (2+).
  "Begun · Sep 12" in the current year; "Begun · Sep 12, 2025" in earlier
  years.
- **✎ counts** reflect synced notes; a note added offline appears once it
  syncs.
- **Accessibility:** each grid is one element whose label is the month and
  its summary ("November. On 9 lists. You prayed 6 times."); days aren't
  focusable one by one in v1.
- **Tapping a day or period** to see its prayers is v2.
- **Section titles** ("Intentions", "History"): **system sans, Title 3
  semibold** (2026-11-08; were Roca).

### Praying on the page (in place)
Praying from a detail page **stays on the page**. It does not go to Home.
```
[Cancel]
            ( D )                      ○   ← name checkbox in trailing slot, pre-checked
             Dad
  Healing after his surgery            ○
  Rest for his heart                   ○
       Pray for others          ← quiet text link

  ( 12:04 · with 282 )   ( Amen )      + gold halo (design-direction §7)
```
- **Strip the page down; don't disable it.** On start, everything that isn't
  the subject fades out together (~250 ms; plain fades under Reduce Motion):
  counts, the carry card, History, the Intentions ＋, ⋯ and ‹.
- **Controls match Home's prayer mode:** "Cancel" text button top-left
  (replaces ‹; same "Discard this prayer?" confirm after ~30 s). The blue
  capsule morphs into the round pray button (countdown → Amen) and the pill fades
  in beside it, holding **timer · "with N" only (no 🔎)**.
- **Checks:** the name gets a checkbox in the trailing slot, like a Home row,
  and its avatar's gold ring follows the check. Intentions use Home's
  checkbox. Home's selection rules apply (`subjects.md`), including the
  partial state on the name.
- **Crediting:** the subject is **pre-checked** at start, so Amen credits it
  even if nothing else is touched. Intentions are credited only if checked.
  The subject can be unchecked (may be revisited). Nothing checked at Amen →
  a prayer with no subjects (R3).
- **Intention page in prayer:** the intention, pre-checked with its checkbox.
  The parent name shows as plain text above it, not checkable and not
  tappable; by the selection rules it is credited whenever the intention is.
- **"Pray for others"** (under the intentions only) goes to Home, still in
  prayer mode with the checks kept. **System back / swipe-back does the
  same.**
- **The session is app-level state** (the existing per-device draft). The
  detail page renders its own items from that session. A draft restored at
  launch **resumes on Home** (where the prayer began isn't stored).
- **Amen happens on the page:** halo flare, the list invitation (if needed),
  the closing sheet. The stripped sections and updated counts **fade back as
  the closing sheet is dismissed**, so the new count lands in view.
- **No conflict with Home prayer mode:** in prayer, tapping a Home row checks
  it, so a detail page can't be opened mid-prayer.

### ⋯ menu (v1)
- **Edit:** name/alias only (self name follows R10's edit limits). Note and
  avatar tone come later.
- **Answered** (intentions): no thanks note in v1. **Release** (intentions):
  confirm ("Release this intention? It moves to Archived."), then pop back.
- **Archive:** confirm (a name's confirm says its intentions go too), then pop
  back to where you came from. **Hidden on the self page** (self is forced
  ACTIVE). Answered/Release are hidden on name pages.
- Home's long-press quick actions get the same Edit / Answered / Release /
  Archive in this build, sharing the same commands and sheets.

### v1 scope
- **In:** everything above.
- **v2:** tapping a period to expand it into individual prayers (time, notes,
  list numbers, the Answered moment); a thanks note on Answered; editing note
  and avatar tone.

## OPEN
- Whether the subject should be lockable as checked on its own page.

# Detail Page — names and intentions

_Last updated: 2026-11-03 (build answers round 2)_

One shared layout for a name (soul) and an intention. Builds on
`stats-history.md` (bead strand data and counts), `screens.md` (screen map),
`subjects.md` (selection rules, lifecycle) and `design-direction.md` (tokens,
type, color roles, motion). Where this file and an older file disagree about
the detail page, this file wins.

## DECIDED (2026-11-03)

### Layout (browsing) — name page
```
‹                                         ⋯
            ( D )        ← ~72 pt avatar; gold ring if held today
             Dad         ← Roca ~28
      Dad will be on List 53   ← inkMuted status line (rules below)

  Held by you · 47 prayers
  Carried by the world · 61,204 prayers · 19 lists

  Intentions                              ← Roca section title
   Healing after his surgery          ✿ •   ← same intention row as Home
   Rest for his heart
   ＋ Add intention for Dad

  History
  This week                         ✎ 2
  ●─●─●─●─●
  You prayed 6 times · On 5 lists · current
  Last week
  ●─●─●   ●─●
  You prayed 4 times · On 5 lists
        Off the list · 2 days
  Earlier in October
  ●─●─●─●─●─●─●─●─●
  You prayed 11 times · On 9 lists
  Begun · Sep 12

                               ( 🙏 Pray for Dad )   ← blue capsule, pray-button slot
```
- **Order:** top section (avatar + name + status) → counts → Intentions → History.
- **Counts:** "Held by you · N prayers" always; "Carried by the world · N
  prayers · N lists" only once ever carried (never "0 lists").
- **Intentions section** reuses Home's intention row exactly: thread, gold
  "held today" dot, trailing carried mark (§5), gold "Answered · {date}".
  Same order as Home (Answered stay in place under the name; Released aren't
  shown). Tapping an intention pushes its own detail page.
- **Add link:** "＋ Add intention for {alias}"; on the self page just
  "＋ Add intention".

### Intention page
- **No avatar.** Above the title: the parent name in small `inkMuted` text,
  tappable → pushes the parent's page. Title = intention text in Roca
  (~22–24, wraps). A **gold dot (~6 pt)** before the title when held today
  (same mark as Home's intention end-dot).
- No Intentions section. Answered/Release live in ⋯.

### Status line (under the title)
- **Name:** covered → "{alias} will be on List 53"; prayed but next list not
  covered yet → "Your next prayer carries {alias} onto List 54"; not prayed →
  "Pray to carry {alias} onto List 53".
- **Self ("Me"):** "You'll be on List 53" / "Your next prayer puts you on
  List 54" / "Pray to be on List 53".
- **Intention (carried):** "It'll be on List 53" / "Your next prayer carries it
  onto List 54" / "Pray to carry it onto List 53".
- **Not carried** (private, or an intention whose name isn't carried, which
  makes it not carried): **no status line** (mark presence, never absence).
- **Answered intention:** gold "Answered · {date}" in place of the status.
- **Closing notice replaces the status line** under the card's rule (only if
  you haven't prayed with the list today): "List 52 closes in 5 min · pray to
  carry {alias}" / "· pray to be on List 53" (self) / "· pray to carry it".
- Weight follows state, as on the card: not covered → `ink`; covered →
  `inkMuted`.

### Pray button label
- Name: "Pray for {alias}". **Self page and intention pages: "Pray".**

### Bead strand rendering
- **Row layout (all rows):** period label (with ✎ count and "Answered"
  hints right-aligned on that line) → bead strand → text line in `inkMuted`.
  **No ♡ glyph.**
- **Beads = plain wax-colored dots (~9 pt)**, one per list, colored by that
  list's `sealVariant`, with the dark-theme lift from `WaxSeal` (no rim below
  ~24 pt). Stamp detail can't be seen at this size, so **D2 doesn't block this
  screen.** The current list's bead **while unsealed ("being filmed")** uses a
  **lighter neutral than the `unsealed` token** (nearest existing neutral with
  ≥ 3:1 against the background; the `unsealed` body nearly vanishes on dark),
  and becomes its wax once sealed.
- Beads sit on a **thin neutral thread**. Week and month rows show every bead;
  **year rows show counts only, no beads.**
- **Spacing:** one fixed pitch for every row (~9 pt bead + ~3 pt gap),
  left-aligned, never stretched to fit. A row that runs out of width wraps to
  a second line. A short week simply looks short.
- **Direction:** rows run newest first, top to bottom; **within a row, beads
  read oldest → newest, left to right**, so this week's strand grows to the
  right and the current (possibly unsealed) bead sits at its right end.
- Weekday wax colors mix within a week, like a mixed mala. **Accepted pending a
  rendered check**, which also covers Sunday's gold bead vs. held gold and the
  faint dark waxes (navy, garnet, deep green) at 9 pt on dark.
- **Periods:** week start follows the device locale. "This week", "Last week",
  then "Earlier in {current month}" (only days of the current month not
  already shown; skip the row if none), then one row per earlier month of the
  current year, then one row per earlier year. Last row "Begun · {date}" =
  the date the subject was created.
- **Empty halves are left out:** a period with beads but no prayers shows only
  "On N lists"; prayers but no lists shows only "You prayed N times" with no
  thread; a period with neither is left out.
- **Gaps:** a break in the thread with "Off the list · N days" below it,
  neutral, no reason given. Only **between** beads: no gap before the first
  bead and no trailing gap from the last bead to today (the status line covers
  the present). A gap that crosses a period boundary is shown once, at the
  **start (left end) of the newer row's strand**, counting all its days. Gap
  labels sit centered under their break, inside the row; several gaps in one
  row stack on separate lines.
- **"Answered" hint** on the period where it was answered is in v1 (not
  tappable), **on the intention's own page only** (the name page's
  Intentions section already shows "Answered · {date}"). A period that has
  only the Answered moment (no beads, no prayers) **stays, showing just the
  hint.**
- **Wording:** "You prayed once", then "You prayed N times" (2+).
  "Begun · Sep 12" in the current year; "Begun · Sep 12, 2025" in earlier
  years.
- **✎ counts** reflect synced notes; a note added offline appears once it
  syncs.
- **Section titles** ("Intentions", "History"): Roca, same size and weight as
  names on Home.

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
  status line, counts, History, "＋ Add intention", ⋯ and ‹.
- **Controls match Home's prayer mode:** "Cancel" text button top-left
  (replaces ‹; same "Discard this prayer?" confirm after ~30 s). The blue
  capsule morphs into the round pray button (ring → Amen) and the pill fades
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
- Whether mixed weekday colors in one strand read well (needs a render).
- Whether the subject should be lockable as checked on its own page.

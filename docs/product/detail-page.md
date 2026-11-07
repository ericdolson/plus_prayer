# Detail Page — names and intentions

_Last updated: 2026-11-03 (history simplified: one strand, this week only)_

One shared layout for a name (soul) and an intention. Builds on
`stats-history.md` (bead strand data and counts), `screens.md` (screen map),
`subjects.md` (selection rules, lifecycle) and `design-direction.md` (tokens,
type, color roles, motion). Where this file and an older file disagree about
the detail page, this file wins.

## DECIDED (2026-11-03)

### Layout (browsing) — name page
```
‹                                         ⋯
            ( D )        ← ~96 pt avatar; gold ring if held today
             Dad         ← Roca ~28 (the alias, else the name)
         Gary Olson      ← the name, smaller inkMuted, only if there's an alias
      Dad will be on List 53   ← inkMuted status line (rules below)

  Held by you · 47 prayers
  Carried by the world · 61,204 prayers · 19 lists

  Intentions                              ← Roca section title
   Healing after his surgery          ✿ •   ← same intention row as Home
   Rest for his heart
   ＋ Add intention for Dad

  History
  This week                         ✎ 2
  ●─●─●─●─●          ← the only strand: ~12–14 pt wax beads
  You prayed 6 times · On 5 lists · current
  Last week                         ✎ 1
  You prayed 4 times · On 5 lists
  October
  You prayed 11 times · On 9 lists
  Begun · Sep 12

                               ( 🙏 Pray for Dad )   ← blue capsule, pray-button slot
```
- **Order:** top section (avatar + name + status) → counts → Intentions → History.
- **Avatar ~96 pt** (2026-11-07), the same size as the add sheet's Name tab,
  so adding someone and landing on their page shows one continuous person.
- **Name under the alias** (2026-11-07): when the person has an alias, the
  title is the alias and the **name** (what's printed) sits under it in
  smaller `inkMuted` text (body), for reference. No alias → the name is the
  title and nothing repeats. Self page: title "Me", your name under it.
- **Counts:** "Held by you · N prayers" always; "Carried by the world · N
  prayers · N lists" only once ever carried (never "0 lists").
- **Intentions section** reuses Home's intention row exactly: thread, gold
  "held today" dot, trailing carried mark (§5), gold "Answered · {date}".
  Same order as Home (Answered stay in place under the name; Released aren't
  shown). Tapping an intention pushes its own detail page.
- **Add link:** "＋ Add intention for {alias}"; on the self page just
  "＋ Add intention". **No intentions yet** (2026-11-07): the section shows
  a prominent **"＋ Add {alias}'s first intention"** (blue tinted-glass
  button; on the self page "＋ Add your first intention") instead of the
  link. Both open the add-intention form for this person (screens.md).
- **Carry row (2026-11-07)** — names and intentions, not the self page
  (self is always carried): under the counts, a native **Toggle "Carry
  onto the list ✱"** with the add sheet's meter as its subtitle ("3 places
  left" / "This uses your last place" / "All 10 places in use"). Off and
  the pool is full → disabled, with **"Make room for {alias}"** under it
  (inert until Membership / Your portion exist). An intention whose name
  isn't carried shows "Also carries {alias} · uses N places" when on. This
  page and Your portion are the places a person's carrying is managed.

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
  makes it not carried): status line **"Not on the list"** (`inkMuted`).
  Allowed here as the subject's own management page (design-direction §5
  exception, 2026-11-07); Home rows still never mark absence.
- **Answered intention:** gold "Answered · {date}" in place of the status.
- **Closing notice replaces the status line** under the card's rule (only if
  you haven't prayed with the list today): "List 52 closes in 5 min · pray to
  carry {alias}" / "· pray to be on List 53" (self) / "· pray to carry it".
- Weight follows state, as on the card: not covered → `ink`; covered →
  `inkMuted`.

### Pray button label
- Name: "Pray for {alias}". **Self page and intention pages: "Pray".**

### History (simplified 2026-11-03)
**One bead strand, for this week only. Every older period is text.** (An
earlier version drew a strand on every row; in the render it read as confetti,
repeated the counts, and its labeled gaps marked absence.)
- **Row layout:** period label (✎ count and "Answered" hints right-aligned on
  that line) → [this week only: bead strand] → text line in `inkMuted`.
  **No ♡ glyph.**
- **This week's strand:** one bead per list this week, colored by that
  list's `sealVariant`, **~13 pt on a ~22 pt pitch** (tune by eye) so each
  reads as an object, with the
  `WaxSeal` dark-theme lift (rim only from ~24 pt). Beads read **oldest →
  newest, left to right**, on a thin neutral thread, left-aligned, fixed
  pitch. A full week is the whole set of weekday waxes. The current list's
  bead **while unsealed ("being filmed")** is a **hollow ring** (~1.5 pt
  stroke in `inkMuted`, no fill) in both themes, and fills with its wax once
  sealed. (A filled gray bead out-shone five of the seven waxes on dark.)
- **Wax contrast:** the waxes keep their real colors; several sit below 3:1 on
  dark (Mon/Wed ~1.6:1). That's accepted: the beads are decorative and the
  counts line beside them carries the meaning. Don't brighten waxes for the
  strand.
- **Sunday's gold** bead (amber, darker) reads distinct enough from the held
  gold ring. No change.
- **The current list always counts in This week**, even when its date falls
  in the next local week after a flip (a rare eighth bead is fine). Stamp detail isn't drawn, so
  **D2 doesn't block this screen.**
- **Missed lists this week:** a quiet break in the thread, **no label**,
  always **one spacing step of bare thread** however many lists were missed
  (the break doesn't measure absence). No break before the first bead or
  after the last.
- **No gaps anywhere else.** Older rows state counts only; "Off the list · N
  days" is retired.
- **No strand this week** (not on any list this week): the row shows text
  only, like an older row.
- **Periods:** rows newest first. Week start follows the device locale. "This
  week", "Last week", then "Earlier in {current month}" (only days of the
  current month not already shown; skip the row if none), then one row per
  earlier month of the current year, then one row per earlier year. Last row
  "Begun · {date}" = the date the subject was created.
- **Empty halves are left out:** a period with lists but no prayers shows only
  "On N lists"; prayers but no lists shows only "You prayed N times"; a period
  with neither is left out.
- **"Answered" hint** on the period where it was answered is in v1 (not
  tappable), **on the intention's own page only** (the name page's
  Intentions section already shows "Answered · {date}"). A period that has
  only the Answered moment stays, showing just the hint.
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

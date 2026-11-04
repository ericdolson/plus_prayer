# Detail Page — names and intentions

_Last updated: 2026-11-03_

One shared layout for a name (soul) and an intention. Builds on
`stats-history.md` (bead strand data and counts), `screens.md` (screen map) and
`design-direction.md` (tokens, type, color roles, motion). Where this file and
an older file disagree about the detail page, this file wins.

## DECIDED (2026-11-03)

### Layout (browsing)
```
‹                                         ⋯
            ( D )        ← ~72 pt avatar; gold ring if held today
             Dad         ← Roca ~28
      They'll be on List 53   ← inkMuted; same status logic as the community card

  Held by you · 47 prayers
  Carried by the world · 61,204 prayers · 19 lists

  Intentions                              ← Roca section title
   Healing after his surgery            •
   Rest for his heart
   ＋ Add intention for Dad

  History
  This week                    ✎ 2
  ●─●─●─●─●                    You prayed 6 times · On 5 lists · current
  Last week
  ●─●─●   ●─●                  You prayed 4 times · On 5 lists
        Off the list · 2 days
  Earlier in October
  ●─●─●─●─●─●─●─●─●            You prayed 11 times · On 9 lists
  Begun · Sep 12

                               ( 🙏 Pray for Dad )   ← blue (action)
```
- **Order:** top section (avatar + name + status) → counts → Intentions → History.
  Intentions come first because you can act on them; history is for looking back.
- **Counts:** "Held by you · N prayers" always; "Carried by the world · N
  prayers · N lists" only once ever carried (never "0 lists"). Wording per
  `stats-history.md`.
- **Intention page:** same layout without the Intentions section and avatar
  edit; shows its parent name under the title; Answered/Release live in ⋯.
- **⋯ menu:** edit name/alias; Answered / Release (intentions only); Archive.
- **Pray button:** blue, in the pray-button slot, labeled "Pray for {alias}".

### Bead strand rendering
- **Beads = plain wax-colored dots (~9 pt)**, one per list the item was on,
  colored by that list's `sealVariant`, with the dark-theme lift from `WaxSeal`
  (no rim below ~24 pt). No stamp detail at this size, so **the D2 vectors are
  not a blocker** for this screen.
- Beads sit on a **thin neutral thread**. Week and month rows show every bead
  (31 at ~9 pt fit the content width). **Year rows show counts only, no beads.**
- Weekday wax colors mix within a week (up to seven colors), like a mixed mala.
  **Accepted pending a rendered check with real wax colors.** Revisit if it
  reads noisy.
- **Gaps:** a break in the thread with "Off the list · N days" below it,
  neutral, no reason given.

### Praying on the page (in place)
Praying from a detail page **stays on the page**. It does not go to Home.
- **Strip the page down; don't disable it.** On start, everything that isn't
  the subject fades out together (~250 ms; plain fades under Reduce Motion):
  status line, counts, History, "＋ Add intention", ⋯ and ‹. Nothing is left
  that needs a disabled state.
```
            ( D )      ← gold ring: pre-checked
             Dad
  Healing after his surgery    ○
  Rest for his heart           ○
       Pray for others          ← quiet text link

  ( 12:04 · with 282  ✕ )  ( Amen )     + gold halo (design-direction §7)
```
- **What's left:** the avatar and name, plus the intentions with checkboxes
  (the same component as Home). The prayer bar, the pray/Amen button and the
  halo behave exactly as on Home.
- **Crediting:** the subject (Dad) is **pre-checked** at start, so Amen credits
  him even if nothing else is touched. **Intentions are credited only if
  checked.** The subject can be unchecked, the same as any check (may be
  revisited). If nothing is checked at Amen, it's a prayer with no subjects,
  which R3 allows.
- **Intention page:** only that intention, pre-checked.
- **"Pray for others":** goes to Home, still in prayer mode with the
  checks kept; the prayer continues. It replaces ‹ while praying.
- **The session is app-level state** (the existing per-device draft). The detail
  page renders its own items from that session. There's no separate prayer
  logic for this screen.
- **Amen happens on the page:** halo flare, the list invitation (if the list
  hasn't been prayed today), the closing sheet. Then the stripped sections fade
  back in and the counts and the current period update (e.g. "You prayed 7
  times").
- **No conflict with Home prayer mode:** in prayer, tapping a row on Home
  checks it rather than opening its page, so a detail page can't be opened
  mid-prayer.

### v1 scope
- **In:** the top section, both counts, Intentions, period rows with beads
  and gaps, the pray button, praying in place, the ⋯ menu.
- **v2:** tapping a period to expand it into individual prayers (time, notes,
  list numbers, the Answered moment). The ✎ note-count hint on period rows can
  show in v1 but isn't tappable yet.

## OPEN
- Whether mixed weekday colors in one strand read well (needs a render).
- Whether the subject should be lockable as checked on its own page.

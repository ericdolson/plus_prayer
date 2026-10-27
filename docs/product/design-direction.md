# Design Direction — Home & visual system

_Decided 2026-10-23 in a design review of the app agent's first Home build.
**This file overrides `app-brief.md` wherever they differ** (see §10)._

**North star:** minimal, modern, expensive. Clean and beautiful, not dull.
Restraint is what makes it feel high-end: lots of space, crisp type, few
signals per row, and color used only when it means something.

**Brand principle, scoped (2026-10-23):** "darker over lighter, antique over
bright" governs the **physical ritual and anything on camera** (wax, lighting,
objects). The **app UI** is clean and modern on light and dark themes, with
color used by meaning (§1). The wax seals are the one place the ritual's
antique character appears in the app.

---

## 1. Color system — every color has one job

| Role | Meaning | Used for | Never for |
|---|---|---|---|
| **Blue (brand)** | *Do this* | Pray button, Amen, the invitation's tap target, primary buttons | Status, decoration, toggles, checks |
| **Gold** | *Held* | Ring on held avatars, end-dot on held intentions, prayer-mode halo, "Answered" text, gold rim on carried avatars in the community card after you pray | Buttons, warnings, large fills |
| **Neutrals** | Quiet | Canvas, surfaces, ink (3 levels), threads, icons, switches | — |

- No red, no pink anywhere. No other accent colors.
- Settings switches and other controls are **neutral** (ink-colored "on"
  state), not blue.

### Tokens (adjust the existing `PPDarkPalette` / `PPLightPalette`)
_Revised 2026-10-24: dark `primary`/`onPrimary` back to the electric blue with
white; dark grounds taken about halfway to black; `sheet` added._

| Token | Dark | Light | Notes |
|---|---|---|---|
| `primary` | `#0580F9` (brand electric blue) | `#0573E0` | The pray button's blue, as before the review (2026-10-24) |
| `onPrimary` | `#FFFFFF` | `#FFFFFF` | Dark: 3.8:1 — passes for the glyph and large text (≥3:1), short of 4.5:1 for small text, so keep labels on blue large/bold. Light: 4.6:1 |
| `ground` | `#0E1012` (was `#1D2124`) | `#E9EEF9` | Dark is near-black like iOS/Gmail dark, not pure black (OLED smear; nothing for frosted bars and the gold glow to read against) |
| `sheet` (new) | `#16191D` | = `ground` | Bottom sheets and dialogs: a slight lift from the ground in dark (1.08:1; 1.16:1 over the scrim) |
| `raised` | `#23272D` (was `#2D313A`) | `#F5F7FD` | Fields, pills, the footer bar, settings groups on a sheet |
| `heldGold` (rename from `carriedGold`) | `#C8AE6E` | `#9A7A30` | Rings + dots (non-text, ≥3:1) |
| `heldGoldText` (new) | `#C8AE6E` | ~`#765A1C` | Text like "Answered · Oct 6" (≥4.5:1). `#9A7A30` is only ~3.5:1 on `#E9EEF9` |
| `heldGlow` (new) | `heldGold` @ 30–40% alpha, wide blur | — (none) | Glow is dark-mode only; it washes out in light |
| `cardSurface` (new) | `#1A1D21` (was ~`#23272B`) | `#F5F7FD` (`raised`) | Community card: one clear step above the ground (1.13:1) |
| `thread` | `hairline` `#2A2E35` (was `#343943`) | `hairline` `#D3DAE8` | Neutral always |
| `unprayedRose` | **delete** | **delete** | The pink dot is gone; remove the token so it isn't reused |
| `inkMuted` | `#9097A1` | `#566D83` (was `#5C748C`) | Secondary text. Dark 6.5:1 on ground; light darkened to pass 4.5:1 (4.6:1) |
| `inkFaint` | decorative only | decorative only | ~3.7:1 dark, ~2.4:1 light — never essential text. Secondary text uses `inkMuted` |

Contrast is computed (WCAG AA: 4.5:1 body text, 3:1 large text and non-text
UI); the figures in `app/lib/theme/tokens.dart` are the checked ones.

---

## 1b. Avatar palette — bright, modern (2026-10-27)
Monogram avatars use **bright, saturated mid-tones with white initials** (the
Gmail / Spotify feel), not muted/antique tones. Color is how users find their
people at a glance. The sacred palette lives on the wax seals (and, later, the
prayer experience) — not on avatars.

**Rules (protect the color system):**
1. **No gold / amber / yellow** (avoid ~35°–60° hue): gold means *held*; a
   yellow avatar would blur the held ring.
2. **No blue close to the action blue `#0580F9`**: avatars must never read as
   buttons. Other blues (indigo, ocean, sky) are fine.
3. **No true red**: use raspberry / berry / vermilion; pure red reads as an alert.

**Craft:** white initials at ≥3:1 contrast (large text) — roughly Material
600–800 shades, never neon 300s or dull grays. Same palette in light and dark;
in dark mode lower brightness very slightly to avoid glare on the near-black
ground. 12–16 colors, well separated in hue so neighbors rarely match
(`avatarTone` 0–15). Default tone from a hash of the subject id. **After launch
the index→color mapping must stay stable** (changing it recolors everyone's
people); changing it now is free.

**Starting set** (tune + verify contrast; up to 3 more allowed under the rules):
`#D81B60` raspberry · `#AD1457` berry · `#8E24AA` purple · `#5E35B1` violet ·
`#3949AB` indigo · `#0277BD` ocean · `#00838F` cyan · `#00897B` teal ·
`#2E7D32` green · `#558B2F` olive · `#E64A19` vermilion · `#6D4C41` cocoa ·
`#546E7A` slate

The gold held-ring's 2 pt gap keeps it legible on every tone.

## 2. Typography
- **Serif (Roca)** only for: names on Home, list numbers ("List 52"), and big
  lines (splash, invitation, section titles on detail pages).
- **Body sans = the platform system font**: SF Pro on iOS (via the system
  font), Roboto on Android. Roboto on iOS is the biggest thing making it feel
  like an Android port.
- **Intentions are sans**, one to two steps smaller than names, in `inkMuted`
  — readable, clearly secondary. Names are the landmarks.
- Respect Dynamic Type / font scaling; layouts must not clip at large sizes.

---

## 3. Layout & spacing (Home)
- **20 pt side margins.** No divider lines between rows.
- **Name rows: one line** (secondary text only for exceptional states, §5).
  ~64 pt tall with a ~44 pt avatar. Intention rows: ~44 pt.
- Generous gap between the community card and the list (~24 pt) and between
  name groups (~12–16 pt). Let the screen breathe.
- **No chevrons anywhere on Home.** The whole row is tappable. The trailing
  slot stays empty in nav mode; the checkbox fades in there in prayer mode.

---

## 4. Header, footer, search
- **Header (left):** your avatar (→ You/settings) with the **streak badge**
  beside it. The badge is the **new logo as a small wax seal** — never a "+"
  glyph. States: prayed with the list today → seal in today's wax + number;
  alive but not yet today → muted seal + number; zero → muted seal, no number.
- **Header (right):** **filter only.** **Search is hidden until you pull the
  list down** (iOS Mail/Notes pattern); it persists across nav and prayer modes
  once shown.
- **Footer:** `[ History ]  ( 🙏 )  [ ＋ ]`, unchanged in function.
- **Translucent bars:** header and footer are blurred so the list scrolls
  visibly beneath them (iOS frosted material). On Android or low-end devices,
  fall back to a semi-opaque fill. The pray button keeps full contrast over
  any content.
- "+" means **Add** and nothing else.

---

## 5. Rows — mark presence, never absence
- **Remove:** the pink unprayed dot, "Last prayed N days ago", "Prayed today",
  the carried badge on avatars, and all chevrons.
- **Held today = gold:** when you hold someone in prayer, their avatar gets the
  gold ring and **keeps it until local midnight**. Everyone else simply looks
  normal. This is the same signal as checking them in prayer.
  - **Ring spec:** 2 pt ring with a 2 pt gap from the avatar on 40–44 pt
    avatars. Dark mode adds `heldGlow`; light mode is ring only.
  - **Always solid** (2026-10-24): holding a name is whole, however you prayed
    for them. No dashed/partial ring — the intention dots already show which
    intentions you held. "Partial" exists only as the checkbox state during
    prayer mode.
- **Secondary text only when it means something:** "Answered · Oct 6" (in
  `heldGoldText`), "Not printed on List 53 · {category}. Edit to include it next
  time." Otherwise, no second line.
- The **"Unprayed today" filter** still exists; it just isn't painted on rows.
- History and "last prayed" live on the detail page (bead strand).

### Intentions on a thread
- A thin neutral `thread` line drops from the **bottom-center of the name's
  avatar** and curves to each intention (like a prayer strand — the same
  metaphor as the bead history).
- **Intention text is left-aligned with the name text.** No bullets, no icons.
- **Held today:** a small **gold dot (~5 pt)** where the thread meets the
  intention (glow in dark mode, solid in light). The thread itself never
  changes color or weight.
- Answered intentions: gold "Answered · {date}" text; no special shape.
- **Tap an intention → its own detail page** (shared detail layout). No
  chevron. **Long-press** a name or intention → quick actions (edit, add
  intention, resolve, archive).

---

## 6. The community card (replaces the "pinned list row")
A **flat tonal surface** (`cardSurface`), no shadow, no border, radius ~20–24
pt, generous padding (~16–20 pt). Clearly different from the rows; it is the
value of the app.

```
╭──────────────────────────────────────────────╮  gold border when you've
│  (seal)  List 52                              │  prayed with the list TODAY
│          4,345 people · 31,208 prayers        │
│          ● 258 praying now                    │
│                                               │
│  (JE) You, (D) Dad ●●● + 3  are on List 52    │  today's list (plain avatars)
│  Pray to carry them onto List 53              │  tomorrow (text, own line)
╰──────────────────────────────────────────────╯
```
- **Scale first** (people · prayers), then **presence** with a small live dot
  (display ladder: live ≥10 → last hour ≥10 → today ≥10 → hidden; never 0),
  then **your carry status** with the avatar cluster.
- **Held = the card's border, not the avatars** (2026-10-24): when you've prayed
  with the list **today (your local day)**, the card gets a thin gold border
  (~1.5 pt, `heldGold` at ~70–80%; soft outer glow in dark mode, border only
  in light). It lights live when the card is checked in prayer mode and clears
  at **local midnight** — the same clock as the streak and the row rings, never
  the flip (a border that survived until the flip would make a user think
  they'd prayed today and break their streak). **Cluster avatars stay plain**
  (no rims — too busy at small sizes).
- **Two groups, two lines:**
  - **Avatar row = yours on today's list** (the list shown on the card):
    "You, Dad + 3 are on List 52". New user / not on today's list: no avatar
    row.
  - **Status line = tomorrow**, on its own line, computed from the real gate:
    - qualifying prayer for the next list exists → "They'll be on List 53"
      (+ small seal stamp at Amen — part of the signature moment);
    - prayed with the list today but the next list isn't covered yet (some
      time zones after the flip) → "Your next prayer carries them onto List 54";
    - not prayed → "Pray to carry them onto List 53".
    New user: "Pray to be on List 53" → "You'll be on List 53".
  - **Only differences are named:** "Mom joins you on List 53"; "Aunt Jo isn't
    carried on List 53" (tap → Your portion).
  - **No extra "you held this list yesterday" icon or count** (2026-10-24): the
    status line already says they're covered ("They'll be on List 53"), and a
    dot or prayer count would compete with today's nudge. Per-list prayer
    counts live on the Today's list page.
- **Never break "List" from its number:** use a non-breaking space ("List 53")
  everywhere.
- Wax seal: unsealed + "being filmed" before publish; sealed in the day's wax
  after.
- The 5-minute **closing notice** ("List 52 closes in 5 minutes") lives inside
  the card, only if you haven't prayed with the list today.
- **Tap → Today's list.** **In prayer mode the whole card is the checkable
  "hold the list" target.**
- **Presence:** shown here to *invite*; prayer mode reveals more as the reward
  (the count moving live; later, richer presence such as countries).
- The separate floating "258 praying now" line above the list is removed.

---

## 7. Prayer mode visuals
- **Halo is gold** (gold = holding): edge glow in dark mode; a slightly
  stronger gradient in light mode so it doesn't vanish.
- Checkbox fades into the trailing slot of every row and the community card.
  **Checked = gold ring on the avatar / gold dot on the intention**, applied
  live.
- Pray button → ring countdown → **Amen** stays **blue** (action).

---

## 8. Motion — one signature moment
- **The signature:** Amen → the seal. That's the one big moment; give it the
  care.
- **Checks:** a small spring on the check + the gold ring/dot fading in, plus a
  light haptic. This is the only place a bounce/spring is used.
- Everything else (navigation, sheets, filters) is quiet and quick.
- Reduce Motion: replace springs and glows with simple fades.

---

## 9. Icons
- **One thin-line icon family** throughout (e.g. Phosphor Light/Regular or
  Lucide), matched in stroke weight to the custom praying-hands glyph. No
  mixing with rounded Material icons.

---

## 10. What this supersedes in `app-brief.md` and the spec
- "Rows: title + one secondary line" → secondary text only for exceptional
  states (§5).
- "Unprayed dot (POC pink)" → removed; presence is marked with gold instead.
- "Small mark if carried on the next list" on rows → removed (carried lives in
  the community card, Your portion, and the detail page).
- "Rows' `>` becomes a checkbox" → no chevrons; the checkbox fades into the
  empty trailing slot.
- "Pinned list row" → the community card (§6).
- "Presence line" above the list → inside the card.
- Header right "search + filter" → filter only; pull-down search.
- Ember "glow" as the check → gold ring/dot spec (§5); glow only in dark mode.
- Gold rims on community-card cluster avatars → a gold card border, day-scoped (§6).
- Streak badge glyph → the new logo as a wax seal.
- Color rule: blue = action, gold = held, everything else neutral.
- Muted/antique avatar tones → bright avatar palette (§1b).

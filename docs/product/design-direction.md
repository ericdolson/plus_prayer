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
| Token | Dark | Light | Notes |
|---|---|---|---|
| `primary` | `#5AA9FB` (logo blue) | `#0573E0` | Same blue family, tuned per theme |
| `onPrimary` | `#0B1A2B` (near-black) | `#FFFFFF` | White on `#5AA9FB` fails contrast (~2.4:1); dark glyph ~7.5:1 |
| `heldGold` (rename from `carriedGold`) | `#C8AE6E` | `#9A7A30` | Rings + dots (non-text, ≥3:1) |
| `heldGoldText` (new) | `#C8AE6E` | ~`#765A1C` | Text like "Answered · Oct 6" (≥4.5:1). `#9A7A30` is only ~3.5:1 on `#E9EEF9` |
| `heldGlow` (new) | `heldGold` @ 30–40% alpha, wide blur | — (none) | Glow is dark-mode only; it washes out in light |
| `cardSurface` (new) | ~`#23272B` | `#F5F7FD` (`raised`) | Community card. Dark `raised` `#2D313A` is too big a jump from `ground` |
| `thread` | `hairline` `#343943` | `hairline` `#D3DAE8` | Neutral always |
| `unprayedRose` | **delete** | **delete** | The pink dot is gone; remove the token so it isn't reused |
| `inkFaint` | decorative only | decorative only | ~3.3:1 dark, ~2.4:1 light — never essential text. Secondary text uses `inkMuted` |

Contrast figures are hand estimates — **verify every pair** (WCAG AA: 4.5:1
body text, 3:1 large text and non-text UI).

---

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
    avatars; 1.5 pt ring / 1.5 pt gap on small cluster avatars. Dark mode adds
    `heldGlow`; light mode is ring only.
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
╭──────────────────────────────────────────────╮
│  (seal)  List 52                              │  serif, list number
│          4,345 people · 31,208 prayers        │  sans, inkMuted
│          ● 258 praying now                    │  only when ≥ threshold
│                                               │
│  (JE) You, (D) Dad ●●● + 3                    │  avatar cluster
│  not yet carried on List 53                   │  → "will be on List 53"
╰──────────────────────────────────────────────╯
```
- **Scale first** (people · prayers), then **presence** with a small live dot
  (display ladder: live ≥10 → last hour ≥10 → today ≥10 → hidden; never 0),
  then **your carry status** with the avatar cluster.
- **After you pray with the list, the cluster avatars light up with the gold
  ring** and the line becomes "will be on List 53" — the moment the card
  confirms they're held by the world tomorrow.
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
- Streak badge glyph → the new logo as a wax seal.
- Color rule: blue = action, gold = held, everything else neutral.

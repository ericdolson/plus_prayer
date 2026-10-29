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
| `heldGlow` | `heldGold` @ 30–40% alpha, wide blur | — (none) | **Only** for the prayer-mode screen halo and the brief bloom on check (2026-10-27). Never a static glow on Home |
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

**Craft:** white initials **at 80% opacity**, so the letters lightly take on
the tone (2026-10-27), at ≥3:1 contrast (large text) on every tone in both
themes — roughly Material
600–800 shades, never neon 300s or dull grays. Same palette in light and dark;
in dark mode lower brightness very slightly to avoid glare on the near-black
ground. 12–16 colors, well separated in hue so neighbors rarely match
(`avatarTone` 0–15). Default tone from a hash of the subject id. **After launch
the index→color mapping must stay stable** (changing it recolors everyone's
people); changing it now is free.

**Final palette** (2026-10-27; frozen at launch). The starting set, tuned —
berry `#AD1457` → `#9C1450` and teal `#00897B` → `#00876A` to separate them
from raspberry and cyan; olive `#558B2F` → `#5F9133` (lighter to separate it
from green, then darkened just enough to hold 3:1 under 80% initials) — plus
fuchsia, sienna and forest. Ordered so tones 1 and 3 apart (where similar ids
land in the FNV-1a hash) differ strongly (ΔE ≥ 67):

| # | Tone | Hex | # | Tone | Hex |
|---|---|---|---|---|---|
| 0 | indigo | `#3949AB` | 8 | raspberry | `#D81B60` |
| 1 | cocoa | `#6D4C41` | 9 | ocean | `#0277BD` |
| 2 | purple | `#8E24AA` | 10 | sienna | `#A0522D` |
| 3 | forest | `#1E6B3A` | 11 | teal | `#00876A` |
| 4 | vermilion | `#E64A19` | 12 | berry | `#9C1450` |
| 5 | slate | `#546E7A` | 13 | olive | `#5F9133` |
| 6 | fuchsia | `#AD1F8C` | 14 | violet | `#5E35B1` |
| 7 | cyan | `#00838F` | 15 | green | `#2E7D32` |

Dark mode blends each tone 6% toward black. Closest pairs: forest/green and
olive/green (ΔE 15); lowest initials contrast: olive and vermilion (3.0:1 in
light). Source of truth: `app/lib/theme/tokens.dart` (`PPAvatarTones`).

The gold held-ring's 2 pt gap keeps it legible on every tone: the ring sits
on the ground (8.8:1 dark, 3.5:1 light), and every tone is ≥ ΔE 28 from the
gold.

## 1c. Dark-mode neutrals (2026-10-28)
- **Keep a very slight cool tint** on dark surfaces (`#0E1012` ground →
  `#1A1D21` card, etc.) — it matches the blue-tinted light theme, makes the
  brand-blue pray button feel native, and lets gold rings pop. Not pure gray.
- **Neutral dark ink** (decided on device 2026-10-28, over the old blue ink
  and pure gray): `#D7E0EE` read noticeably blue on large type. `ink`
  `#E8EAED`, `inkMuted` `#9A9EA4`, `inkFaint` `#6C7076` (decorative) — 15.8:1,
  7.1:1 and 3.8:1 on the ground; muted is ≥ 5.6:1 on every surface.
- **All neutrals share one hue** (the surfaces' faint cool tint, ~216°) — no
  mismatched grays.

## 2. Typography
- **Serif (Roca)** only for: names on Home, list numbers ("List 52"), and big
  lines (splash, invitation, section titles on detail pages).
- **Body sans = the platform system font**: SF Pro on iOS (via the system
  font), Roboto on Android. Roboto on iOS is the biggest thing making it feel
  like an Android port.
- **Intentions are sans**, clearly smaller than names (13 pt), clearly
  secondary but **easy to read** (2026-10-28): aim for ~7:1 contrast (between
  `inkMuted` and the neutralized `ink`) and/or regular weight rather than
  light. Names are the landmarks.
- **"Answered · {date}" is never larger than its intention:** same 13 pt or one
  step smaller, in `heldGoldText` (gold carries the emphasis).
- **Avatar initials use the body sans, not the serif** (2026-10-28): serif
  initials repeat the serif name beside them ("D Dad") and blur at small
  sizes; sans reads as a badge, keeps the serif special for names, and suits
  the bright palette. Medium/semibold weight, ~40% of the avatar diameter,
  slight letter-spacing on two letters, optically centered.
- Respect Dynamic Type / font scaling; layouts must not clip at large sizes.

---

## 3. Layout & spacing (Home)
- **20 pt side margins.** No divider lines between rows.
- **Name rows: one line** (secondary text only for exceptional states, §5).
  Row = avatar + room for its ring (~52 pt).
- **Intention rows: ~40 pt pitch** (2026-10-27, revised): the tight look comes
  from the small 13 pt text, not from squeezing rows. The whole pitch is the
  tap target (≥40 pt; close to the 44 pt guideline). Accessibility wins over
  tightness.
- **Tight within a group, generous between groups** (2026-10-27, Gestalt
  proximity): ~4–8 pt from a name to its first intention, intentions on the
  ~40 pt pitch with no extra gap, **~24–28 pt between name groups**; ~24 pt between the community
  card and the list. Each person reads as one unit.
- **Bottom padding** so the last row scrolls fully clear of the floating bar.
- **No chevrons anywhere on Home.** The whole row is tappable. The trailing
  slot stays empty in nav mode; the checkbox fades in there in prayer mode.

---

## 4. Header, bottom bar, search (revised 2026-10-27)
- **Header (left):** your avatar at **~32 pt** (smaller than list avatars, so it
  doesn't compete) with the **streak badge** beside it. Badge = the logo as a
  small wax seal, never a "+" (seal art is a separate upcoming task). States:
  prayed with the list today → seal in today's wax + number; alive but not yet
  today → muted seal + number; zero → muted seal, no number.
- **Header (right): filter** (revised again 2026-10-28):
  - Default: a filter icon.
  - Tap → a **small custom menu anchored to the icon** (styled to the app; must
    keep menu semantics for VoiceOver/TalkBack: announced as a menu, "selected"
    on the checked item, focus moves in, tap-outside/swipe dismiss): *All ·
    Still to hold · Carried*, checkmark on the current one.
  - **Labels** (2026-10-28): "Unprayed today" → **"Still to hold"** (menu and
    chip; translates cleanly, uses the "hold" vocabulary; "today" is taught by
    the midnight reset and the empty state). **"Carried"** stays plain — no list
    number (today's vs tomorrow's list would be ambiguous and the number shifts
    at the flip). **No icons** in the menu (a hollow ring reads as an unchecked
    box).
  - **Counts in the menu only**, right-aligned and muted, on all three (All 12 ·
    Still to hold 3 · Carried 6). When Still to hold reaches 0, show a small
    **gold check** instead of "0". Never on the main screen.
  - **Empty state** for Still to hold: "Everyone's been held today."
  - **Linger then fold:** under Still to hold, rows held in a prayer show their
    gold ring for ~1–1.5 s after Amen, then gently fold away (Reduce Motion:
    fade). No inline chip row (it hid "All" with no scroll affordance and
    put two ✕ buttons side by side). A bottom sheet only if filters grow later.
  - Active filter (anything but All) → **a single chip replaces the icon**:
    `[ Still to hold × ]` with the **× inside the chip**. Tap × → All; tap the
    label → reopen the menu. Neutral active style (ink on `raised`), not blue.
  - Filters remain available in prayer mode.
  - Unprayed filter: a held name with an unprayed intention shows dimmed, with
    the unprayed intention at full strength (keep).
- **Bottom bar — floating pill + separate pray button** (iOS 26 pattern):
  ```
  Normal:     ( History  🔎  ＋ )   ( 🙏 )
  In prayer:  ( 3:12 · with 229    🔎 )   ( Amen )
  Header normal:     [avatar][✱ 6] ………… [filter]  or  [Still to hold ×]
  Header in prayer:  [Cancel] ……………………… [filter]  or  [Still to hold ×]
  ```
  - The pill is fully rounded, translucent/blurred (semi-opaque fallback on
    Android/low-end), ~56–60 pt tall, floating with a small gap from the
    screen edges.
  - The **pray button** is a separate circle of the **same height**, action
    blue, on the **right** (thumb side). No notch/cradle. It becomes Amen with
    the countdown ring in place.
  - In prayer mode the pill becomes the prayer bar in place: elapsed time ·
    "with N" · **🔎 search stays available** (2026-10-28).
  - **Cancel lives in the header, top-left** (2026-10-28): a **text button
    "Cancel"** (not a ✕ — avoids confusion with the filter chip's ×) replaces the
    avatar/streak. No praying-hands icon (the halo already says "praying"). Keeps
    cancel out of the thumb zone next to Amen. **If the prayer is over ~30 s,
    confirm: "Discard this prayer?"**; under that, discard immediately.
- **Search:** 🔎 in the pill opens a search field **docked just above the
  keyboard** (Slack-style); the list filters live behind it. If a prayer starts
  with search active, the field stays, docked above the prayer bar (search
  persists across modes). **Replaces pull-down search.**
  - **Search empty state** (2026-10-28): one quiet line + an add shortcut:
    > Nothing matches "Robe".
    > [ + Add someone ]
    (Revised 2026-10-28: partial queries made "No one named 'Robe' / Add 'Robe'"
    read oddly.) The button opens the add sheet **prefilled with the query,
    cursor at the end**, so "Robe" becomes "Robert" naturally; it's a **name**
    by default (switchable to an intention; normal caps and validation apply).
    Show the empty state only after typing pauses (~500–700 ms) to avoid
    flicker while typing.
    If the query matches **archived** items, show them under "In your archive"
    with a Restore action instead of (or above) the add shortcut. Search
    matches both aliases and real names. In prayer mode, the add shortcut is
    hidden (adding mid-prayer isn't a goal) — show the line only.
  - While the keyboard is up, the bar hides, so the docked row carries a
    **compact pray button** (Amen in prayer mode) at the right end of the
    search field — Pray is never unreachable.
  - Icons in the pill have accessibility labels ("History", "Search", "Add").
  - The prayer bar shows "with 229"; screen readers hear "praying with 229
    others".
- **Pull-down encouragement: DEFERRED.** Later, pulling down may reveal one
  quiet rotating line (faith-neutral by default, brand voice; ~30 lines written
  by Eric). Not in MVP.
- "+" means **Add** and nothing else.
- **The pray button stays action blue** (2026-10-28). A dark button with gold
  hands reads as disabled and puts gold (= held) on an action.

### Scroll edges and glass (2026-10-28, iOS 26)
- **No header slab and no divider line.** The list scrolls beneath the header
  and dissolves into the top of the screen: what's beneath **blurs and dims
  toward the screen's edge**, and is fully sharp again by the header's bottom.
- **The same at the bottom:** a separate edge (~120 pt from the bottom of the
  screen) under the floating bar, so rows dissolve into the bottom too instead
  of hitting the pill.
- **Smooth falloff, no visible start or end.** One eased curve for both blur
  and dim, flat at both ends, bowed so the effect builds early from the inner
  end. The dim fades to the screen's `ground`, not to black.
- **The blur stays slight**: words beneath stay readable, just softened. It
  grows toward the screen's edge (heavier blur nearer the edge).
- **Top and bottom are tuned independently.** The top dims almost fully at
  the screen's edge (under the status bar); the bottom dims less, since the
  floating bar already covers most of it. Values chosen on device and kept as
  tokens (`PPMaterialTokens.topEdge` / `bottomEdge`).
- **Controls float on their own glass:** the streak badge, the filter, the
  pill and the docked search field each sit on a fully rounded frosted shape
  with a hairline edge, so they hold their shape over any row. The pray button
  stays solid action blue. The header's glass matches the ~32 pt header
  avatar. An active filter raises the glass's tint (neutral, never blue).
- **Fallback:** where the blur isn't available (Android, low-end), the edges
  are the dim alone, on the same curve, and glass is semi-opaque.

---

## 5. Rows — mark presence, never absence
- **Remove:** the pink unprayed dot, "Last prayed N days ago", "Prayed today",
  the carried badge on avatars, and all chevrons.
- **Held today = gold:** when you hold someone in prayer, their avatar gets the
  gold ring and **keeps it until local midnight**. Everyone else simply looks
  normal. This is the same signal as checking them in prayer.
  - **Ring spec:** 2 pt ring with a 2 pt gap from the avatar on 40–44 pt
    avatars. **Crisp ring only, both themes — no static glow** (2026-10-27:
    with the bright avatar palette, the glow muddied the edges and cheapened
    the look).
  - **Always solid** (2026-10-24): holding a name is whole, however you prayed
    for them. No dashed/partial ring — the intention dots already show which
    intentions you held. "Partial" exists only as the checkbox state during
    prayer mode.
- **Secondary text only when it means something:** "Answered · Oct 6" (in
  `heldGoldText`), "Not printed on List 53 · {category}. Edit to include it next
  time." Otherwise, no second line.
- The **"Still to hold" filter** still exists; it just isn't painted on rows.
- History and "last prayed" live on the detail page (bead strand).

### Intentions on a thread
- A thin neutral `thread` line drops from the **bottom-center of the name's
  avatar** and curves to each intention (like a prayer strand — the same
  metaphor as the bead history).
- **Intention text is left-aligned with the name text.** No bullets, no icons.
- **Held today:** a small **gold dot (~5 pt)** where the thread meets the
  intention (crisp, solid, both themes — no glow). The thread itself never
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
  with the list **today (your local day)**, the card gets the **same held ring
  as a name** (2026-10-27): 2 pt crisp `heldGold` with a 2 pt gap, outside the
  card's rounded corners, with the same fade and check bloom — tapping the
  card in prayer feels exactly like tapping a name.
  It lights live when the card is checked in prayer mode and clears
  at **local midnight** — the same clock as the streak and the row rings, never
  the flip (a border that survived until the flip would make a user think
  they'd prayed today and break their streak). **Cluster avatars stay plain**
  (no rims — too busy at small sizes).
- **Two groups, two lines:**
  - **Avatar row = yours on today's list** (the list shown on the card). New
    user / not on today's list: no avatar row. Layout (2026-10-27):
    - **Grouped, overlapping avatars first**, then text that begins with names.
      You first, then the user's order. A thin ring in `cardSurface` separates
      overlaps. **At 24 pt, show a single initial** (first letter, ≥11 pt);
      two-letter initials (~8.6 pt) are too small. If a single letter can't
      reach 11 pt, color only.
    - **≤5 people:** show all avatars; text names the first one or two and
      counts the rest — "You and Dad are on List 52", "You, Dad + 3 are on
      List 52".
    - **>5 people:** 4 avatars + a **neutral gray overflow disc "+N"** (N = the
      rest beyond the 4; fill: dark `raisedHigh`, **light `hairline`
      `#D3DAE8`** (white disappears on the light card); `inkMuted` text; same
      separator ring as the avatars). Text names the
      first one or two **without a number** — "You, Dad and others are on
      List 52".
    - **The count appears exactly once** — in the disc when there is one,
      otherwise in the text. Screen readers read every name.
    - **Card text beside the cluster must not wrap awkwardly:** if "You, Dad
      and others are on List 52" doesn't fit beside the avatars, let the text
      run full-width below the cluster rather than breaking "List 52" onto a
      second line next to it.
    - **One shared cluster component everywhere** (card, Amen invitation, Today's
      list, Your portion). Larger contexts (e.g. the invitation) may use
      28–32 pt avatars with initials.
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
- **Card under filters and search** (2026-10-28):
  - **All:** shown.
  - **Still to hold:** shown only if you haven't prayed with the list today;
    once held, it lingers with its gold border then folds away like a row.
  - **Carried:** shown.
  - **Search active:** hidden (results only).
  - **Prayer mode + Still to hold:** same rules — checkable until held, then
    lingers and folds.
- **Carried teaching helper** (2026-10-28): when the Carried view shows only
  you (self name + your free intention) — or, rarely, nothing — show quietly
  below the list (or as the empty state):
  > Carried means printed on the daily list, and held by everyone who prays it.
  > Pray with the list each day to keep them carried.
  > [ Choose who's carried ] → Your portion
  Explains, never sells: no "Upgrade" here; plan limits are handled in Your
  portion.

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
- **Check moment:** a brief gold bloom (~300–400 ms) as the ring/dot appears,
  settling into the crisp ring — motion, not a lasting glow.
- Reduce Motion: replace springs and the bloom with simple fades.

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
- Header right "search + filter" → filter only; search from the pill (docked
  above the keyboard), not pull-down (revised 2026-10-27).
- Footer slab with notched pray button → floating pill + separate pray button.
- Frosted header bar → no bar; scroll edges blur and dim what's beneath at the
  top and bottom of the screen, and controls sit on their own glass (§4).
- Ember "glow" as the check → crisp gold ring/dot (§5); glow only in the
  prayer halo and the transient check bloom.
- Gold rims on community-card cluster avatars → a gold card border, day-scoped (§6).
- Streak badge glyph → the new logo as a wax seal.
- Color rule: blue = action, gold = held, everything else neutral.
- Muted/antique avatar tones → bright avatar palette (§1b).

---

## 11. Future: prayer groups
Direction recorded 2026-10-28 in `groups-design-note.md`: a group is a top-level
row (group picture + name); shared items sit on its thread with the sharer's
small avatar; same gestures, prayers logged to the member's item; any item can be
shared, with a group-facing label chosen at share time and a confirmation of
what the group will see.

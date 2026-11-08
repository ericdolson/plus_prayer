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

## 0. Platforms & fidelity tiers (2026-11-05)
The app is **native on each platform**: **iOS first in SwiftUI** (iOS 26,
Liquid Glass), then **Android in Kotlin + Jetpack Compose** (Material 3)
before public launch. The Flutter build in `app/` is reference only.
Each platform should feel at home on that platform. +Prayer's identity lives in
its custom components, which match across both.

**Tier A — Signature components (custom, must match across platforms).**
This spec gives exact values (sizes, tokens, weights, spacing, timing), and
both apps target them. Tune by eye on both, then update the spec so they stay
in step:
avatars and the held ring · threads and the gold dot · Home row layout and
spacing · the community card (including the avatar cluster) · the streak seal ·
wax seals · the History strand · prayer mode (halo, checks, check bloom) · the pray
button and its countdown · Amen → seal · color roles and tokens · type roles
(Roca for proper names and the list's name, system sans for everything else).

**Tier B — Native chrome (platform component, platform metrics).**
Use the platform's own component and accept its look: menus, popovers,
context menus, sheets, alerts, search field, navigation and tool bars and their
material, **forms and settings-style screens (SwiftUI `Form`: section
headers, footers, text fields, toggle rows with subtitles, navigation rows;
2026-11-06)**, switches, pickers, date pickers, the share sheet, keyboards, the
scroll edge effect, and the platform's symbol set (§9). For these,
the spec defines **content and behavior only**: items, order, labels, copy,
counts, checked/active state, and what each does. It does **not** define padding,
radius, row height or background color. Where a platform can't render a
detail (e.g. system menus are monochrome), the platform wins; don't build a
custom component just to keep a flourish. A custom Tier B replacement needs a
spec decision first.

**Sheets (2026-11-05):** the Amen invitation, the closing sheet and the add
sheet are **native sheets with detents** (Tier B). The signature components
inside them (the countdown button, the avatar cluster, the seal) stay Tier A.

Where it's unclear which tier something is in, ask; don't guess.

**Visual reference:** screenshots of approved screens live in
`docs/product/reference/`. They show intent; **the spec wins when they differ**.

---

## 1. Color system — every color has one job

| Role | Meaning | Used for | Never for |
|---|---|---|---|
| **Blue (brand)** | *Do this* | Pray button, Amen, the invitation's tap target, primary buttons | Status, decoration, toggles, checks |
| **Gold** | *Held* | Ring on held avatars, end-dot on held intentions, prayer-mode halo, "Answered" text, gold rim on carried avatars in the community card after you pray | Buttons, warnings, large fills |
| **Neutrals** | Quiet | Canvas, surfaces, ink (3 levels), threads, icons, switches | — |

- No red, no pink anywhere. No other accent colors.
- Settings switches and other controls are **neutral**, not blue. A
  switch's "on" track is **`inkMuted`** with the standard white knob, in both
  themes and app-wide (2026-11-06: full ink was near-white in dark mode and
  the brightest thing on screen). The **"off" track is much dimmer, `ink` at
  ~14%** (a faint groove), so on and off differ by fill, not just knob
  position; the on track stays `inkMuted` (no brighter). Tokens:
  `switchTrackOn` / `switchTrackOff`. **iOS keeps the native switch**
  (drag, iOS 26 glass knob, future system changes), so there the off track is
  the system's and only `switchTrackOn` applies; `switchTrackOff` applies on
  Android, whose native switch allows it. No custom-drawn switch.

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
| `thread` | `#3A3F47` | `#C3CCDD` | Neutral always. Its own value, a step stronger than `hairline` (`#2A2E35` / `#D3DAE8`), as tuned in the Flutter build (2026-11-05) |
| `unprayedRose` | **delete** | **delete** | The pink dot is gone; remove the token so it isn't reused |
| `inkMuted` | `#9A9EA4` (§1c) | `#566D83` (was `#5C748C`) | Secondary text. Dark 7.1:1 on ground; light darkened to pass 4.5:1 (4.6:1) |
| `inkFaint` | decorative only | decorative only | ~3.7:1 dark, ~2.4:1 light — never essential text. Secondary text uses `inkMuted` |
| `carriedMark` (new, 2026-11-01; revised same day) | `#53585E` (2.7:1) | `#A6B4C6` (1.8:1) | The carried mark (§5): its own value, halfway between `thread` and `inkFaint`. A quiet secondary cue, below 3:1 on purpose (`inkFaint` read too loud); the Carried filter is the reliable way to see what's carried |

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

**Craft:** white initials **at 70% opacity** (`0xB3`; 2026-11-05, was 80%),
so the letters lightly take on the tone. Most tones hold ≥3:1 (large text);
**vermilion and olive drop to ~2.6–2.9:1** at 70% (they were 3.0:1 at 80%),
accepted as tuned in the Flutter build. Tones are roughly Material
600–800 shades, never neon 300s or dull grays. Same palette in light and dark;
in dark mode lower brightness very slightly to avoid glare on the near-black
ground. 12–16 colors, well separated in hue so neighbors rarely match
(`avatarTone` 0–15). **New subjects (2026-11-05):** the add sheet picks the
tone when it opens, from the tones least used among the user's active names
(ties at random), shows it before anything is typed, and writes `avatarTone`
on create; it never changes while typing. The hash of the subject id is only
the fallback for rows with no stored tone. **After launch
the index→color mapping must stay stable** (changing it recolors everyone's
people); changing it now is free.

**Final palette** (2026-10-27; frozen at launch). The starting set, tuned —
berry `#AD1457` → `#9C1450` and teal `#00897B` → `#00876A` to separate them
from raspberry and cyan; olive `#558B2F` → `#5F9133` (lighter to separate it
from green, then darkened just enough to hold 3:1 under 80% initials; ~2.7:1
at today's 70%) — plus
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
- **Serif (Roca)** only for **proper names** (2026-11-08): people's names
  (Home rows, the detail page title, wherever a name is the title) and the
  list's name ("List 52"), plus two ceremonial lines (the splash and the Amen
  invitation). **Everything else is the system sans** in its native weights
  and sizes, including section titles on detail pages ("Intentions",
  "History") and intention titles.
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
- **Sans page roles** (tokens, 2026-11-08): `type.sectionTitle` (Title 3
  semibold: "Intentions", "History"), `type.intentionTitle` (Title 2
  semibold: an intention page's title), `type.periodLabel` (Headline: a
  History period's label).
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
  ~40 pt pitch with no extra gap, **~24–28 pt between name groups**
  (2026-11-05: the visible gap, from the last row's text to the next avatar;
  rows' own padding counts toward it, and the last intention in a group
  doesn't add the 40 pt pitch's empty space below it, though its tap target
  still reaches 40 pt); ~24 pt between the community
  card and the list. Each person reads as one unit.
- **Bottom padding** so the last row scrolls fully clear of the floating bar.
- **Bare glyph buttons in the content** (the ＋ on a page's Intentions title)
  get a 44 pt tap target: `size.hitTarget`.
- **No chevrons anywhere on Home.** The whole row is tappable. The trailing
  slot stays empty in nav mode; the checkbox fades in there in prayer mode.

---

## 4. Header, bottom bar, search (revised 2026-10-27)
- **Header (left):** your avatar at **~32 pt** (smaller than list avatars, so it
  doesn't compete) with the **streak badge** beside it. Badge = **a neutral
  pewter seal** (2026-11-01, revised same day): the same stamp shape as
  `WaxSeal`, unwaxed, tinted `inkMuted` with its relief shading so it reads as
  a pressed seal (not the flat ink carried mark, §5), ~22 pt. **Never gold,
  never a wax color** — wax color belongs to a list, not to you. **The number
  carries the state:** prayed with the list today → number in `ink`; alive
  but not yet today → number in `inkMuted`, seal one step dimmer; zero → dim
  seal, no number. Why neutral: the badge clears at local midnight but the
  list's wax changes at the flip, so a colored badge is wrong for part of
  every day; and the card's gold border already says "prayed today".
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
  - **Counts in the menu only**, on all three, **in the item's title**
    (2026-11-05, native menu, Tier B §0): "All · 12", "Still to hold · 3",
    "Carried · 6". Never on the main screen.
  - **Never show 0** (2026-11-05): at 0 the count is dropped and the title is
    the bare label ("Carried"). No check either (in a system menu the check
    means "the active filter").
  - **Still to hold at 0** also carries the subtitle **"Everyone's been held
    today."** No other item gets a subtitle.
    _Was: trailing muted counts, and a small gold check in place of "0"._
  - **Empty state** for Still to hold: "Everyone's been held today." (the same
    line as the menu's subtitle at 0).
  - **Linger then fold:** under Still to hold, rows held in a prayer show their
    gold ring for ~1–1.5 s after Amen, then gently fold away (Reduce Motion:
    fade). No inline chip row (it hid "All" with no scroll affordance and
    put two ✕ buttons side by side). A bottom sheet only if filters grow later.
  - Active filter (anything but All) → **a single chip replaces the icon**:
    `[ Still to hold × ]` with the **× inside the chip**. Tap × → All; tap the
    label → reopen the menu. Neutral active style (ink on `raised`), not blue.
  - Filters remain available in prayer mode.
  - Unprayed filter: a held name with an unprayed intention shows dimmed, with
    the unprayed intention at full strength (keep). Dimmed = 55% opacity
    (`number.contextRow`, Flutter's value; 2026-11-05).
- **Bottom bar — floating pill + separate pray button** (iOS 26 pattern):
  ```
  Normal:     ( History  🔎  ＋ )   ( 🙏 )
  In prayer:  ( 3:12 · with 229    🔎 )   ( Amen )
  Searching:  ( 🔍 dad          ✕ )   ( 🙏 )     ← keyboard up: both at 52 pt
  Header normal:     [avatar][✱ 6] ………… [filter]  or  [Still to hold ×]
  Header in prayer:  [Cancel] ……………………… [filter]  or  [Still to hold ×]
  ```
  - The pill is fully rounded, translucent/blurred (semi-opaque fallback on
    Android/low-end), **62 pt** tall (2026-11-05, was ~56–60), floating with a
    small gap from the screen edges.
  - **Tier (2026-11-05):** the pill and pray button are **Tier A in layout**
    (our arrangement and sizes) on the **platform's glass material** (iOS 26
    Liquid Glass).
  - The **pray button** is a separate circle of the **same height**, action
    blue, on the **right** (thumb side). No notch/cradle. It becomes Amen in
    place after the countdown.
  - **Countdown (2026-11-06; replaces the decaying ring):** during the ~5 s
    minimum the disc dims (`number.prayButtonDim`) and a **small pie inside
    it** (`number.countdownPie`, 0.4 of the diameter, action blue) runs down
    to nothing, its edge moving clockwise from 12 o'clock; then it fades
    into **Amen**. No ring outside the button and no change in size: the
    motion stays at the center (App Store download progress, Dynamic Island
    timer). Reduce Motion: the pie steps once a second. The Amen invitation's
    button is the same component (prayer-flow.md).
  - In prayer mode the pill becomes the prayer bar in place: elapsed time ·
    "with N" · **🔎 search stays available** (2026-10-28).
  - **Cancel lives in the header, top-left** (2026-10-28): a **text button
    "Cancel"** (not a ✕ — avoids confusion with the filter chip's ×) replaces the
    avatar/streak. No praying-hands icon (the halo already says "praying"). Keeps
    cancel out of the thumb zone next to Amen. **If the prayer is over ~30 s,
    confirm: "Discard this prayer?"**; under that, discard immediately.
- **Search reuses the bar (2026-11-06; replaces the docked search row):** 🔎
  turns the **pill's own glass into the search field** (🔍 · text · ✕); the
  list filters live behind it. The **pray button stays its own circle beside
  it**, never inside the field. With the keyboard up, both **ride above it at
  a compact 52 pt** (`size.bar.compact`, from 62) with a small gap; with the
  keyboard down they return to full height. With text, the pill stays the
  search field (even with the keyboard down) until **✕**, which clears the
  query and morphs it back to History · 🔎 · ＋; left empty, it closes when
  the keyboard goes. Search persists across modes. **Replaces pull-down
  search.**
  - **In prayer** the field takes the prayer bar's place while searching, so
    the timer and "with N" are hidden until ✕: focus is on finding someone,
    and the halo and Amen still say you're praying (open-questions D6).
  - **Tier:** our layout (Tier A) on the platform's glass, matching the iOS 26
    tab bar's own search morph; everything inside the field is native.
  - **Search empty state** (revised 2026-10-29): **one layout for every
    no-results case** — one quiet line + one blue add button:
    > No matches for "Robe"
    > [ + Add ]
    - The line is **always one line** (17pt system sans, secondary). If the
      query is long, truncate the **query** with "…", never wrap the sentence.
    - **[ + Add ]** is blue (action) and the only primary, in every case. The
      label stays type-neutral ("+ Add someone" read as people-only; echoing
      the query was rejected 2026-10-28 for partial queries). It opens the add
      sheet **prefilled with the query, cursor at the end**, so "Robe" becomes
      "Robert" naturally; it's a **name** by default (switchable to an
      intention; normal caps and validation apply).
    - **Live, like the rows (2026-11-06):** the empty state shows as soon as
      nothing matches and its line follows the query as you type; it's never
      hidden and shown again while nothing still matches. (Was: wait for
      typing to pause, ~500–700 ms.)
    - **Filter hiding matches:** if a filter is active and the query matches
      under **All**, add **one match hint** below the button: a flat
      **`cardSurface`** container (not glass — it's content, not a floating
      control; see "Glass vs. surface" below), radius ~16 pt (not fully
      rounded, so it never reads as a field or pill), no border/shadow/blur,
      one line:
      > 1 match in All            Show →
      Count + label in secondary; **"Show →"** in blue. The **whole container
      is the tap target** (one action; "Show →" is the visible affordance),
      with a subtle pressed state, exposed to accessibility as one button
      ("Show 1 match in All"). Tapping clears the filter (→ All) and keeps the
      query. Show the count, not the rows (the Gmail/Slack "widen the scope"
      pattern; keeps the screen calm).
    - **Nothing matches anywhere:** no card and **no "Clear filter" link**
      (clearing can't help; the filter chip's ✕ already clears it).
    - No "or" separator, no second big button.
    If the query matches **archived** items, show them under "In your archive"
    with a Restore action instead of (or above) the add shortcut. Search
    matches both aliases and real names. In prayer mode, the add shortcut is
    hidden (adding mid-prayer isn't a goal) — show the line only.
  - Pray is never unreachable: the pray button (Amen in prayer) rides above
    the keyboard beside the field.
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
- **iOS (2026-11-05): Tier B.** Use the platform's soft scroll edge effect
  (iOS 26), not a custom blur and dim; the tuning above doesn't apply. The
  curve and values above remain the reference for the Android dim fallback.
- **Controls float on their own glass:** the streak badge, the filter, the
  pill (also the search field) each sit on a fully rounded frosted shape
  with a hairline edge, so they hold their shape over any row. The pray button
  is the same interactive glass **tinted action blue** (2026-11-05, was solid
  blue: a rigid disc felt dead beside the glass that gives under the finger);
  it still reads as solid blue, never gold. Your **header avatar** (→ You) is
  the same interactive glass tinted with your avatar tone (2026-11-05), the
  initials on it as on any avatar. The header's glass matches the ~32 pt header
  avatar. Avatar and streak badge sit **8 pt (`sm`) apart** (2026-11-07): two
  separate controls, so they read as two pieces. On iOS they share one glass
  container (spacing = the gap), so they blend only while one is pressed.
  Android keeps the 8 pt gap; Material has no shared glass, so no blend. An active filter raises the glass's tint (neutral, never blue).
- **Glass vs. surface (2026-10-29):** glass is only for **controls that float
  over content** (streak badge, filter, pill and its search field). Anything
  that **lives in the content** and scrolls or sits with it (community card,
  search match hint, future in-content cards) is a flat **`cardSurface`**,
  never glass. Fully rounded capsules are reserved for the floating controls;
  in-content containers use a softer radius.
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
    avatars. **Scales in steps, not proportionally** (2026-11-08; a
    proportional ring at 96 pt is ~4.5 pt and heavy): up to ~32 pt →
    1.5 / 1.5; 40–44 pt → 2 / 2; ~96 pt (detail page, add sheet) → 3 / 3
    (ring / gap). One token per step (`size.held.ringSmall` /
    `ringGapSmall`, `ring` / `ringGap`, `ringLarge` / `ringGapLarge`); the
    History strand's node ring follows its own size (history.md).
  - **History strand** (history.md, 2026-11-08; replaces the calendar
    tokens): node disc ~30 in a 44 tap area, bloom ~19 at ~55% opacity,
    note dot on the corner; exact tokens set at build. **Crisp ring only, both themes — no static glow** (2026-10-27:
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
- History lives on the History screen (history.md); the detail page has a preview.

### Carried mark (2026-11-01)
A tiny neutral glyph **after** every carried name and intention, so a long
list shows at a glance what goes on the printed list.
- **Meaning = carried**, the same set the Carried filter shows: the owner chose
  it for the list (an intention's mark = chosen to print ∧ its person
  carried; Q32). It is
  **not time-indexed**: no "on List 52" vs "staged for List 53" per row. The
  gate is per user, so the community card owns timing ("Pray to carry them
  onto List 53" / "They'll be on List 53", "Mom joins you on List 53"); the
  History screen owns history. The mark does not change when the
  user prays or lapses.
- **Name carried, intention not:** the name has the mark, the intention
  doesn't. An intention can't be carried without its name, so the mark never
  appears on an intention under an unmarked name.
- **"Me" is marked too** — always on, which is how the glyph is learned.
- **Absence is never marked:** private items simply have no mark.
  **Exception (2026-11-07): a subject's own detail page** may state "Not on
  the list", because it's where that subject is managed directly (its carry
  row and "Make room" live there). Home, lists and every other surface still
  never mark absence.
- **In the add sheet's carry row** (2026-11-06) the same flat glyph trails
  the "Carry onto the list" label at ~15 pt, `inkMuted` in every state,
  centered on the label's cap height: louder than on rows because it
  appears once and teaches the mark, placed exactly as on rows (trailing).
  It sits inside the native toggle's title (the add sheet is a native form).
- **Glyph (for now):** the same logo glyph the streak badge used
  (`assets/img/+prayer_icon.svg`, the bloom with the "+" cut out), as a flat
  neutral silhouette — no wax, no sheen. Later: a dedicated bloom without the
  "+" (Eric to draw; see open-questions D1).
- **Placement:** trailing, inline with the text (an inline span, so it never
  wraps alone onto its own line; with single-line truncation it follows the
  ellipsis). The leading slot stays the gold held dot.
  - Intentions: ~9 pt glyph after the 13 pt text, 4 pt gap, centered on the
    x-height.
  - Names: ~11 pt glyph after the Roca name, 6 pt gap, centered on the
    x-height.
- **Color:** `carriedMark` (neutral, never gold, never blue): a background
  mark like the thread, a step above it, below `inkFaint`. Below 3:1 on
  purpose: a secondary cue you notice when you look, not a signal you scan
  for; the Carried filter (and the ", carried" label) is the reliable path.
- **Accessibility:** append ", carried" to the row's label.
- **Teaching:** the same glyph appears in the Your portion preview and the
  Carried teaching helper (§6).
- **One symbol, two materials** (2026-11-01): the bloom is the only brand mark
  on Home. **Ink** (flat, neutral) = carried, "this will be printed" — rows.
  **Wax** (the bloom pressed into the day's wax) = sealed, an event — the
  community card's seal (and Today's list). The streak badge is the same
  seal **unwaxed, in pewter** (§4). The record of an item having
  been on lists is History's Days strand, in ink blooms; its Lists tab
  shows each list with its wax (history.md). Rows
  never wear wax: on paper each name is printed in ink and the whole sheet
  gets one seal, and the carried mark is a standing promise, not a dated
  record.

```
 (EO)  Me ✻
   ╰── Patience with the new job ✻
 ((D)) Dad ✻
   ╰─● Healing after his surgery ✻      ● = held today (gold)
   ╰── Rest for his heart               (private: no mark)
```

### Intentions on a thread
- A thin neutral `thread` line drops from the **bottom-center of the name's
  avatar** and curves to each intention (like a prayer strand).
- **Intention text is left-aligned with the name text.** No bullets, no icons
  — except the trailing carried mark (§5).
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
pt, generous padding (~16–20 pt; **bottom padding equals top**, ~20 pt). Clearly different from the rows; it is the
value of the app.

**Redesigned 2026-11-02** (was seven lines). The card answers two questions
at a glance: **is the list alive?** (the world) and **are my people going onto
the next list?** (you — the one thing you can act on). Everything else lives
on Today's list or Your portion.

```
╭───────────────────────────────────────────╮  gold border when you've
│▓▓▓▓▓▓   List 52                           │  prayed with the list TODAY
│▓ seal ▓  4,345 people · 3,881 prayers     │  ← the world
│▓▓▓▓     ● 239 praying now                 │
│         (stamp ~65% visible, cropped      │
│          into the top-left corner)        │
│ (E)(D)(M)(D)(A)(R)(J)(K)(L)(B)            │  ← you: carried people,
│ Pray to carry them onto List 53           │    full width, status below
╰───────────────────────────────────────────╯
```

### The stamp — large, cropped into the corner
- The day's seal at **110 pt**, clipped by the card's inner radius so
  **~70% is visible** (revised twice 2026-11-02: ~88% wasn't decisive; the
  −36/−32 build hid too much). **Tune by outcome, not offset:** tuned on
  device to **−23 pt left / −15 pt up** (2026-11-05, was ~104 pt at
  −24/−20); the whole bloom center and most petals must be
  visible, with only the outer wax and petal tips cropped and the wax runs into the rounded
  corner. It is the card's anchor and its distinctive mark; the crop hints
  there's more inside (Today's list shows the full seal uncropped).
- Keep the **impressed bloom readable inside the visible portion**: render
  the wax body and the impression as **separate layers** — the body crops into
  the corner, the bloom is centered on the *visible* part. Stopgap until then:
  a smaller offset. The D2 stamp art should be delivered as body + impression
  layers for this reason. **Until D2** (2026-11-02): the impression is baked
  into the stamp image; the ~70% target above already keeps the bloom
  readable.
- **Unsealed ("being filmed") state** (2026-11-02): no dashed ring, no "+"
  (the circled "+" is retired). Render the same seal shape as an unpressed
  neutral blank — the existing **`unsealed` token** body (dark `#30353D`,
  light `#C9D1DF`; purpose-named, keep it) with the same relief shading — with
  the bloom faintly debossed, as if waiting for wax. **Until D2:** use the
  stamp image's own impression (with its small "+" and inner ring) rendered
  in this neutral; the "+"-free bloom arrives with the stamp art
  (open-questions D1/D2).
- The Amen stamp moment lands here.
- **Photographed seals (PLANNED 2026-11-02 — Eric will shoot them):** at
  large sizes (≥ ~40 pt: community card, Today's list, Amen invitation) the
  seal becomes a **real macro photo** of each weekday's stamp, cut out as a
  transparent image, bundled in the app (one per `sealVariant`). Vectors stay
  for small sizes (the pewter streak badge). `WaxSeal` keeps its API
  and picks photo vs vector by size. It is the only photographed thing in the
  UI. Later, the day's own seal from the ritual can replace the set.
  - **Shoot guide:** all 7 in one session; same soft light from the upper
    left (matches the code's sheen), same lens, height and pour size; gray
    card for white balance.
  - **Pour for the crop:** spread the wax toward the upper left and press the
    stamp slightly low-right of center, so the corner crop takes wax, not
    petals (no layered art needed for photos).
  - **Cutout:** clean edge, no baked drop shadow (add a contact shadow in code
    if needed) so it sits on light and dark cards.
  - **Unsealed:** photograph a blank unpressed pour in a neutral wax
    (preferred over mixing a vector blank with photo seals).
  - **Amen moment:** crossfade unsealed → sealed photo with a small scale
    settle.
  - **Assets:** ~330 px square (104 pt @3×), WebP/PNG with alpha, ~50–150 KB
    each.
  - Real wax highlights should separate dark waxes on their own; the dark-theme
    rim/lift below may then be dropped for photos (judge on device).
- **Dark-theme wax separation** (2026-11-02): the ritual's waxes are mostly
  dark (navy, deep red, garnet, green, brown) and sink into `cardSurface` in
  dark mode. In **dark theme only**, give the stamp a ~1 pt **rim light along
  its visible edges** (the wax's sheen color, partial opacity) and allow a
  modest per-theme lift of the body color so the silhouette separates from the
  card. The wax names and light-theme colors stay true to the physical wax.
  - **Scope:** part of the `WaxSeal` component (theme-aware), so it applies
    wherever a seal sits on a dark surface — card, Amen invitation, Today's
    list. Below ~24 pt the lift applies but no rim.
  - **Rim:** an even rim (outline copy behind the seal) is fine for now, kept
    subtle; a directional rim on the lit edge comes with the layered D2 art.
  - **Lift only waxes that need it:** Sunday's gold gets no lift (it already
    separates, and lifting pushes it toward the gold held border).
  - **Unsealed blank:** no lift (it isn't wax), but give it the same subtle
    rim in a lighter neutral so it separates from `cardSurface`.
- **Check before committing:** the 7 wax colors at this size (a wax close to
  action blue could read as a button — deepen/desaturate it if so), and the
  gold held border beside non-gold wax in both themes.
- Decorative for screen readers; the card's label carries "List 52, sealed".

### The world block (beside the stamp)
- **Three left-aligned lines beside the stamp** (revised 2026-11-02: the
  right-aligned marker in the title row floated on a different baseline and
  broke the column): "List 52" (Roca) → counts → **presence**: "● 239 praying
  now" (live dot, `inkMuted` text), filling the space beside the stamp. Display ladder unchanged (live ≥10 → last hour ≥10 → today ≥10 →
  hidden; never 0). **Lower rungs have no dot** (the dot means *now*) and
  keep their verb: "640 prayed this hour", "4,113 prayed today"; screen
  readers hear the long forms. If the line doesn't fit whole, hide it — never
  truncate a number.
  **In prayer mode the marker hides** (the pill already shows "with N").
- **Counts row:** "4,345 people · 3,881 prayers" — **words, not icons**
  (icon + number reads as engagement metrics; the praying hands stay a verb).
  Numbers in `ink` with tabular figures, labels in `inkMuted`, a thin middle
  dot with a little extra space. The prayer count matters: everyone on the
  list is held by every prayer for it. When it rises live, **crossfade only the
  changed digits** (no rolling counter — Amen → seal stays the one signature
  motion).
- No intention count on the card (Today's list has the full breakdown).

### The you block (full width, below)
- **Avatar row = your carried people** (who goes onto the next list): you
  first, then the user's order; intentions have no avatars. **Always shown**
  (2026-11-02) — you are always carried, so a new user or someone who skipped
  yesterday still sees at least their own avatar. It is not "who was on
  today's list". **Fill the card's
  width**; add the neutral **"+N" overflow disc only when the faces don't
  fit** (measured, not a fixed cap). **28 pt avatars** (2026-11-02, up from
  24 — too small beside the 44 pt rows), **the same initials as that
  person's row avatar** (2026-11-02: "DK" for Daniel Kim, "D" for Dad, "EO"
  for you — single initials made Dad and Daniel identical, and matching the
  rows aids recognition); text ~11–13 pt, never below 11 pt (else color only), thin `cardSurface` separator ring on
  overlaps. **Overlap ≤ ~4–5 pt** (2026-11-02) so two-letter initials are
  never covered by the next avatar — the full-width row has the room. Overflow disc: dark `raisedHigh`, light `hairline` `#D3DAE8`,
  `inkMuted` text. Screen readers read every name. **Cluster avatars stay
  plain** (no rims).
- **Status line below the avatars**, **~6–8 pt** under them so faces and
  sentence read as one unit (the larger gap sits above the avatars, between
  the two blocks). **Weight follows state** (2026-11-02): not yet covered →
  `ink` (the one actionable thing); covered ("They'll be on List 53" /
  "You'll be on List 53") → `inkMuted` (done; the gold border celebrates). With a single
  avatar (e.g. free user, only you) the status may sit beside it instead.
  Computed from the real gate:
  - qualifying prayer for the next list exists → "They'll be on List 53"
    (+ small seal stamp at Amen — part of the signature moment);
  - prayed with the list today but the next list isn't covered yet (some
    time zones after the flip) → "Your next prayer carries them onto List 54";
  - not prayed → "Pray to carry them onto List 53".
  **Only you carried** (new user, or no one else carried): "Pray to be on
  List 53" → "You'll be on List 53"; after-flip case "Your next prayer puts
  you on List 54".
- **Long text / large type** (2026-11-02): never shrink text below the user's
  size. The status line **wraps as needed, no line cap** (two or three lines at
  the largest sizes; meaning beats line count; never "…" mid-sentence),
  keeping "List 53" unbroken. The counts row wraps at the middle dot (people /
  prayers on separate lines). The presence line hides first. **The world block
  moves below the stamp when the title or either count can't fit on one line
  beside it.**
- **Closing notice replaces the status line** (doesn't add one), only if you
  haven't prayed with the list today: "List 52 closes in 5 min · pray to carry
  them" (only you carried: "List 52 closes in 3 min · pray to be on List 53").
  No clock icon.
- **Removed from the card (2026-11-02):** the "You, Dad and others are on
  List 52" line (the avatars show who; who was on today's list lives on Today's
  list) and the **differences lines** ("Mom joins you…", "Aunt Bea isn't
  carried…") — the carried mark on rows (§5) now shows this; changes are
  named in **Your portion** only. (Correction 2026-11-02: the Amen invitation
  appears only when a prayer ended without the list and states who will be
  carried; it does not name changes.)
- **No extra "you held this list yesterday" icon or count** (2026-10-24).

### Card behavior
- **Held = the card's border, not the avatars** (2026-10-24): when you've prayed
  with the list **today (your local day)**, the card gets the **same held ring
  as a name** (2026-10-27): 2 pt crisp `heldGold` with a 2 pt gap, outside the
  card's rounded corners, with the same fade and check bloom — tapping the
  card in prayer feels exactly like tapping a name.
  It lights live when the card is checked in prayer mode and clears
  at **local midnight** — the same clock as the streak and the row rings, never
  the flip.
- **Never break "List" from its number:** use a non-breaking space ("List 53")
  everywhere.
- **Tap → Today's list.** **In prayer mode the whole card is the checkable
  "hold the list" target.** The checkbox sits in the trailing slot **aligned
  to the "List 52" title line** (2026-11-02), as a row's checkbox aligns to
  its name. The baseline issue that moved presence was about text; a control
  in the trailing slot is consistent with rows.
- **Presence:** shown here to *invite*; prayer mode reveals more as the reward
  (the count moving live in the pill; later, richer presence such as countries).
- **Shared cluster component:** the card uses its full-width fill mode (28 pt
  avatars); other contexts use their own layouts with **24 pt** avatars
  (Today's list, Your portion) or **32 pt** (the Amen invitation)
  (2026-11-05, was 28–32). They overlap **~4 pt**, as on the card, so
  two-letter initials are never covered (`size.cluster.overlap`). The
  invitation's seal is **~56 pt** (`size.seal.invitation`, Flutter's value).
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
- **Halo = a solid edge line + a glow** (2026-11-05, as in the Flutter build):
  a steady **2 pt** gold line on the screen's very edge says "holding"; the
  glow over it only accents it. Only the glow breathes and flares; the line
  just fades in and out with the session.
- **Halo behavior** (2026-11-03): it frames the session and is not a second
  signature motion.
  - **Enter/exit:** fades in over ~400 ms when the prayer starts; fades out
    over ~400 ms on ✕ cancel, Discard, or when the session ends. **Session end
    = any Amen that commits the prayer** (the FAB Amen, the invitation's Amen
    when the list invitation appears, or the welcome-back Amen). The halo stays
    on through the invitation. The closing phase (closing sheet, Still-to-hold
    fold) is **not** held back: it starts at once and the flare + fade play
    beneath it.
  - **At rest:** the line is steady; the glow breathes, slow but discernible
    (2026-11-05: ~5 s cycle, glow opacity ~0.4 ↔ 1.0; was ~8 s at 0.65 ↔ 0.85,
    too quiet to see). No moving, rotating or multicolor gradient (that reads as
    Siri).
  - **Amen flare** (committing Amen only): ~500 ms, opacity → ~1.0 (0.99 is
    fine) and glow reach ~1.3× the resting reach. Shape: fast rise (~150 ms,
    ease-out), slower settle (~350 ms, ease-in-out). Sequence: flare → then the ~400 ms
    fade-out (the fade waits for the flare). Starts at the Amen tap for now;
    when the seal-stamp animation exists, retime it to the stamp's impact
    (keep the start a single tunable offset).
  - **Inner glow kept tight:** at rest, the visible glow reaches ≤ ~12 pt in
    from the screen edge (inset + stroke + blur falloff, not blur radius
    alone), so it doesn't muddy the corners behind the prayer pill and Amen
    button. The flare may exceed this briefly.
  - **Reduce Motion:** fully static, the glow at opacity ~0.7 (no breath, no flare);
    enter/exit stay as simple fades.
- Checkbox fades into the trailing slot of every row and the community card.
  **Checked = gold ring on the avatar / gold dot on the intention**, applied
  live.
- Pray button → countdown (the pie inside it) → **Amen** stays **blue** (action).

---

## 8. Motion — one signature moment
- **The signature:** Amen → the seal. That's the one big moment; give it the
  care.
- **Checks:** a small spring on the check + the gold ring/dot fading in, plus a
  light haptic. This is the only place a bounce/spring is used. The spring is
  **420 ms on an ease-out-back curve** (`cubic-bezier(0.175, 0.885, 0.32,
  1.275)`, a small overshoot), as tuned in the Flutter build (2026-11-05).
- Everything else (navigation, sheets, filters) is quiet and quick.
- **Check moment:** a brief gold bloom (~300–400 ms) as the ring/dot appears,
  settling into the crisp ring — motion, not a lasting glow.
- Reduce Motion: replace springs and the bloom with simple fades; the prayer
  halo is fully static (§7).

---

## 9. Icons (revised 2026-11-05)
- **The platform's own symbol set at a light weight**: SF Symbols on iOS,
  Material Symbols Outlined (light weight) on Android. Native chrome (menus,
  toolbars, search, swipe actions) renders them natively, and they track text
  weight and Dynamic Type.
- **Custom glyphs are drawn as platform symbols** to match: the praying hands
  and the bloom (carried mark) become custom SF Symbols on iOS and vector
  drawables on Android.
- One family per platform; no mixing (no Phosphor beside SF Symbols, no
  rounded Material icons on iOS). _Was: one thin-line family (e.g. Phosphor
  Light) on both platforms._

---

## 10. What this supersedes in `app-brief.md` and the spec
- "Rows: title + one secondary line" → secondary text only for exceptional
  states (§5).
- "Unprayed dot (POC pink)" → removed; presence is marked with gold instead.
- "Small mark if carried on the next list" on rows → removed 2026-10-23,
  **restored 2026-11-01 in a new form**: a trailing neutral carried mark that
  means "carried", not "on the next list" (§5).
- "Rows' `>` becomes a checkbox" → no chevrons; the checkbox fades into the
  empty trailing slot.
- "Pinned list row" → the community card (§6).
- "Presence line" above the list → inside the card.
- Header right "search + filter" → filter only; search from the pill (the
  pill becomes the field, riding above the keyboard beside the pray button;
  revised 2026-11-06), not pull-down.
- Footer slab with notched pray button → floating pill + separate pray button.
- Frosted header bar → no bar; scroll edges blur and dim what's beneath at the
  top and bottom of the screen, and controls sit on their own glass (§4).
- Ember "glow" as the check → crisp gold ring/dot (§5); glow only in the
  prayer halo and the transient check bloom.
- Gold rims on community-card cluster avatars → a gold card border, day-scoped (§6).
- Streak badge glyph → a neutral pewter seal (`WaxSeal` shape, unwaxed,
  2026-11-01); the logo glyph moves to the carried mark (§5).
- Color rule: blue = action, gold = held, everything else neutral.
- Muted/antique avatar tones → bright avatar palette (§1b).

---

## 11. Future: prayer groups
Direction recorded 2026-10-28 in `groups-design-note.md`: a group is a top-level
row (group picture + name); shared items sit on its thread with the sharer's
small avatar; same gestures, prayers logged to the member's item; any item can be
shared, with a group-facing label chosen at share time and a confirmation of
what the group will see.

# Onboarding D — merged mock, notes

_2026-11-09. Mock: `index.html` (serve the repo root over http). Review links: `?step=moment&fill=1`, `?step=someone&fill=1`, `?step=home&fill=1&light=1`, `&ground=dawn|candle|bluehour|lamp`, `&rm=1`._

## Flow (as briefed)
1. **Your name** — "Here, we pray for each other." (Roca 400) · "What's your name?" · field (sans; placeholder *Your name*) · Continue lit once there is text · `Sign in` top-right → native sheet (Apple / Google / Not now). No keyboard on arrival; tapping the field raises it and Continue rides up above it.
2. **The moment · the mechanic** — the typed name becomes Roca in place, the avatar forms above it (fade + scale from 0.72 + a settling blur; no letters flying), the name settles onto the *List 53* paper line (stand-in for a photographed line of the real list), then: "Pray with today's list. Tomorrow your name is on it." · "The list is printed and sealed each day, and kept private." · Continue. No seal: it waits for the first Amen on Home.
3. **Someone you pray for** — "Who do you pray for?" · **Name** / *e.g. Julie Olson* / Printed on the list · **What you call them · optional** / *e.g. Mom* / Only you see this · Continue (lit once there is a name) · `Not now` top-right → hand-off. Their avatar forms as they type (initials from the alias once there is one). Your own avatar sits small at the top as the anchor.
4. **Their intention** — only Mom: her avatar travels up from the fields and "Mom" (Roca 700) settles under it · "What are you praying for, for Mom?" · "A request: healing, a new job, peace. It can print with their name." · field *e.g. Healing after surgery* · Add / `Skip` top-right.
5. **Hand-off to Home** — the ground dissolves to `#0E1012` (or `#E9EEF9` with Light Home on), your avatar travels to the header slot, Mom's avatar travels into her row, the card fades in with its seal, the rows and the pill follow, and the blue button becomes the pray button last. Card status: "Pray to carry you and Mom onto List 53" / "Pray to be on List 53". No tour, no line.

Corners are fixed slots on every step: `‹ Back` top-left (steps 2–4), the quiet action top-right (Sign in / Not now / Skip). Keyboard-up layouts are shown on 1 (after tap), 3 and 4, with the button at a fixed slot above the keyboard (top 478) and never under a field.

## Grounds (switcher outside the phone; the ink is Home's `#E8EAED` / `#9A9EA4` on all four, so warmth comes from light, not hue)

| # | Name | Values | Reads as |
|---|---|---|---|
| 1 | **Dawn** | `#0A0F1B → #0F1524 → #161A26` top to bottom, plus a faint amber glow low on the screen (`rgba(214,160,84,.22)` at 50%/104%, gone by 72%) | the light of tomorrow, under the mechanic's words. Risk: the only one with a gradient; kept faint so it never reads as a wellness app. |
| 2 | **Candlelight** | `#0E1012` (Home's ground) + a living glow behind the stage (`rgba(226,196,140,.16)` ellipse at 50%/38%, breathing 0.72 ↔ 1 over 6.4 s with a 6 pt drift; static at 0.85 under Reduce Motion) | the room where the list is made, lit by one flame. The hand-off is just the flame going out: Home is the same room. |
| 3 | **Blue hour** | flat `#10182A` | quiet and expensive; the plainest. The hand-off is a temperature shift (blue → neutral). |
| 4 | **Lamp** | `#0E1012` lit from above by a soft warm-white (`rgba(242,235,223,.13)` ellipse at 50%/−6%), the faintest answering light at the bottom edge | a desk lamp over the table; light rather than color, Home's own ground. |

**My pick: Candlelight (2).** Warmth from a light source, on Home's own ground, so the hand-off is believable in both appearances (dark: the glow fades; light: the dissolve brightens from the same neutral). Lamp (4) is the runner-up and the calmest; Dawn (1) is the most beautiful still frame but the hardest to keep off "gradient app". Blue button on all four: `#0580F9` against the darkest ground is ≥ 3.4:1 (shape); the white label is 3.8:1, which the token sheet accepts for large/semibold labels (design-direction §1); if 4.5:1 is required for the label, use `#0573E0` with a 17 pt semibold label on the light Home only, or darken the pill's text to the ground color on light.

## Motion spec

| Transition | What moves | Timing |
|---|---|---|
| Step change (all) | outgoing lines fade and rise −8 pt; incoming fade in from +12 pt, 60 ms stagger, starting 140 ms after | 240 ms ease-in out, 320 ms ease-out in |
| Anchors (avatar, Mom's avatar, the name) | travel position and size together | 600 ms ease-in-out |
| The one blue button | position / width / radius; label crossfade | 420 ms ease-in-out; 160 ms |
| Keyboard | rises/falls; the button rides to its above-keyboard slot in the same beat | 320 ms ease-out |
| **The moment** (step 2) | t0 field text → same text in Roca (opacity crossfade of two faces, same position); t+380 avatar forms (opacity, scale .72 → 1, blur 4 → 0, 480 ms); t+1000 paper rises (+14 pt, 320 ms); t+1120 name travels onto the paper, shrinking 28 → 22 and taking the paper ink (600 ms); t+1650 the two lines arrive | ~2.3 s total, no haptic (the first haptic belongs to the first Amen) |
| Step 3 → 4 | your avatar fades; Mom's avatar travels from above the fields to the anchor slot (center y 140); "Mom" rises in beneath at 300 ms | 600 ms |
| **Hand-off** | ground dissolve 700 ms; your avatar → header slot (600 ms); Mom's avatar → her row (600 ms, from 120 ms), then hands over to the row's own avatar; header / card / rows / pill fade-rise in with 90 ms stagger from 420 ms; the button morphs into the pray button from 700 ms, its glyph at 1000 ms | ~1.5 s |
| **Reduce Motion** | every transition is a 160 ms opacity fade; no travel, scale or blur; the candle glow and the lamp are static; keyboard and sheet fade; beats compress to ≤ 200 ms | |

## Type roles
- `ob.lead` — Roca **400** 30/38 (`sm` 26/33): the one big line per step. Never bold.
- `ob.name` — Roca 700: the user's name after the moment (28), Mom as the anchor (24), 22 on the paper line.
- `ob.question` — SF 17/24 `ink` ("What's your name?").
- `ob.mechanic` — SF 20/27 `ink` (the one true sentence).
- `ob.body` — SF 17/24 `inkMuted`; 15/21 for the intention helper.
- `ob.fieldLabel` — SF 15 medium `inkMuted`, "· optional" in `inkFaint`; `ob.caption` SF 13 `inkMuted`.
- Fields — sans 22 centered (step 1 and 4) or sans 20 left-aligned under a label (step 3), over a 1 pt hairline (`ink` at 18%, 50% focused). No boxes, no grouped-form chrome.
- Buttons — one primary pill (56 pt, radius 28, `primary`, SF 17 semibold; disabled = `primary` at 28%, label at 55%) that becomes the pray button; quiet text actions (SF 17, `inkMuted`) in the top corners.

## Changes from the brief, and why
- **The person's avatar is not on screen until they type** (step 3 opens with the empty slot above the fields, and the avatar forms with the first letter). An empty 96 pt disc before anything is typed was the "hole" the critic flagged; forming on the first letter keeps the moment theirs.
- **"It can print with their name."** kept neutral as suggested; no gendered pronoun is inferred from an alias.
- **Quiet actions live top-right, not under the button.** With the keyboard up there is no room beneath the button; one consistent slot (Sign in / Not now / Skip) is also easier to find at 40+.
- **Status bar / home indicator take the ink of the current ground**, and the keyboard stand-in takes the system's light look only when Light Home is on and the step is Home (it never shows there), so onboarding keyboards are always dark on these grounds.
- **No "Begin" wording**: the last button is "Add" (or Skip); the hand-off itself is the beginning.
- Home shows a **Me** row (the self row carries the user's own intentions, per the spec) and the pewter streak badge with no number (zero prayers), as the spec defines.

## Stand-ins to replace
- The paper line: a photographed line of the real list paper, shot in the ritual's light, with the user's name set live in Roca over it (names are otherwise never legible).
- The pray button glyph: the custom praying-hands SF Symbol.
- The seal in the card: `WaxSeal` by the day's `sealVariant` (the mock uses the red stamp PNG).

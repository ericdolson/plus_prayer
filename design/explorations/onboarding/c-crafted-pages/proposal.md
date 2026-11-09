# C. Crafted pages — proposal (2026-11-09)

Mock: `index.html` (serve the repo root over http and open
`/design/explorations/onboarding/c-crafted-pages/index.html`). Deep links for
review: `?step=2&fill=1&kb=1`, `?step=3&large=1`, `?step=1&sheet=1`,
`?step=home`, `&reduce=1` on any of them.

## The idea

Four steps, one template, never broken. Every step has the same warm ground,
the same Roca line in the same place at the same calm weight, the same field,
the same capsule at the bottom, the same `‹ Back` / `Skip` corners and the same
quiet stitch at the top. The rhythm is ask / show / ask / show: you type your
name, and the next page shows it typeset on a paper line the way it will
print; you type a person, and the next page's headline is them ("And for
Mom?"). The one piece of motion the flow earns is that printed line: the name
you just typed travels from the field onto the paper. Nothing pushes;
steps cross-fade in place inside one container. At the end the blue
Continue capsule you have pressed three times becomes Home's pray button
while the warm room cools to Home's near-black, so the first time you see
Home it is already yours: your name, your person, their intention, and the
one button you will use.

## The flow, screen by screen (exact copy)

Template on every step: status bar · top bar (`‹ Back` left from step 2; the
stitch center; `Sign in` / `Skip` right) · leader (Roca 400, 34 pt) · sub-line
(SF 17, muted) · content · capsule CTA (56 pt) above the home indicator, or
above the keyboard when it is up.

**1 · Your name** (required)
- Leader: **Here, we pray for each other.**
- Sub: What’s your name?
- Field (Roca 24, how it prints): placeholder *Your name*
- Caption: Printed on the list the way you write it.
- Top right: **Sign in** · CTA: **Continue** (lit only once there is a name)
- No keyboard on arrival. Tapping the field raises it. Return = Continue.

**2 · Carried** (the mechanic, plus an optional intention for yourself)
- Leader: **Tomorrow, your name is on the list.**
- Sub: Pray with today’s list, and tomorrow you’re printed on it. The list is
  sealed each day and kept private.
- The printed line: a cream paper strip, stitched edge at left, `LIST 53`
  small-caps top right, a brown wax seal cropped into the right edge; your
  name in Roca 22 dark ink, and beneath it, live as you type, your
  intention in 13 pt. *Stand-in for the real asset:* a photograph of one line
  of the actual printed list, shot on the ceremony's table in the ritual's
  light, with the user's name composited into the line (names are otherwise
  never legible; this one is their own).
- Field label: An intention for yourself · optional
  Field (SF 17): *e.g. Patience with the new job*
  Caption: Prints beside your name. The people you pray for come next.
- Top right: **Skip** · CTA: **Continue**

**3 · Someone you pray for** (skippable)
- Leader: **Who do you pray for?**
- Sub: One person for now. You can add more anytime.
- Field label: Their name · field (Roca 24): *e.g. Julie Olson*
  Caption: Printed on the list, carried with you.
- Field label: What you call them · optional · field (Roca 24): *e.g. Mom*
  Caption: Only you see this.
- Return in the name field moves to the alias field (keyboard key reads
  `next`). No avatar: the names are the picture.
- Top right: **Skip** (→ Home; skipping the person skips their intention) ·
  CTA: **Continue**

**4 · Their intention** (skippable)
- Leader: **And for Mom?** (alias; else the name; else "them")
- Sub: What are you praying for? A request: healing, a new job, peace.
- Field (SF 17): *e.g. Healing after surgery*
- Caption: Prints beside their name on the list.
- Top right: **Skip** (→ Home) · CTA: **Begin** (→ Home)

**Home** arrives with: header avatar in your tone, the community card (List
52 · 4,345 people · 3,880 prayers · 213 praying now · your two avatars ·
"Pray to carry them onto List 53"), rows **Me** + intention and **Mom** +
intention, each with the carried mark; the floating pill and the pray button.
If the person was skipped, one row and the line "Add the people you pray for
with ＋."

Rules that hold on every step: **Continue needs input; Skip passes without
it.** A tap on the unlit Continue doesn't error; it focuses the first empty
field. Back is always there after step 1 and keeps what was typed. The leader
slot is two lines tall on every step, bottom-aligned, so a one-line question
("Who do you pray for?") and a two-line statement share one baseline position.

## What I cut from Eric's sketch, and why

- **The separate mechanic screen.** The mechanic is a statement, not a
  decision; a page with nothing to do is a page people flick past. Folding it
  into the page that *asks for your own intention* makes it the reason for the
  field ("your name is on the list; prints beside your name"), keeps "one
  decision per screen" (type or don't), and cuts a step. Five became four.
- **"Welcome, {name}."** Gone, as he asked. The name appears once, printed,
  which says more than a greeting.
- **Avatar materializing from the name field, floating praying hands, the
  drifting avatar.** All three animate feeling; the brand states facts. The
  avatar also appeared twice in the last build and read heavy. Here the only
  travelling object is the name becoming print, which is literally what the
  product does.
- **"Add an intention" / "I'll just hold them by name" as two CTAs.** Two
  primary choices on one screen is the thing the 40+ rule forbids. One
  capsule, one Skip, the same on every step.
- **The arrow-only CTA.** Labeled, always: Continue / Begin.
- **Account creation on screen 1.** No. Sign in is for people who already have
  a list; a new person types a name and is in. Sign-in prompts stay where the
  spec puts them (after the first prayer, around a 3-day streak, before the
  trial ends).
- **The Begin-only welcome.** Replaced by the name question itself; the first
  screen already scoops you in. "Your name, carried by the world." stays on
  the launch screen only.
- **Kept, deliberately:** the alias field. "Mom" on the Home row is what makes
  Home read as *yours* within the first second, and it teaches the
  printed/private split in one caption.

## Ground, type, fields, buttons (proposed tokens)

The onboarding is a warm, lit room; Home is the clear night it opens onto.
The warm ground is a deliberate half-step from the Welcome stand-in already in
the token set, so the Welcome photograph (if it returns) and these pages share
a family.

| Token (new unless noted) | Hex | Use |
|---|---|---|
| `onboardingGround` | `#1A1411` | The ground of all four steps (both appearances) |
| `onboardingGlow` | `#2C2017` | A soft radial warmth at the top center (120%×55%, fading into the ground by 70%) |
| `onboardingRaised` | `#2A211C` | Fields; the unlit CTA |
| `onboardingHairline` | `#3B2F28` | Field rim (1 pt inset); focused rim is `welcomeInkMuted` at 1.5 pt |
| `onboardingStitchAhead` | `#4A3C33` | Stitch nodes/segments not yet reached |
| `onboardingInkFaint` | `#7E7366` | Placeholders, "· optional", the unlit CTA label (decorative only; 3.9:1) |
| `welcomeInk` (existing) | `#F2EBDF` | Leader, field text, Back/Skip/Sign in, stitch done (15.1:1 on the ground) |
| `welcomeInkMuted` (existing) | `#BBB1A3` | Sub-lines, labels, captions (8.5:1) |
| `paper` | `#EFE4CF` | The printed line |
| `paperInk` / `paperMuted` | `#2A2019` / `#6B5B4B` | Name / intention and "LIST 53" on paper (13.4:1 / 4.7:1) |
| `primary` (existing, dark) | `#0580F9` | The lit CTA; the same blue becomes the pray button |

Blue stays the only accent: blue = do this, as everywhere in the app, and it
is the thing that physically carries over into Home. No gold here (gold means
held, and nothing is held yet).

**Type scale (onboarding).** Roca is used at 400, never bold; bold sans
titles are gone.

| Role | Face | Size / weight | Notes |
|---|---|---|---|
| `ob.leader` | Roca | 34 / 400, line 1.18, −0.5% tracking | Title 1 class; scales with Dynamic Type |
| `ob.sub` | SF | 17 / 400, muted | Body |
| `ob.fieldName` | Roca | 24 / 400 | Names, as they print |
| `ob.fieldText` | SF | 17 / 400 | Intentions |
| `ob.fieldLabel` | SF | 15 / 500, muted; "· optional" 400 faint | Subheadline |
| `ob.caption` | SF | 13 / 400, muted | Footnote |
| `ob.cta` | SF | 17 / 600 | Headline |
| `ob.corner` | SF | 17 / 400 | Back, Skip, Sign in |
| paper name / line | Roca 22 / 400 · SF 13 | fixed, not scaled (it is a picture of print) |

**Fields.** One style: 58 pt tall, radius 16, `onboardingRaised` fill, 1 pt
inset hairline, 18 pt text inset, left-aligned, blue caret, placeholder in
faint. Focus: the rim brightens to muted. Names set in Roca, intentions in
sans; the face tells you what kind of thing you are typing.

**Buttons.** One primary: a 56 pt capsule, full width inside 24 pt margins,
`glassProminent` tinted `primary` when the step has input; before that, flat
`onboardingRaised` with a faint label (unlit, not grayed-out iOS disabled). The
corners are plain text buttons with 44 pt targets. Nothing else is a button.

**Spacing.** 24 pt side margins (a touch wider than Home's 20, so the pages
feel like paper, not a list), 14 between leader and sub, 28 to the first
block, 22 between blocks, 8 label→field, 8 field→caption. CTA area: 12 top,
34 bottom (10 when the keyboard is up).

## The progress cue: the stitch

A 98 pt thread at the top center with four stitch nodes (4 pt). Done nodes
and the thread behind you are `welcomeInk`; the current node is a ring; the
rest are `onboardingStitchAhead`. On each Continue the thread draws forward
to the next node (500 ms ease-out) and the node fills. It reads as the list
being stitched, which it is; it is never labeled "1 of 4", and it carries no
tap targets. Skipping draws the thread straight to the end.

## Transitions

- **Between steps** (one container, no NavigationStack push): the outgoing
  page fades out and rises 18 pt (340 ms); the incoming fades in from 18 pt
  below (420 ms, `cubic-bezier(.2,.8,.2,1)`), starting 80 ms later so it
  reads as elements moving in place rather than a card arriving. Back
  reverses the direction. The top bar and CTA do not move; only their labels
  cross-fade (Continue ↔ Begin, Sign in ↔ Skip).
- **The printed line** (1 → 2 only): the name in the field travels to its
  place on the paper, 24 → 22 pt and cream → paper ink, 550 ms on the same
  curve, while the page beneath it changes. The paper's name slot stays
  empty until it lands.
- **Keyboard**: the system keyboard rises; the CTA rides above it; the
  content scrolls, never compresses or clips.
- **Reduce Motion**: every step change is a 300 ms cross-fade with no travel;
  the name does not fly (it is simply there on the paper); the stitch fills
  without drawing; the hand-off is a cross-fade. Nothing is lost but motion.

## Sign in

Top right on step 1 only: **Sign in**, plain text. It opens a native sheet
(medium detent): "Sign in" · "If you’ve used +Prayer before, your list comes
back." · **Continue with Apple** (black) · **Continue with Google** (white) ·
"New here? Just type your name." · Cancel. On success the onboarding is
skipped and their list loads (fresh install, existing account, per the spec).
No account is created here: a new person types a name and is in; the
keep-your-list-safe prompts come later as already decided. Steps 2–4 have no
sign-in; by then the person has started, and Skip occupies the corner.

## The hand-off to Home

On **Begin** (or Skip on 3/4): the page content and top bar fade (250 ms); the
ground cross-fades from `onboardingGround` to Home's `ground` (700 ms); the
blue capsule travels to the bottom-right and becomes the 62 pt pray button
(680 ms, `cubic-bezier(.4,0,.2,1)`), its label fading as the praying-hands
glyph fades in; at 380 ms Home's header, card and rows fade up in a 60 ms
stagger. At 760 ms the real pray button takes over and nothing moves again.
Home's first state is honest to what was typed: Me + intention, Mom +
intention, both in the community card's avatar row, and the card's line
"Pray to carry them onto List 53" is the next thing to do with the button
that just arrived under the thumb.

## Eric's five critiques, answered

1. **"Not high end; a variety of fonts and buttons; cold."** One face for
   the line (Roca 400), one for everything else (SF), one field, one button
   shape, two corner text buttons. A warm umber ground and cream ink, a paper
   line with a wax seal: the room is lit the way the ceremony is.
2. **"Not centered, cropped, chunky, yelling."** No bold sans anywhere. The
   leader is Roca at a calm weight, left-aligned with everything else on a
   fixed two-line slot, inside 24 pt margins that hold at ×1.3 text (tested;
   it wraps, never clips). Nothing shouts; the line reads like a sentence
   someone said.
3. **"Not cohesive."** A strict template: identical ground, title position,
   field, CTA position and corners on every step. The pages are one object
   with four faces.
4. **"Feels like next pages; no sense of sliding through; morph in place;
   a colored background that sets it apart; Home as the transition."** One
   container, cross-fades in place, a stitch that draws forward, the name
   that travels onto paper, and a hand-off where the room cools into Home
   and the button you pressed becomes the button you'll use.
5. **"The Begin-only page doesn't scoop me in."** Gone. The first thing you
   see is the question, with Sign in in the corner for people who already
   have a list.

## SwiftUI build notes (iOS 26)

- **Container**: a single `ZStack` driven by `@State step` with
  `.transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 18)),
  removal: .opacity.combined(with: .offset(y: -18))))` and
  `.animation(.easeOut(duration: 0.42))`; reverse the offsets when going
  back. Not a `NavigationStack`: push is the look we are leaving. Custom
  `‹ Back` / `Skip` text buttons in a fixed top row. **S/M.**
- **Leader slot**: `Text` in Roca 400 at `.title`-relative size
  (`Font.custom("Roca-Regular", size: 34, relativeTo: .title)`), inside a
  `frame(minHeight:)` of two lines (`ViewThatFits` or a hidden two-line
  sizer) aligned `.bottomLeading`. **S.**
- **Stitch**: a `Canvas`/`Shape` with `trim(from:to:)` animated per step;
  Reduce Motion → no trim animation (`accessibilityReduceMotion`). **S.**
- **Fields**: `TextField` with `.textFieldStyle(.plain)` inside a
  `RoundedRectangle(cornerRadius: 16)` fill + inset stroke (Tier A, custom:
  the native grouped `Form` field is what made the last build look like
  Settings). `.font` Roca for names, system for intentions;
  `.textInputAutocapitalization(.words)`/`.sentences`; `.submitLabel(.next /
  .continue)`. 40/80-char caps and the contact check from the add sheet. **S.**
- **CTA**: the existing `OnboardingButton` (`.glassProminent` tinted
  `primary`) when input exists, else a plain capsule in `onboardingRaised`;
  `.safeAreaBar(edge: .bottom)` so it rides above the keyboard as today.
  **S.**
- **Printed line**: a custom view (Tier A): paper fill, dashed stroke at the
  left, the Seals asset (brown) clipped at the trailing edge, Roca name,
  13 pt intention bound to the field. **S.** The name's travel:
  `matchedGeometryEffect(id: "selfName", in: ns)` on the field's text (step 1)
  and the paper name (step 2) with `.animation(.easeOut(duration: 0.55))`;
  both live in the one ZStack so the effect works. Reduce Motion: no
  `matchedGeometryEffect`, opacity only. **M.**
- **Sign-in sheet**: `.sheet` with `.presentationDetents([.medium])`,
  `SignInWithAppleButton` and a Google button; existing-account path skips
  onboarding. **S** (UI) on top of the auth work already planned.
- **Hand-off**: Home is already presenting onboarding as a full-screen cover;
  change it to a `ZStack` overlay so both can be on screen during the
  hand-off. The capsule → pray button is a second
  `matchedGeometryEffect(id: "pray")` between the CTA's background and the
  `PrayButton`'s disc, 0.68 s; the ground is `Color` interpolated with
  `.animation`; rows use a staggered `.transition(.opacity)` via
  `delay(0.06 * i)`. Reduce Motion: a cross-fade. The pray button is a
  Tier A component; the morph should land on its exact frame so the real
  button can take over without a frame change. **M.**
- Dynamic Type: all sizes `relativeTo:` the matching text style; the pages
  are `ScrollView`s with `scrollBounceBehavior(.basedOnSize)`. Verified in
  the mock at ×1.3 with the keyboard up.
- Persistence/resume: unchanged. Name saves on step 1's Continue
  (`setSelfName`); the self intention, the person and their intention are
  created at Begin/Skip through the existing add path. Resume rule
  unchanged (no self name → step 1; otherwise Home).
- Total effort: **M** (about a week for one person on top of the existing
  model), with the two matched-geometry moments as the only parts that
  need tuning on device.

## Risks

- **Warm ground → cool Home.** The hand-off is designed to make the shift
  deliberate, but if the warmth reads as "a different app" the fix is to pull
  `onboardingGround` toward `#15110E` (the Welcome stand-in) and lean on the
  glow for warmth. Needs a look on an OLED phone, not a simulator.
- **The paper line as a stand-in.** It is a graphic until there is a
  photograph; a bad photo (bright, craft-table, legible names) would break
  the "every object belongs to the ceremony" rule faster than the graphic
  does. Ship the graphic if the photo isn't right.
- **Blue on umber.** `#0580F9` is electric against a warm ground; it is
  intentionally the one cold thing, pointing at Home. If it jars on device,
  the light-theme `#0573E0` is a step quieter without changing its job.
- **Four steps is still four steps.** The template makes them feel like one,
  but the person who only wants their own name on the list sees two Skips.
  Mitigation is already in: Skip on step 3 goes straight to Home.
- **"And for Mom?" with no alias** falls back to the full name ("And for
  Julie Olson?"), which is fine, and to "them" if the jumper skips ahead,
  which never happens in the real flow.
- **Copy voice.** Every line was checked against the brand self-check; the
  one line that carries any feeling is the first ("Here, we pray for each
  other."). If it reads as performed on the phone, "Let's pray together."
  is the spare fallback.

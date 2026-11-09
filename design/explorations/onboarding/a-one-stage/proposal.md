# Onboarding exploration A: "One stage"

_2026-11-09. Mock: `index.html` (serve the repo root over http and open `/design/explorations/onboarding/a-one-stage/index.html`; `?step=N` jumps, `&rm=1` turns Reduce Motion on, `&focus=1` raises the keyboard)._

## The idea

Onboarding is one surface on one warm ground, and nothing on it is ever replaced by a new page. The user types their name; that name becomes the printed name in Roca, its initials lift out of it and become their avatar, the name is set onto a list and sealed, and the name and avatar then sit at the top of the stage as the first row of what will be Home. A second person, if they want one, forms as the second row beneath. When they're done, the warm ground cools to Home's ground and every object on the stage glides to the place it will live from now on: the avatar into the header, the rows into the list, the seal into the corner of the community card, the pray button rising from the bottom. There is no Begin screen, no greeting, no tour, no indicator; the continuity of the objects is the indicator. Four decisions, one tap each, about 40 seconds.

## The flow

The stage has fixed slots: a primary button always at the same height (y 700), a plain secondary below it (y 768), back (‹) at the top-left from the second step on, content between. One persistent avatar, one persistent name, one seal, one paper.

**1 · Your name** (arrival; the stage scoops: leader, then question and field, then the button, over ~1 s)
- Leader, Roca 400 32: **Your name, carried by the world.**
- Question, SF 22 medium: **What's your name?**
- Field, SF 24 centered, placeholder "Your name". No keyboard on arrival; tapping the field raises it and Continue rides up above it (the mock shows this).
- Primary: **Continue** (disabled until there is text). Top-right, quiet: **Sign in**.
- Leaves out: a Begin screen, the wordmark (the launch screen had it), any paragraph about the product, the photograph (nothing competes with the name).

**2 · The moment** (automatic, ~1.5 s, after Continue)
- The field's chrome, the question and the leader fade. The typed name becomes the same name in Roca 700 30, in place.
- The two initials lift out of the name (copies; the name keeps its letters) and travel ~90 pt up into a disc that forms behind them and fills with the user's tone. The disc's initials take over from the travelling letters as they arrive. Light haptic at arrival.
- Nothing else on screen: a disc and a name on a warm ground.
- Leaves out: "Welcome, Eric Olson." (the brief: it feels fake; here the name is shown, not announced).

**3 · Set onto the list, sealed**
- The avatar moves up to the top; a paper rises from below (the list stand-in: aged paper, a stitched top edge, six soft illegible lines). The name descends from under the avatar onto the paper's third line, shrinking to printed size (19) in paper ink. After it lands, the day's wax seal presses onto the paper's bottom edge (scale 1.25 → 1, 320 ms, ease-out).
- Lead line, SF 20 medium: **Pray with today's list. Tomorrow your name is on it.**
- Line, SF 17 muted: **The list is printed and sealed each day, and kept private.**
- Primary: **Continue**. ‹ returns to the field with the name in it.
- Leaves out: numbers, "the world", how carrying works for others, the privacy footer paragraph (one clause carries it), any mention of the trial.
- Real asset: a photographed blank strip of the actual list paper (texture, stitching, the wax) shot in the ritual's light, with the user's name typeset over it in Roca. Never a photo of a real list; names are never legible on camera and the user's name must be live text.

**4 · Who else you pray for**
- The avatar shrinks to 44 and the name comes back from the paper to sit beside it (Roca 700 19): a row, centered. The seal shrinks to 32 and sits above the row as a quiet emblem. The paper and its copy leave.
- Question: **Who else do you pray for?**
- Field "Their name", caption **Printed on the list**. Field "What you call them · optional", caption **Only you see this**.
- Primary: **Continue** (disabled until a name). Secondary: **Not now** (→ Home, with only your row).
- Leaves out: a big avatar (the brief: loud), the "carried with you" sentence (the row forming under yours says it), any second person after this one.

**5 · Their intention**
- The second row forms under yours: a 44 avatar with their initials (from the alias if given), the alias or name in Roca.
- Question: **What are you praying for, for Mom?** (alias, else name)
- Line, SF 15 muted: **An intention is a request: healing, a new job, peace. It can print with their name.**
- Field, placeholder "e.g. Healing after surgery".
- Primary: **Add**. Secondary: **Skip**. Both lead to the hand-off; Add first draws the intention under their row (thread + text) and holds ~0.7 s so they see it.
- ‹ dissolves the row back into the fields.

**6 · Hand-off to Home** (automatic, ~1.3 s)
- The ground cools from the stage's umber to Home's `#0E1012` (800 ms). ‹, the seal emblem and the buttons go.
- Your avatar glides to the header slot (32 pt, top-left). Your name glides into the Me row's slot and crossfades to **Me** with the carried mark; the Me row's own 44 pt avatar fades in beside it. The second row glides into its slot and gains its carried marks.
- The community card fades in above the rows (200 ms in); the seal travels from the emblem slot into the card's top-left corner, growing to 110 and taking the card's crop as it lands (clip-path to the card's radius).
- The floating bar and pray button rise from the bottom (500 ms in). Home is live. Card status: "Pray to carry them onto List 53" (or "Pray to be on List 53" after Not now).

## Ground, type, buttons (proposed tokens)

Stage colors, both appearances (the stage is dark and warm like the Welcome ground was; a light-mode Home receives the hand-off the same way, cooling and brightening to `#E9EEF9`):

| Token | Hex | Use |
|---|---|---|
| `onboarding.ground` | `#1C1612` | the stage, both themes (warmer and a step lighter than `welcomeGround #15110E`) |
| `onboarding.light` | `rgba(150,108,62,.20)` → 0 | one radial light from the top edge, the ritual's low warm light; fades out in the hand-off |
| `onboarding.ink` | `#F2EBDF` | = `welcomeInk` (15.9:1) |
| `onboarding.inkMuted` | `#BBB1A3` | = `welcomeInkMuted` (8.9:1) |
| `onboarding.inkFaint` | `#7E746A` | captions under fields (4.6:1) |
| `onboarding.field` / `.hairline` | ink at 7% / 14% | fields; focused: 9% / 30% |
| `onboarding.paper` | `#D8CAAF` (gradient `#DDD0B7` → `#CDBEA2`) | the list stand-in |
| `onboarding.paperInk` | `#2B2119` | the printed name and the lines |
| primary | `#0580F9` (dark primary) | blue = do this; the only saturated color on the stage besides the wax |

Type (all Dynamic Type; Roca roles via `relativeTo:`):

| Role | Face | Size / weight | Where |
|---|---|---|---|
| `onboarding.leader` | Roca | 32 / 400, 1.25 | "Your name, carried by the world." Regular, not bold: warm, not chunky |
| `onboarding.name` | Roca | 30 / 700 → 19 / 700 | the user's name; the same role as Home's `name` at the end |
| `onboarding.question` | SF | 22 / medium, −1% tracking | every question. Replaces `onboardingTitle` (34 bold) |
| `onboarding.lead` | SF | 20 / medium | the one mechanic line |
| body / caption | SF | 17 / 400 muted · 15 / 400 muted · 13 / 400 faint | lines under questions; captions under fields |
| field | SF | 24 (name) · 22 (others) / 400, centered | the person types in sans; Roca is what the app makes of it |
| label | SF | 17 / semibold | buttons |

Buttons: three kinds, each in one place. **Primary**: 56 pt capsule, action blue, white label; in SwiftUI `.glassProminent`; disabled at 38%. **Secondary**: a plain text button, 44 pt tall, `inkMuted`, in the slot under the primary ("Not now", "Skip"). **Chrome**: ‹ and "Sign in", 44 pt targets, `inkMuted`. No tinted capsule, no outlined button, no icon-only CTA.

## Motion

Durations from the tokens: `quick` 160, `settle` 320, `calm` 700; one new easing for travel, `calm` = cubic-bezier(.4, 0, .2, 1) (ease-in-out, no overshoot; the check's spring stays the app's only spring).

| Beat | What transforms | Time |
|---|---|---|
| Arrival | leader, then question + field, then button fade up 12 pt | 700 / 600 / 600 ms, staggered 80 / 420 / 700 |
| The moment | field chrome + question + leader fade (380 ms); sans name → Roca name crossfade in place (320); two initial glyphs travel to the disc (720, calm) while the disc scales .7 → 1 and fades in (320) from 40% of the travel; disc initials take over in the last 18% | ~1.4 s |
| Onto the list | avatar up (700, calm); paper rises 28 pt (700, calm); name travels to the paper line and shrinks 30 → 19 (700, calm, 200 ms late); seal presses 1.25 → 1 (320, ease-out) 1.0 s in; copy fades up 1.1 s in | ~1.5 s |
| To a row | avatar 96 → 44 and name 19 travel to the centered row (700, calm); paper fades down (320); seal 60 → 32 travels to the emblem slot (700); question + fields fade up 300 ms late | 1.0 s |
| Second row | row fades up 12 pt (320, 250 ms late); on Add the thread draws (320, dash offset) and the intention fades in (320, 200 ms late) | |
| Hand-off | ground color 800; avatar → header, name → Me slot, row 2 → its slot (700, calm); "Me" crossfade 450 ms in; card fades in from −10 pt 200 ms in; seal → card corner with the crop (700, 150 ms late); bar rises 24 pt 500 ms in; marks fade in 700 ms in | 1.3 s |

Reduce Motion: no travel anywhere. Geometry snaps and everything that moved instead crossfades in place at `settle`; the initials don't fly, the disc fades in above the name; the paper, seal and rows fade in where they'll be; the hand-off is the ground's color change plus fades (color change isn't motion). The mock's checkbox does exactly this.

## Sign-in

Top-right on the first frame only, as quiet text ("Sign in"), gone once the name is committed. It opens a native confirmation sheet: **Already have an account?** · "Sign in and your list comes back." · Sign in with Apple · Continue with Google · Cancel. A successful sign-in to an account with a name skips the rest and hands off to Home with their list; Sign in with Apple on a brand-new account prefills the field with the name Apple gives and the stage continues from step 1 with the name in place (the user still presses Continue, so the moment still happens). No sign-in anywhere else in onboarding; the "keep your list safe" prompts stay where they are (after the first prayer).

## How the hand-off works

Home is already underneath: the stage is a full-screen cover over Home with its own ground, and the hand-off is the cover's last state, not a dismissal. The avatar, the name, the second row and the seal are the cover's views until the final frame; Home's header avatar, Me row, second row and card seal are Home's views. They share geometry IDs, so when the cover's state becomes `.handedOff` each pair is one morph (the glass avatar to the header avatar's glass, the seal to the card's cropped stamp) and the cover's remaining content (buttons, ‹, copy) fades. The ground is one color property animated 800 ms. At the end the cover is removed with no transition (identical frames), and `isFinished` is true. The moment to land on is: the pray button rising last, so the first thing that moves after everything settles is the one thing to do.

## Eric's five critiques

1. **Not high-end: a variety of fonts and buttons, cold.** Two faces with fixed jobs (Roca for the name and the leader, SF for everything the app says), one primary button that never moves, one plain secondary under it, one warm ground with one low light. Nothing default-iOS is visible except the keyboard and the sign-in sheet.
2. **Questions chunky, cropped, off-center, yelling.** Every question is SF 22 medium, centered, with 32 pt side margins; no Large Title bold anywhere. The only big type is Roca, and it's regular weight at 32 or the name itself.
3. **Screens not cohesive.** There are no screens. The same avatar, name and seal are on stage from the moment the name is typed to Home; every step changes where they sit, never what they are.
4. **Feels like "next page"; wants morphing in place, a colored background, Home as the transition.** Nothing slides in from the side. The stage has its own ground; the only time the ground changes is the hand-off, and that is the transition to Home: things don't leave, they land.
5. **The Begin-only screen doesn't scoop.** The first frame asks the question. The leader and the field arrive within a second; there's nothing to opt into, only a name to give.

## SwiftUI build notes (iOS 26)

- **Structure**: one `OnboardingStage` view in the existing full-screen cover, driven by `OnboardingModel.phase` (`.name, .becoming, .onList, .who, .intention, .handedOff`), no `NavigationStack`. Slots are computed layout (a `ZStack` with `.position`/`.frame` per phase under `withAnimation(.timingCurve(.4,0,.2,1, duration: 0.7))`). Phase-local content is `.transition(.opacity.combined(with: .offset(y: 10)))`. **M.**
- **The moment**: `TextRenderer` (iOS 18+) on the Roca name to get the two initial glyphs' frames, then two `Text` glyph copies animated with `KeyframeAnimator` (position + scale over 720 ms) to the disc's initials, which are measured the same way; `MonogramAvatar` appears with `.scaleEffect`/`.opacity`. Fallback: glyph frames from a `GeometryReader` around per-character `Text`s. **M–L**; it's the custom effort of this design.
- **Shared geometry**: `matchedGeometryEffect` within the cover for avatar, name, row 2 and seal between phases; `glassEffectID` in one `GlassEffectContainer` for the avatar → header avatar morph in the hand-off (the header avatar is interactive glass tinted with the tone). The seal's crop is a `clipShape` with an animatable inset. Because Home's views are a different hierarchy, the hand-off pairs are the cover's copies morphing to the measured frames of Home's views (`PreferenceKey` or `onGeometryChange`), then the cover drops. **M.**
- **Ground**: a `Color` animated between `onboarding.ground` and `ground`; the low light is a `MeshGradient` (3×3, one warm point at the top) or a `RadialGradient`, opacity animated to 0. **S.**
- **Paper and seal**: a drawn `Shape` with a dashed stitch and blurred `Capsule`s for the lines, or the photographed paper asset; `WaxSeal` at 60 → 32 → 110 (the card's stamp is already `WaxSeal` cropped). **S.**
- **Fields**: native `TextField`s styled (centered, 24/22 pt, `.textContentType(.name)`), Continue in a bottom `safeAreaBar` so it rides the keyboard; no keyboard on arrival (no `.defaultFocus`). The name field becomes a `Text` in Roca in place (same frame, crossfade). **S.**
- **Reduce Motion**: `@Environment(\.accessibilityReduceMotion)` switches the phase animation to `.easeOut(duration: 0.32)` on opacity only; geometry changes are wrapped in `withAnimation(nil)`. **S.**
- **Dynamic Type**: slots are minimums; at AX sizes the content scrolls within the stage and the paper hides its lines (the name stays). **M.**
- **Haptics**: `.sensoryFeedback(.impact(weight: .light))` on the disc forming and the seal pressing. **S.**
- Native (Tier B): the sign-in confirmation sheet, text fields, keyboard, the glass buttons. Custom (Tier A): the stage layout, the moment, the paper and the hand-off.

## Risks

- **The moment depends on glyph geometry.** `TextRenderer` gives it cleanly; without it the fallback is approximate and the letters may not lift from exactly where they sit. Mitigation: ship the fallback with a 2 pt tolerance; no one sees the difference at 720 ms.
- **Hand-off across two hierarchies.** Matching the cover's copies to Home's live frames can be off by a point on the first layout pass (the card measures its own seal offset). Mitigation: measure Home once before the hand-off starts; Home is already built under the cover.
- **One stage at accessibility sizes.** Fixed slots stop fitting at AX3+; the stage must scroll and the choreography simplifies to fades. Design-wise acceptable (Reduce-Motion-like), but it needs its own pass.
- **Cost of a dark warm stage in light mode.** Users on a light Home get a dark onboarding, then a bright Home: the hand-off's ground change is larger. It still works (the mock's dark Home is the smaller case), but check it on device; if it's too much, the stage lightens to a warm paper tone in light mode and the paper object inverts to a darker card.
- **"Me" replacing the name in the hand-off.** It's honest to Home, but a first-time user watches their name turn into "Me". If it reads as loss, keep the full name on the row for the first session and let Home's self-row show "Me" from the next launch.
- **The seal emblem above the row (steps 4–5)** is the one element that's decoration. If it reads as a badge or a button, drop it there and let the seal appear with the card in the hand-off instead; the mock keeps it because the continuity into the card corner is the better ending.

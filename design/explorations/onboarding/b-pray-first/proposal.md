# Onboarding B — "Pray first"

_Exploration, 2026-11-09. Mock: `index.html` in this folder (serve the repo root over http; `?step=name&fill=1&rm=1` jumps for review)._

## The idea

+Prayer's one mechanic is reciprocity: pray with today's list and you are on tomorrow's. Every onboarding so far has *explained* that; this one has the person *do* it. The first screen is today's list — the seal, "List 52", 4,345 people, 239 praying now — and a single blue button, **Pray**. Five seconds later they say Amen, the seal is pressed and ringed in gold (the app's signature moment, on first launch), and only then does the app ask the one thing it needs: "Tomorrow, you're on List 53. What name should we print?" The name is asked at the moment it means something, not as a form to get past. Then one optional person, one optional reminder, and Home, where the community card already says "You'll be on List 53." No welcome screen, no Begin button, no tour: the first minute is the product.

## The flow, screen by screen (exact copy)

Everything happens on one page with a warm dark ground. Three elements persist across every step and carry the continuity Eric asked for: **the seal** (the list), **the blue button** (the one action), and **the ground**. Text groups rise in and out around them.

**1 · Today's list** (arrive; no Begin, no opt-in)
- Seal, 180 pt, upper center.
- `List 52` (Roca 700 22) · `4,345 people · 239 praying now` (15, muted, tabular)
- Lead (Roca 400 30): **Pray with today's list.** / **Tomorrow, you're on it.**
- Body (17, muted): One list, printed and sealed each day. Names are kept private, never published.
- **[ Pray ]** (primary pill)
- Already have an account? **Sign in** (quiet; opens the native sheet: Continue with Apple / Continue with Google / Not now)
- Leaves out: the wordmark (the launch screen just showed it), a photograph (the seal is the ceremony's object; see assets note), any "welcome", any explanation of tiers, intentions or aliases.

**2 · Praying** (in place, same page)
- Halo: 2 pt gold edge line + breathing glow fades in over 400 ms. `Cancel` top-left (text, ink).
- `List 52` stays; the counts line becomes `239 praying with you` (presence as the reward, as on Home).
- Lead: **Holding the 4,345** / **on List 52.**  Body: Stay as long as you like.
- The pill contracts into the 62 pt pray circle at the same spot; the small pie (0.4 ⌀) runs down over 5 s; then the circle expands back into a pill reading **Amen**. Same component as Home's button; the person has now used it once.
- Leaves out: a timer, journaling, the checklist of people (there are none yet), any text about tomorrow (that comes after Amen, where it is true).

**3 · Amen → seal** (the signature, ~1.5 s beat, automatic)
- Halo flare (500 ms) then fade (400 ms). The seal is **pressed**: scale 1 → 0.94 → 1 over 500 ms with the drop shadow tightening on the press; a gold **bloom** swells from its edge (360 ms) and settles into a crisp 3 pt gold **held ring** with a 3 pt gap.
- Lead becomes **You prayed with List 52.**; counts become `3,882 prayers` (yours just counted). Cancel and the hold line go.
- Then the seal shrinks to 64 pt and rises to the top; the name step arrives beneath it.

**4 · Your name**
- Seal 64 pt with its gold ring, top center (the mark that you prayed stays in view through the rest).
- Lead (Roca 400 30): **Tomorrow, you're on List 53.**
- Question (17, ink): What name should we print?
- Field: Roca 700 28, centered, hairline underline, placeholder `Your name`, 40-char cap. Caption (13, muted): Printed on the list. Never shown publicly.
- **[ Continue ]** above the keyboard (disabled until there is text). Return also continues.
- No back (there is nothing to go back to: the prayer is logged). No sign-in here: one ask.
- Leaves out: the 96 pt avatar (it arrives on the next step, as the answer), the privacy footer paragraph, the counter until the last 10 characters.

**5 · Carried · someone?**
- Seal (ringed) top. The field's text becomes the printed name: avatar 72 pt **materializes** (fade + scale from 0.72 with a blur settling, 480 ms) above **Eric Olson** (Roca 700 28). Line (17, muted): On List 53 tomorrow.
- Lead (Roca 400 26): **Is there someone you pray for?**  Body: Keep them here. They'll be on the list with you.
- **[ Add someone ]** (primary) · **Not now** (quiet → Home)
- Leaves out: "Welcome, Eric Olson." (Eric: feels fake), the hold/carry vocabulary lesson, the "who *else*" framing.

**6 · Someone you pray for** (only after Add someone)
- `‹ Back`. Lead: **Who do you pray for?**
- Avatar 56 pt fills with initials as they type (from the alias once there is one, as on Home).
- Field `Their name` (Roca 700 26), caption: Printed on the list.
- Field `What you call them · optional` (sans 20), caption: Only you see this.
- Live line once a name exists: **Mom will be on List 53 with you.** (alias, else name)
- **[ Continue ]** above the keyboard.
- Leaves out: an intention step. The person was added *after* the prayer, so there is no prayer to attach it to; the first time they open Mom's row on Home, "Add an intention" is right there with its own explanation. Also out: the carried switch (carried by default; the pre-trial pool covers it) and a second person ("never more than one other name in onboarding").

**7 · Reminder** (moved here from "after first Amen")
- `‹ Back`. Lead: **List 53 opens tomorrow morning.**  Question: When should we remind you to pray?
- Options (native list): Morning 8:00 AM (selected) · Midday 12:00 PM · Evening 8:00 PM. Caption: A quiet reminder once a day. Change it any time in You.
- **[ Turn on reminders ]** → the system notification prompt → Home. **Not now** → Home.
- Why here: the decided sequence already fires the reminder ask after the first Amen; the first Amen now happens in onboarding, and "tomorrow" has just been given a reason. Skipping is one tap. If this feels like one screen too many, cut it and keep the existing post-Amen placement for the *second* prayer; the mock makes the trade visible.

**8 · Home** (the hand-off)
- Ground crossfades warm → `#0E1012` (700 ms). The seal travels into the community card's top-left corner at 110 pt and fades as the card's own cropped seal appears; the pill contracts into the floating pray button bottom-right. Header (avatar `EO`, streak 1), the card with its gold held border and `You and Mom will be on List 53.` (or `You'll be on List 53.`), the Mom row with its carried mark, the History · 🔎 · ＋ pill.
- The empty-rows state when no one was added: The people you pray for will be here. Add someone with ＋.

## Ground, type and buttons (proposed tokens)

Onboarding owns a warm ground that is distinct from Home but hands off believably: the seal and the blue button are the same objects on both.

| Token | Value | Use |
|---|---|---|
| `ob.ground` | `#15110E` (= existing `welcomeGround`) | the page; plus a soft radial `#2B2017` glow at 50%/34% (candle-warm, 0 → transparent at 70%) |
| `ob.ink` / `ob.inkMuted` | `#F2EBDF` / `#BBB1A3` (= `welcomeInk` / `welcomeInkMuted`; 15.8:1 / 8.9:1) | leads, body |
| `ob.inkFaint` | `#7A7066` (decorative; placeholders) | field placeholders |
| `ob.hairline` | `#33291F` | field underlines, option separators |
| `ob.field` | `#1F1915` | the options list |
| `primary` / `onPrimary` | `#0580F9` / `#FFFFFF` (unchanged) | Pray, Amen, Continue — the one action |
| `heldGold` | `#C8AE6E` (unchanged) | halo, the seal's held ring |
| wax | `wax-red` in the mock (Tuesday's garnet reads well on the warm ground); real: the day's `sealVariant` | the list |

Type (SF Pro unless Roca; all scale with Dynamic Type):

| Role | Spec | Where |
|---|---|---|
| `ob.lead` | Roca **400** 30/38 (`sm`: 26/33) | the one big line per step. Regular, not bold — Roca at this weight is warm; bold sans at 34 pt was the "yelling". Proposed as an extension of the "two ceremonial lines" allowance, scoped to onboarding. |
| `ob.name` | Roca 700 28/34 | the typed name (how it prints), the confirmed name |
| `ob.listName` | Roca 700 22/28 | `List 52` |
| `ob.question` | SF 17/24 regular, `ob.ink` | "What name should we print?" |
| `ob.body` | SF 17/24 regular, `ob.inkMuted` | facts |
| `ob.counts` | SF 15/20 tabular, muted | `4,345 people · 239 praying now` |
| `ob.caption` | SF 13/18, muted | field captions |
| `ob.button` | SF 17 semibold | pill labels |

Buttons — exactly two styles plus chrome:
- **Primary pill**: 56 pt tall, full width inside 20 pt gutters, radius 28, `primary` fill, white 17 pt semibold label; a soft blue shadow at 25%. Disabled = 40% opacity. It is the *same element* throughout and morphs into the 62 pt pray circle (and finally Home's floating button), so there is one button in the whole flow.
- **Quiet**: text only, 17 pt regular, `ob.inkMuted` (the actionable word in `ob.ink`: "Sign in"), 44 pt tall.
- **Chrome**: `‹ Back` / `Cancel` top-left, 44 pt targets, in `ob.ink`.
- No glass pills, no tinted secondary, no bordered buttons.

Fields: no boxes. A centered line of type (Roca for anything that prints, sans for the alias) over a 1 pt hairline that brightens on focus; caption beneath. Natively this is a plain `TextField` with a `Divider`, not a `Form` row — Tier B metrics aren't needed because there is no grouped form.

## Motion spec

- **Step changes** (one page, in place): outgoing lines fade and rise −8 pt over 240 ms ease-in; incoming lines fade in from +12 pt over 320 ms ease-out, staggered 60 ms, starting 140 ms after the outgoing begins. Persistent elements move on their own curves: seal 600 ms ease-in-out (position and size together), button 420 ms ease-in-out (position, width, radius).
- **Pray tap**: halo fades in 400 ms; the pill contracts to the circle (420 ms); the pie starts after the morph lands and runs 5 s linear, its edge moving clockwise from 12 o'clock; the circle dims to `primary` at 30% during the hold (`number.prayButtonDim`); on completion it expands back into the Amen pill (label crossfades 160 ms).
- **Amen** (the signature): halo flare 500 ms (fast rise 150 ms, settle 350 ms) then fade 400 ms; seal press 500 ms ease-out (scale 1 → 0.94 at 30% → 1, shadow 6 → 2 → 6 pt); gold bloom 360 ms (opacity 0 → 0.9 at 35% → 0, scale 1 → 1.3, blur 6 pt); the held ring fades in at 180 ms and stays. A single medium haptic at the press (impact, `.medium`), none elsewhere. Beat of 1.5 s, then the name step.
- **Name → carried**: field text stays put and the underline fades; avatar materializes 480 ms (opacity, scale 0.72 → 1, blur 4 → 0).
- **Hand-off**: ground crossfade 700 ms; seal travels to the card corner 600 ms then fades 320 ms as the card's seal appears; button morphs to the floating circle 420 ms; header/card/rows/bar fade in with 70 ms stagger from 380 ms.
- **Reduce Motion**: every transition is a 160 ms opacity fade with no travel, scale or blur; the pie steps once a second; no press, no bloom, no flare — the ring simply appears; the halo is static at 0.7 opacity; the keyboard and sheet fade instead of sliding. **Beats are kept**: the 5 s hold and the 1.5 s pause after Amen are time, not motion.

## Sign-in placement

Screen 1 only, as the quiet line under Pray: "Already have an account? Sign in" → the native sheet with Continue with Apple / Continue with Google. An existing account skips onboarding and loads its list (as decided). A *new* user who signs in with Apple here can have the name step prefilled from Apple's one-time name; the step still shows (they confirm how it prints). No sign-in on the name step: it is one ask. The "keep your list safe" prompt stays where it is decided (soft, after the first prayer — here that means a few minutes after onboarding, on Home, not inside it).

## Backend implications

Checked against `backend/functions/src` and `backend/dataconnect`:

- **`logPrayer` needs no self name today.** `LogPrayer` is `@auth(level: USER_ANON)` and takes `subjectIds` (empty here) and `communityListId`; `onPrayerLogged` counts it, bumps the list, starts the streak and the trial. Nothing to change for the prayer itself. The onboarding prayer is a real community prayer: `communityList` = List 52, `subjectIds` = [].
- **The self subject is created at step 4** by the existing idempotent `setSelfName(name)`; `onAuthUserCreated` already made the User row at the silent anonymous sign-in. Order reversal (prayer before self subject) is fine for `logPrayer`; **assembly must not require the self subject to predate the prayer** — it joins the user's qualifying prayer to their self subject at assembly time (~6 am MT), so a name entered minutes after Amen is carried. Confirm `draft N+1 entries` in `list-lifecycle.md` reads the self subject at assembly, not at prayer time (it should; worth one test).
- **Resume stays state-based**: prayer logged but no self name → the app resumes at step 4 with the same copy (`Tomorrow, you're on List 53.` if the prayed-with list is still current; after the flip, just `What name should we print?` — the lead is dropped, nothing invented). This is the one real cost of praying first: a person who prays and quits before naming is not on List 53. No deadline copy; no urgency.
- **Trial** starts at this first prayer (`processPrayer` sets `trialStartedAt`, pool = `basePremiumPool`), so the person added at step 6 is inside the trial pool. The pre-trial pool rule (2026-11-09) becomes nearly moot for this flow but should stay for people who add before praying later.
- **Carrying**: Mom at step 6 goes through the normal `addSubject` with carried = true (default, pool 10). The day-10 trial notice gets scheduled from this prayer — fine.
- **Reminder**: the step writes the same reminder preference the post-Amen flow writes today, then requests notification permission. No new fields.
- Nothing changes in `setSelfName`, `logPrayer`, `addSubject` or the schema. One behavioural change: the app allows a community prayer with no self subject (today the main screen is gated on the name; prayer mode here is a dedicated onboarding view, not Home, so the gate can stay on Home).

## How it answers Eric's five critiques

1. **"Nothing feels high end; a variety of fonts and buttons."** One serif role (Roca regular for leads, bold for names), one sans for facts, one blue button that is literally the same element from Pray to Amen to Continue to Home's floating button, one quiet text style. No glass, no grouped forms, no mixed alignment: everything centered on one axis.
2. **"Chunky, like yelling; the question wasn't centered and was cropped."** No bold sans titles anywhere. Questions are 17 pt sans in ink; the big lines are Roca regular at 30. Everything is centered with 32 pt side margins and `text-wrap: balance`; nothing is pushed under the keyboard (Continue rides above it at a fixed slot, fields sit in the upper half).
3. **"Not cohesive screen to screen."** It is one screen. The seal, the ground and the button never leave; text changes around them. The gold ring the seal earns at Amen stays in view through every later step: the thread of the flow is "you prayed; now…".
4. **"Feels like a next page; no sense of sliding through; Home should feel like *the* transition; a colored background."** No push navigation, no page dots: elements morph in place, and the only real scene change is the hand-off, where the ground cools, the seal flies into the card and the button becomes the pray button. The warm ground sets onboarding apart and makes Home's cool ground read as "arriving".
5. **"The Begin-only first page doesn't scoop me in."** There is no Begin. The first screen is today's list with real numbers and one verb. The person is inside the product before any decision; the first decision they make is the product's whole point.

## SwiftUI build notes (iOS 26)

- **One view, one state enum** (`OnboardingStage`), not a `NavigationStack`: content switches with `.transition(.opacity.combined(with: .offset(y: 12)))` under `withAnimation(.easeOut(duration: 0.32))`; the seal and button are siblings in a `ZStack` driven by stage-dependent frame/offset values with `matchedGeometryEffect` for the hand-off into Home's card and floating button (`@Namespace` shared via the environment; Home's `CommunityCard` seal and `PrayButton` take the same id). Effort **M**.
- **Button morph**: one `Button` whose label is a `ZStack` of the text and the `CountdownButton` pie; animate `frame(width:)` and `clipShape(Capsule())` — a capsule at 62×62 is the circle, so no shape switch is needed. Use the existing `CountdownButton` for the pie and dim. Effort **S**.
- **Halo**: reuse `Components/Halo.swift` (line + glow, breath, flare; already has Reduce Motion). Effort **S**.
- **Seal press + bloom + ring**: `WaxSeal` plus a `Circle().stroke(heldGold, lineWidth: 3)` and a blurred copy for the bloom; keyframes via `KeyframeAnimator` (iOS 17+) for the press (scale/shadow) and the bloom (opacity/scale); `sensoryFeedback(.impact(weight: .medium), trigger:)`. Reduce Motion: `accessibilityReduceMotion` swaps to opacity only. This is the moment to spend on. Effort **M**.
- **Fields**: plain `TextField` with `.font(.custom("Roca-Bold", size: 28, relativeTo: .title))`, `.multilineTextAlignment(.center)`, a `Divider` beneath, `.focused`, `.submitLabel(.continue)`; Continue in `.safeAreaBar(edge: .bottom)` (already used in `NameScreen`). Effort **S**.
- **Avatar materialize**: `MonogramAvatar` with `.transition(.scale(0.72).combined(with: .opacity))` plus a `blur` keyframe. Effort **S**.
- **Reminder options**: a native `List` section with checkmarks (Tier B), or three `Button` rows in a `raised` container as mocked; then `UNUserNotificationCenter.requestAuthorization`. Effort **S**.
- **Ground**: `Rectangle().fill(.radialGradient…)` over `welcomeGround`, crossfaded to `ground` with the stage; `.environment(\.colorScheme, .dark)` for the whole flow (the warm ground is dark in both appearances, as the Welcome already is). Effort **S**.
- **Data**: a `PrayerSession` started in onboarding with `communityList` set and no subjects; `logPrayer` at Amen (optimistic, queued); `setSelfName` at Continue (online; the existing offline/failed lines under the field); `addSubject` at step 6. Resume: `User.displayName == nil` and a prayer for the current list exists → stage `.name`. Effort **M**.
- Dynamic Type: leads use `relativeTo: .largeTitle`; at accessibility sizes the content column scrolls and the seal drops to 120 pt; the button stays in the safe-area bar. Test at AX5 as the existing previews do.
- Total: roughly a week for one engineer, most of it in the Amen moment and the hand-off.

## Risks

- **Asking a stranger to pray before they know what this is.** The first screen gives them three facts (one list, printed and sealed daily, private) and real numbers; some will still want to know more before praying. Mitigation in the mock: Cancel is always there and returns to the list; nothing is lost. If testing shows hesitation, add one quiet link on screen 1 ("How the list works") that expands three lines in place — never a tour.
- **A prayer with no name.** Pray, quit, never name → not on List 53, and a prayer exists for a user with no self subject. Resume handles the UI; confirm assembly and the "first printed" rule tolerate it. The orphaned prayer still counts toward the list's numbers, which is honest: they did pray.
- **The trial starts before the person has added anyone.** By design (first prayer), but it means the 14 days begin in the first minute. Acceptable; if not, start the clock at the first prayer *after* onboarding and keep the pre-trial pool rule for the onboarding add.
- **Seven steps on paper.** Two are automatic (the Amen beat, the hand-off), two are skippable with one tap, and the whole thing is ~60–90 s. If it must shrink, drop the reminder step first (keep the decided post-Amen placement), then merge "someone" into Home's ＋.
- **Roca regular at 30 pt for leads** extends the typography rule (Roca for names, list numbers and two ceremonial lines). The alternative — sans titles — is what Eric called yelling. If the rule must hold, the leads can be SF 28 regular (not bold) and only the list name and the typed name stay in Roca; the mock would lose some warmth but keep its structure.
- **The wax color on the warm ground.** Garnet and brown read well; Monday's navy and Sunday's gold need checking on `#15110E` (the gold wax beside the gold held ring in particular). The dark-theme rim light from `WaxSeal` applies here as on any dark surface.
- **Assets.** The seal is the stand-in for the planned photograph/loop of the sealed list; this flow doesn't need the photograph (the seal is the object the person acts on). If one is shot, it belongs behind screen 1 only, dark, with the seal still the focal object.
